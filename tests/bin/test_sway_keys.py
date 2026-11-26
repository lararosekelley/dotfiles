"""home/dot_bin/executable_sway-keys against small sway configs."""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_sway-keys"

CONFIG = """\
# variables
set $mod Mod4
set $term kitty

include ~/machine.conf
include /etc/sway/config.d/*

# open terminal
bindsym $mod+Return exec $term

# headline that a blank line separates from the binding

bindsym $mod+q kill

# save and quit (A & B)
bindsym --locked $mod+Shift+bracketright exec echo a && echo b

mode "resize" {
    # leave resize mode
    bindsym Escape mode "default"
}
"""


class SwayKeysTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        (self.tmp / "config").write_text(CONFIG)
        (self.tmp / "machine.conf").write_text("set $mod Mod1\n")
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        rofi = self.bin / "rofi"
        rofi.write_text(
            f'#!/usr/bin/env bash\necho "$*" > "{self.tmp}/args"\n'
            f'cat > "{self.tmp}/rows"\n'
        )
        rofi.chmod(0o755)

    def run_script(self, *args):
        env = {
            **os.environ,
            "HOME": str(self.tmp),
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "SWAY_KEYS_CONFIG": str(self.tmp / "config"),
        }
        return subprocess.run(
            [str(SCRIPT), *args], env=env, capture_output=True, text=True
        )

    def lines(self):
        result = self.run_script("--print")
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.splitlines()

    def test_an_included_file_can_change_mod_before_the_bindings(self):
        self.assertTrue(self.lines()[0].startswith("Alt+Enter "))

    def test_each_binding_shows_its_comment_and_command(self):
        first = self.lines()[0]
        self.assertIn("open terminal", first)
        self.assertIn("(kitty)", first)

    def test_a_comment_separated_by_a_blank_line_is_not_used(self):
        kill = self.lines()[1]
        self.assertIn("kill  (kill)", kill)
        self.assertNotIn("headline", kill)

    def test_flags_are_skipped_and_key_names_are_readable(self):
        self.assertTrue(self.lines()[2].startswith("Alt+Shift+] "))

    def test_bindings_in_a_mode_are_labelled_with_it(self):
        self.assertTrue(self.lines()[3].startswith("resize: Esc "))
        self.assertEqual(len(self.lines()), 4)

    def test_the_menu_escapes_markup(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = (self.tmp / "rows").read_text()
        self.assertIn("(A &amp; B)", rows)
        self.assertIn("echo a &amp;&amp; echo b", rows)
        self.assertNotIn(" && ", rows)
        self.assertIn("-markup-rows", (self.tmp / "args").read_text())

    def test_a_missing_config_is_reported(self):
        (self.tmp / "config").unlink()
        result = self.run_script("--print")
        self.assertEqual(result.returncode, 1)
        self.assertIn("can't read", result.stderr)


if __name__ == "__main__":
    unittest.main()
