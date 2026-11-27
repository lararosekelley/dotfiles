"""home/dot_bin/executable_brightness against fake brightnessctl and ddcutil."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_brightness"


class BrightnessTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.stub("ddcutil", f'echo "ddcutil $*" >> "{self.log}"')

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def panel(self, present):
        listing = (
            "echo \"Device 'amdgpu_bl1' of class 'backlight':\"" if present else ""
        )
        self.stub(
            "brightnessctl",
            f'if [ "$1" = --list ]; then {listing or "exit 1"}; '
            f'else echo "brightnessctl $*" >> "{self.log}"; fi',
        )

    def run_script(self, *args):
        return subprocess.run(
            [str(SCRIPT), *args],
            env={"PATH": f"{self.bin}:/usr/bin:/bin", "XDG_RUNTIME_DIR": str(self.tmp)},
            capture_output=True,
            text=True,
        )

    def test_a_laptop_panel_uses_brightnessctl(self):
        self.panel(True)
        self.run_script("up")
        self.run_script("down", "10")
        self.assertEqual(
            self.log.read_text().splitlines(),
            ["brightnessctl --quiet set 5%+", "brightnessctl --quiet set 10%-"],
        )

    def test_without_a_panel_the_monitor_is_set_over_ddc(self):
        self.panel(False)
        self.run_script("up")
        self.run_script("down")
        self.assertEqual(
            self.log.read_text().splitlines(),
            ["ddcutil --noverify setvcp 10 + 5", "ddcutil --noverify setvcp 10 - 5"],
        )

    def test_a_press_while_ddcutil_is_busy_is_dropped(self):
        self.panel(False)
        self.stub("ddcutil", f'echo "ddcutil $*" >> "{self.log}"; sleep 1')
        first = subprocess.Popen(
            [str(SCRIPT), "up"],
            env={"PATH": f"{self.bin}:/usr/bin:/bin", "XDG_RUNTIME_DIR": str(self.tmp)},
        )
        for _ in range(50):
            if self.log.read_text():
                break
            subprocess.run(["sleep", "0.02"])
        second = self.run_script("up")
        first.wait()
        self.assertEqual(second.returncode, 0)
        self.assertEqual(len(self.log.read_text().splitlines()), 1)

    def test_a_bad_direction_is_an_error(self):
        result = self.run_script("sideways")
        self.assertEqual(result.returncode, 2)
        self.assertIn("usage", result.stderr)


if __name__ == "__main__":
    unittest.main()
