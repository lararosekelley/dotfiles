"""home/dot_bin/executable_windows against a fake swaymsg and rofi."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_windows"


def window(id, app_id, name, focused=False, **extra):
    return {
        "id": id,
        "type": "con",
        "pid": 100 + id,
        "app_id": app_id,
        "name": name,
        "focused": focused,
        "nodes": [],
        "floating_nodes": [],
        **extra,
    }


def workspace(name, nodes=(), floating=()):
    return {
        "type": "workspace",
        "name": name,
        "nodes": list(nodes),
        "floating_nodes": list(floating),
    }


TREE = {
    "nodes": [
        {
            "type": "output",
            "name": "__i3",
            "nodes": [
                workspace(
                    "__i3_scratch",
                    floating=[dict(window(7, "kitty", "notes"), type="floating_con")],
                ),
            ],
        },
        {
            "type": "output",
            "name": "DP-3",
            "nodes": [
                workspace(
                    "1",
                    nodes=[
                        window(3, "startup-callie", "callie"),
                        {
                            "type": "con",
                            "layout": "splitv",
                            "nodes": [
                                window(4, "startup-fastfetch", ""),
                                window(
                                    5,
                                    None,
                                    "Steam",
                                    focused=True,
                                    window_properties={"class": "Steam"},
                                ),
                            ],
                            "floating_nodes": [],
                        },
                    ],
                ),
                workspace("2", nodes=[window(6, "startup-nvim", "nvim\tfile")]),
            ],
        },
    ]
}


class WindowsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        (self.tmp / "tree.json").write_text(json.dumps(TREE))
        self.stub(
            "swaymsg",
            f"""if [ "$1" = -t ]; then cat "{self.tmp}/tree.json"
else echo "$*" >> "{self.tmp}/swaymsg"; fi""",
        )
        self.answer("")
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "cat", "jq"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def answer(self, row):
        """Make rofi record its input and arguments, then pick row (an index),
        or cancel when row is empty."""
        pick = f"echo {row}" if row != "" else "exit 1"
        self.stub(
            "rofi",
            f"""cat > "{self.tmp}/shown"
echo "$*" > "{self.tmp}/args"
{pick}""",
        )

    def run_script(self):
        return subprocess.run(
            [str(SCRIPT)], env={"PATH": self.path}, capture_output=True, text=True
        )

    def rows(self):
        shown = (self.tmp / "shown").read_bytes().decode().splitlines()
        return [row.split("\0")[0].split() for row in shown]

    def test_lists_every_window_by_workspace_and_selects_the_focused_one(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.rows(),
            [
                ["1", "startup-callie", "callie"],
                ["1", "startup-fastfetch"],
                ["1", "Steam", "Steam"],
                ["2", "startup-nvim", "nvim", "file"],
                ["scratchpad", "kitty", "notes"],
            ],
        )
        self.assertIn("\0icon\x1fsteam", (self.tmp / "shown").read_text())
        self.assertIn("-selected-row 2", (self.tmp / "args").read_text())
        self.assertFalse((self.tmp / "swaymsg").exists())

    def test_choosing_a_window_focuses_it(self):
        self.answer("3")
        self.run_script()
        self.assertEqual((self.tmp / "swaymsg").read_text(), "-q [con_id=6] focus\n")

    def test_no_matching_window_focuses_nothing(self):
        self.answer("-1")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("-no-custom", (self.tmp / "args").read_text())
        self.assertFalse((self.tmp / "swaymsg").exists())

    def test_a_scratchpad_window_is_brought_out_by_focusing_it(self):
        self.answer("4")
        self.run_script()
        self.assertEqual((self.tmp / "swaymsg").read_text(), "-q [con_id=7] focus\n")


if __name__ == "__main__":
    unittest.main()
