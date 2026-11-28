"""home/dot_bin/executable_waybar-refresh against a stand-in for waybar."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_waybar-refresh"

# Like waybar at login, it handles SIGRTMIN+8 only after a moment; until then
# the signal ends it. The shebang names bash directly: through env, the process
# would be named bash rather than after the script, and pgrep wouldn't find it.
FAKEBAR = """\
#!{bash}
sleep 1
trap 'echo refreshed >> "{log}"' RTMIN+8
while true; do sleep 0.1; done
"""


class WaybarRefreshTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.log = self.tmp / "log"
        # unique per run, so no other process (or waybar) matches
        self.name = f"fakebar{os.getpid() % 100000}"
        self.bar = self.tmp / self.name
        self.bar.write_text(FAKEBAR.format(bash=shutil.which("bash"), log=self.log))
        self.bar.chmod(0o755)

    def refresh(self, signal="8"):
        return subprocess.run(
            [str(SCRIPT), signal],
            env={**os.environ, "WAYBAR_REFRESH_NAME": self.name},
            capture_output=True,
            text=True,
            timeout=30,
        )

    def test_a_bar_that_just_started_is_signalled_once_it_handles_it(self):
        bar = subprocess.Popen([str(self.bar)])
        self.addCleanup(bar.wait)
        self.addCleanup(bar.kill)
        time.sleep(0.2)
        result = self.refresh()
        self.assertEqual(result.returncode, 0, result.stderr)
        for _ in range(30):
            if self.log.exists():
                break
            time.sleep(0.1)
        self.assertIsNone(bar.poll(), "the signal ended the bar")
        self.assertEqual(self.log.read_text(), "refreshed\n")

    def test_without_a_bar_it_does_nothing(self):
        result = self.refresh()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
