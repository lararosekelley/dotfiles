"""home/dot_bin/executable_night-light against fake gammastep and swaymsg."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_night-light"

OUTPUTS = [
    {"name": "DP-3", "adaptive_sync_status": "enabled"},
    {"name": "HDMI-A-1", "adaptive_sync_status": "disabled"},
]


class NightLightTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.running = self.tmp / "gammastep-running"
        config = self.tmp / "config/gammastep"
        config.mkdir(parents=True)
        (config / "config.ini").write_text("[general]\ntemp-night=4000\n")
        (self.tmp / "outputs.json").write_text(json.dumps(OUTPUTS))
        # gammastep "runs" while a file exists: setsid starts it, pkill ends it
        self.stub("setsid", f'echo "$*" >> "{self.log}"; touch "{self.running}"')
        self.stub("pgrep", f'[ -e "{self.running}" ]')
        self.stub(
            "pkill",
            f'echo "pkill $*" >> "{self.log}"\n'
            f'[ "${{*: -1}}" != gammastep ] || rm -f "{self.running}"',
        )
        self.stub("waybar-refresh", f'echo "waybar-refresh $*" >> "{self.log}"')
        self.stub(
            "swaymsg",
            f"""if [ "$2" = get_outputs ]; then cat "{self.tmp}/outputs.json"
else echo "swaymsg $*" >> "{self.log}"; fi""",
        )

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def run_script(self, *args):
        result = subprocess.run(
            [str(SCRIPT), *args],
            env={
                "PATH": f"{self.bin}:/usr/bin:/bin",
                "XDG_CONFIG_HOME": str(self.tmp / "config"),
                "XDG_STATE_HOME": str(self.tmp / "state"),
                "NIGHT_LIGHT_RESTORE_DELAY": "0",
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def calls(self):
        return self.log.read_text().splitlines()

    def state(self):
        return (self.tmp / "state/night-light/state").read_text().strip()

    def test_on_warms_now_with_adaptive_sync_off_on_displays_that_had_it(self):
        self.run_script("toggle")
        self.assertIn("swaymsg -q output DP-3 adaptive_sync off", self.calls())
        self.assertNotIn("HDMI-A-1", self.log.read_text())
        self.assertIn("-f gammastep -O 4000", self.calls())
        self.assertEqual(self.state(), "on")
        self.assertIn('"class": "on"', self.run_script("status"))
        self.assertIn("4000K", self.run_script("status"))

    def test_off_restores_adaptive_sync_on_the_same_displays(self):
        self.run_script("toggle")
        self.log.write_text("")
        self.run_script("toggle")
        self.assertIn("pkill -x gammastep", self.calls())
        self.assertIn("swaymsg -q output DP-3 adaptive_sync on", self.calls())
        self.assertNotIn("HDMI-A-1", self.log.read_text())
        self.assertEqual(self.state(), "off")
        self.assertIn('"class": "off"', self.run_script("status"))

    def test_after_a_crash_on_still_remembers_which_displays_had_vrr(self):
        self.run_script("on")
        # gammastep dies without night-light off; DP-3 now reports VRR off
        self.running.unlink()
        outputs = [dict(o, adaptive_sync_status="disabled") for o in OUTPUTS]
        (self.tmp / "outputs.json").write_text(json.dumps(outputs))
        self.log.write_text("")
        self.run_script("on")
        self.assertIn("swaymsg -q output DP-3 adaptive_sync on", self.calls())

    def test_restore_brings_it_back_only_if_it_was_on(self):
        self.run_script("restore")
        self.assertFalse(self.running.exists())
        self.run_script("on")
        self.running.unlink()
        self.log.write_text("")
        self.run_script("restore")
        self.assertTrue(self.running.exists())
        self.assertIn("-f gammastep -O 4000", self.calls())

    def test_without_a_config_it_warms_to_3600k(self):
        (self.tmp / "config/gammastep/config.ini").unlink()
        self.run_script("on")
        self.assertIn("-f gammastep -O 3600", self.calls())


if __name__ == "__main__":
    unittest.main()
