"""home/dot_bin/executable_autosplit against a fake swaymsg."""

from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_autosplit"


def window(width, height, focused=True, fullscreen=0):
    return {
        "type": "con",
        "pid": 1,
        "focused": focused,
        "fullscreen_mode": fullscreen,
        "rect": {"width": width, "height": height},
        "nodes": [],
        "floating_nodes": [],
    }


def tree(layout, *nodes, floating=()):
    """A root holding one workspace with these nodes in a layout container."""
    container = {
        "type": "con",
        "layout": layout,
        "focused": False,
        "nodes": list(nodes),
        "floating_nodes": [],
    }
    workspace = {
        "type": "workspace",
        "layout": "splith",
        "focused": False,
        "nodes": [container],
        "floating_nodes": list(floating),
    }
    return {"type": "root", "nodes": [{"type": "output", "nodes": [workspace]}]}


class AutosplitTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.trees = self.tmp / "trees"
        self.trees.mkdir()
        # subscribe replays one focus event per tree, plus events autosplit
        # ignores; get_tree hands out the trees in order; other calls are logged
        self.stub(
            "swaymsg",
            f"""case "$2" in
  subscribe)
    for f in "{self.trees}"/*.json; do
      echo '{{"change": "title"}}'
      echo '{{"change": "focus"}}'
    done ;;
  get_tree)
    n=$(cat "{self.tmp}/count" 2>/dev/null || echo 0)
    n=$((n + 1)); echo "$n" > "{self.tmp}/count"
    cat "{self.trees}/$n.json" ;;
  *) echo "$*" >> "{self.tmp}/commands" ;;
esac""",
        )
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "cat", "jq", "seq"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def commands(self, *trees, args=()):
        for n, layout_tree in enumerate(trees, 1):
            (self.trees / f"{n}.json").write_text(json.dumps(layout_tree))
        result = subprocess.run(
            [str(SCRIPT), *args],
            env={"PATH": self.path, "XDG_RUNTIME_DIR": str(self.tmp)},
            capture_output=True,
            text=True,
            timeout=20,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        log = self.tmp / "commands"
        return log.read_text().splitlines() if log.exists() else []

    def test_tall_windows_split_vertically_and_wide_ones_horizontally(self):
        self.assertEqual(
            self.commands(
                tree("splith", window(400, 800), window(400, 800, False)),
                tree("splitv", window(800, 400), window(800, 400, False)),
            ),
            ["-q split v", "-q split h"],
        )

    def test_a_split_already_going_the_right_way_is_left_alone(self):
        self.assertEqual(
            self.commands(
                tree("splitv", window(400, 800)),
                tree("splith", window(800, 400)),
            ),
            [],
        )

    def test_floating_fullscreen_tabbed_and_stacked_windows_are_left_alone(self):
        floating = tree("splith", window(400, 800, False), floating=[window(400, 800)])
        self.assertEqual(
            self.commands(
                floating,
                tree("splith", window(400, 800, fullscreen=1)),
                tree("tabbed", window(400, 800)),
                tree("stacked", window(400, 800)),
            ),
            [],
        )

    def test_nothing_is_split_while_sway_startup_runs(self):
        # this test's own process stands in for a running sway-startup
        (self.tmp / "sway-startup.pid").write_text(f"{os.getpid()}\n")
        self.assertEqual(self.commands(tree("splith", window(400, 800))), [])

    def test_a_pid_file_left_by_a_finished_sway_startup_is_ignored(self):
        finished = subprocess.Popen(["true"])
        finished.wait()
        (self.tmp / "sway-startup.pid").write_text(f"{finished.pid}\n")
        self.assertEqual(
            self.commands(tree("splith", window(400, 800))), ["-q split v"]
        )

    def test_flip_toggles_the_focused_windows_container(self):
        self.assertEqual(
            self.commands(
                tree("splith", window(400, 800), window(400, 800, False)),
                args=["flip"],
            ),
            ["-q layout toggle split"],
        )

    def test_flip_on_a_window_alone_in_its_container_flips_the_one_above(self):
        self.assertEqual(
            self.commands(tree("splitv", window(400, 800)), args=["flip"]),
            ["-q focus parent; layout toggle split; focus child"],
        )


if __name__ == "__main__":
    unittest.main()
