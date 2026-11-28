"""home/dot_bin/executable_brightness against fake brightnessctl and ddcutil."""

from pathlib import Path
import json
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
        self.stub(
            "ddcutil",
            f'echo "ddcutil $*" >> "{self.log}"\n'
            '[ "$1" = getvcp ] && echo "VCP 10 C 15 100"',
        )
        self.stub("waybar-refresh", f'echo "waybar-refresh $*" >> "{self.log}"')

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
            f'case "$*" in --list*) {listing or "exit 1"} ;; '
            '*info) echo "amdgpu_bl1,backlight,512,50%,1023" ;; '
            f'*) echo "brightnessctl $*" >> "{self.log}" ;; esac',
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
            [
                "brightnessctl --quiet set 5%+",
                "waybar-refresh 11",
                "brightnessctl --quiet set 10%-",
                "waybar-refresh 11",
            ],
        )

    def test_without_a_panel_the_monitor_is_set_over_ddc(self):
        self.panel(False)
        self.run_script("up")
        self.run_script("down")
        self.assertEqual(
            self.log.read_text().splitlines(),
            [
                "ddcutil --noverify setvcp 10 + 5",
                "ddcutil getvcp 10 --brief",
                "waybar-refresh 11",
                "ddcutil --noverify setvcp 10 - 5",
                "ddcutil getvcp 10 --brief",
                "waybar-refresh 11",
            ],
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
        sets = [x for x in self.log.read_text().splitlines() if "setvcp" in x]
        self.assertEqual(len(sets), 1)

    def test_a_change_shows_the_new_level_on_screen(self):
        self.panel(False)
        self.stub("osd", f'echo "osd $*" >> "{self.log}"')
        self.run_script("up")
        self.assertIn("osd value 15", self.log.read_text().splitlines())

    def test_status_shows_the_panels_level(self):
        self.panel(True)
        self.assertIn("50%", json.loads(self.run_script("status").stdout)["text"])

    def test_status_shows_the_monitors_level_over_ddc(self):
        self.panel(False)
        self.assertIn("15%", json.loads(self.run_script("status").stdout)["text"])

    def test_status_hides_with_neither(self):
        self.panel(False)
        self.stub("ddcutil", "exit 1")
        self.assertEqual(json.loads(self.run_script("status").stdout)["text"], "")

    def test_a_bad_direction_is_an_error(self):
        result = self.run_script("sideways")
        self.assertEqual(result.returncode, 2)
        self.assertIn("usage", result.stderr)


if __name__ == "__main__":
    unittest.main()
