"""home/dot_bin/executable_wait-for-tray against a fake busctl."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_wait-for-tray"


class WaitForTrayTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.calls = self.tmp / "calls"
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "seq", "sleep", "wc", "echo"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"

    def busctl(self, ready_on):
        """A busctl that finds the tray from its ready_on-th call (0: never)."""
        script = self.bin / "busctl"
        script.write_text(
            "#!/usr/bin/env bash\n"
            f'echo "$*" >> "{self.calls}"\n'
            f'n=$(wc -l < "{self.calls}")\n'
            f'[ {ready_on} -gt 0 ] && [ "$n" -ge {ready_on} ]\n'
        )
        script.chmod(0o755)

    def run_script(self, *args):
        return subprocess.run(
            [str(SCRIPT), *args],
            env={"PATH": self.path, "WAIT_FOR_TRAY_TENTHS": "5"},
            capture_output=True,
            text=True,
        )

    def checks(self):
        return self.calls.read_text().splitlines()

    def test_it_runs_the_command_once_the_tray_appears(self):
        self.busctl(ready_on=3)
        result = self.run_script("echo", "started")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "started\n")
        self.assertEqual(
            self.checks(), ["--user status org.kde.StatusNotifierWatcher"] * 3
        )

    def test_it_runs_the_command_anyway_when_no_tray_appears(self):
        self.busctl(ready_on=0)
        result = self.run_script("echo", "started")
        self.assertEqual(result.stdout, "started\n")
        self.assertEqual(len(self.checks()), 5)

    def test_without_a_command_it_shows_usage(self):
        self.busctl(ready_on=1)
        result = self.run_script()
        self.assertEqual(result.returncode, 2)
        self.assertIn("usage:", result.stderr)


if __name__ == "__main__":
    unittest.main()
