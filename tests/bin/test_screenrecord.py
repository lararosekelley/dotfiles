"""home/dot_bin/executable_screenrecord against a fake wf-recorder."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_screenrecord"

# Keeps its arguments, runs until interrupted, and then writes the -f file, as
# wf-recorder finishes a video on SIGINT.
WF_RECORDER = """\
#!/usr/bin/env bash
echo "$*" > "{tmp}/args"
while [ $# -gt 0 ]; do [ "$1" = -f ] && file=$2; shift; done
trap 'echo video > "$file"; exit 0' INT
while :; do sleep 0.05; done
"""


class ScreenrecordTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(self.cleanup)
        self.home = self.tmp / "home"
        self.home.mkdir()
        self.run_dir = self.tmp / "run"
        self.run_dir.mkdir()
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        (self.bin / "wf-recorder").write_text(WF_RECORDER.format(tmp=self.tmp))
        (self.bin / "wf-recorder").chmod(0o755)
        self.stub("slurp", 'echo "10,20 300x200"')
        self.stub("swaymsg", 'echo \'[{"name": "DP-1", "focused": true}]\'')
        self.stub("pactl", "echo speakers")
        self.stub("notify-send")
        self.stub("pkill")
        self.stub("xdg-user-dir", "exit 1")

    def cleanup(self):
        # stop a recorder a failed test left running
        pidfile = self.run_dir / "screenrecord.pid"
        if pidfile.exists():
            subprocess.run(["kill", pidfile.read_text().strip()], check=False)
        shutil.rmtree(self.tmp)

    def stub(self, name, body=""):
        script = self.bin / name
        script.write_text(
            f'#!/usr/bin/env bash\necho "{name} $*" >> "{self.log}"\n{body}\n'
        )
        script.chmod(0o755)

    def run_script(self, *args):
        env = {
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "HOME": str(self.home),
            "XDG_RUNTIME_DIR": str(self.run_dir),
        }
        return subprocess.run(
            [str(SCRIPT), *args], env=env, capture_output=True, text=True
        )

    def status(self):
        return json.loads(self.run_script("status").stdout)

    def videos(self):
        return list((self.home / "Videos/Recordings").glob("*.mp4"))

    def test_a_region_records_until_run_again_then_saves(self):
        self.assertEqual(self.status()["text"], "")
        result = self.run_script("region")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.status()["class"], "recording")
        args = (self.tmp / "args").read_text()
        self.assertIn("-g 10,20 300x200", args)
        self.assertNotIn("--audio", args)

        self.run_script("region")
        self.assertEqual(self.status()["text"], "")
        (video,) = self.videos()
        self.assertEqual(video.read_text(), "video\n")
        self.assertIn(f"Recording saved {video}", self.log.read_text())
        self.assertIn("pkill -RTMIN+10 -x waybar", self.log.read_text())

    def test_audio_records_the_default_outputs_monitor(self):
        self.run_script("output", "--audio")
        args = (self.tmp / "args").read_text()
        self.assertIn("-o DP-1", args)
        self.assertIn("--audio=speakers.monitor", args)
        self.run_script("stop")
        self.assertEqual(len(self.videos()), 1)

    def test_cancelling_the_region_records_nothing(self):
        self.stub("slurp", "exit 1")
        result = self.run_script("region")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.tmp / "args").exists())
        self.assertEqual(self.status()["text"], "")

    def test_a_recorder_that_fails_at_once_is_reported(self):
        (self.bin / "wf-recorder").write_text("#!/usr/bin/env bash\nexit 1\n")
        result = self.run_script("output")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Couldn't start recording", self.log.read_text())
        self.assertEqual(self.status()["text"], "")


if __name__ == "__main__":
    unittest.main()
