"""home/dot_bin's power-menu and display-menu against a fake rofi.

The fake rofi answers each prompt with the first entry containing the text
queued for it, so the tests pick entries by label while the menus show icons.
"""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
POWER = REPO / "home/dot_bin/executable_power-menu"
DISPLAY = REPO / "home/dot_bin/executable_display-menu"


class MenusTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.answers = self.tmp / "answers"
        # rofi: record what's shown, then answer with the line matching the next
        # queued answer, or cancel (exit 1) when none is left
        self.stub(
            "rofi",
            f"""lines=$(cat)
printf '%s\\n---\\n' "$lines" >> "{self.tmp}/shown"
answer=$(head -n 1 "{self.answers}")
sed -i 1d "{self.answers}"
[ -n "$answer" ] || exit 1
grep -F -m 1 -- "$answer" <<< "$lines" """,
        )
        for name in ("swaylock", "swaymsg", "systemctl", "night-light", "wl-mirror"):
            self.stub(name, f'echo "{name} $*" >> "{self.log}"')
        self.stub("kanshictl", f'echo "kanshictl $*" >> "{self.log}"')
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "cat", "grep", "sed", "head", "printf"):
            path = shutil.which(command)
            if path:
                (system / command).symlink_to(path)
        self.path = f"{self.bin}:{system}"

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def run_menu(self, script, *answers, env=None, succeeds=True):
        self.answers.write_text("".join(a + "\n" for a in answers))
        self.log.write_text("")
        result = subprocess.run(
            [str(script)],
            env={"PATH": self.path, "HOME": str(self.tmp), **(env or {})},
            capture_output=True,
            text=True,
        )
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stderr)
        return self.log.read_text().splitlines()

    def shown(self):
        return (self.tmp / "shown").read_text()

    def test_each_power_entry_starts_with_an_icon(self):
        self.run_menu(POWER)
        entries = self.shown().split("---")[0].strip().splitlines()
        self.assertEqual(len(entries), 5)
        for entry in entries:
            self.assertRegex(entry, r"^[^\x00-\x7f]  \w")

    def test_power_entries_run_their_command(self):
        cases = {
            ("lock",): ["swaylock "],
            ("suspend",): ["systemctl suspend"],
            ("reboot", "yes"): ["systemctl reboot"],
            ("shut down", "yes"): ["systemctl poweroff"],
            ("log out", "yes"): ["swaymsg exit"],
        }
        for answers, calls in cases.items():
            with self.subTest(answers=answers):
                self.assertEqual(self.run_menu(POWER, *answers), calls)

    def test_declining_or_cancelling_runs_nothing(self):
        # a declined confirmation leaves the script's status at 1; only what
        # runs matters here
        self.assertEqual(self.run_menu(POWER, "reboot", "no", succeeds=False), [])
        self.assertEqual(self.run_menu(POWER, "shut down", succeeds=False), [])
        self.assertEqual(self.run_menu(POWER), [])

    def test_display_entries_run_their_command(self):
        kanshi = self.tmp / ".config/kanshi"
        kanshi.mkdir(parents=True)
        (kanshi / "config").write_text("profile docked {\n}\nprofile laptop {\n}\n")
        self.stub("pgrep", "exit 1")
        self.assertEqual(
            self.run_menu(DISPLAY, "layout: laptop"), ["kanshictl switch laptop"]
        )
        self.assertEqual(
            self.run_menu(DISPLAY, "night light: on"), ["night-light toggle"]
        )
        self.assertIn("  layout: docked", self.shown())


if __name__ == "__main__":
    unittest.main()
