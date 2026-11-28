"""home/dot_bin/executable_osd against a fake wob and wpctl."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_osd"


class OsdTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.shown = self.tmp / "shown"
        # wob: keep each line it reads
        self.stub("wob", f'while read -r line; do echo "$line" >> "{self.shown}"; done')
        self.volume("Volume: 0.45")
        self.env = {
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "XDG_RUNTIME_DIR": str(self.tmp),
            "SWAYSOCK": "/run/user/1000/sway-ipc.1000.42.sock",
        }

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def volume(self, line):
        self.stub("wpctl", f'echo "{line}"')

    def osd(self, *args):
        return subprocess.run(
            [str(SCRIPT), *args],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=5,
        )

    def daemon(self):
        process = subprocess.Popen(
            [str(SCRIPT), "daemon"], env=self.env, start_new_session=True
        )
        self.addCleanup(lambda: subprocess.run(["pkill", "-g", str(process.pid)]))
        fifo = self.tmp / "wob.sway-ipc.1000.42.sock.fifo"
        for _ in range(50):
            if fifo.exists():
                break
            time.sleep(0.05)
        self.assertTrue(fifo.is_fifo())

    def lines(self, count):
        for _ in range(50):
            if (
                self.shown.exists()
                and len(self.shown.read_text().splitlines()) >= count
            ):
                break
            time.sleep(0.05)
        return self.shown.read_text().splitlines()

    def test_levels_reach_wob(self):
        self.daemon()
        self.osd("value", "40")
        self.osd("volume")
        self.volume("Volume: 0.30 [MUTED]")
        self.osd("volume")
        self.assertEqual(self.lines(3), ["40", "45", "30 muted"])

    def test_without_the_daemon_a_key_returns_at_once(self):
        start = time.monotonic()
        result = self.osd("value", "40")
        self.assertEqual(result.returncode, 0)
        self.assertLess(time.monotonic() - start, 2)

    def test_a_bad_argument_is_an_error(self):
        self.assertEqual(self.osd("sideways").returncode, 2)


if __name__ == "__main__":
    unittest.main()
