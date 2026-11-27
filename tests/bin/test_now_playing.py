"""home/dot_bin/executable_now-playing against a fake playerctl."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_now-playing"


class NowPlayingTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.players = self.tmp / "players"
        self.players.mkdir()

    def player(self, name, status, artist="", title=""):
        folder = self.players / name
        folder.mkdir()
        (folder / "status").write_text(status + "\n")
        (folder / "artist").write_text(artist + "\n")
        (folder / "title").write_text(title + "\n")

    def run_script(self, *args):
        # playerctl -l lists the player folders; -p NAME reads or logs
        playerctl = self.bin / "playerctl"
        playerctl.write_text(f"""#!/usr/bin/env bash
if [ "$1" = -l ]; then ls "{self.players}"; exit; fi
p="{self.players}/$2"; shift 2
case "$1" in
  status) cat "$p/status" ;;
  metadata) cat "$p/$2" ;;
  *) echo "$(basename "$p") $*" >> "{self.log}" ;;
esac
""")
        playerctl.chmod(0o755)
        result = subprocess.run(
            [str(SCRIPT), *args],
            env={"PATH": f"{self.bin}:/usr/bin:/bin"},
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_shows_the_playing_player_s_artist_and_title(self):
        self.player("chromium.instance1", "Paused", "Other", "Video")
        self.player("cliamp", "Playing", "Mitski", "Nobody")
        status = json.loads(self.run_script())
        self.assertEqual(status["text"], "\U000f0388 Mitski - Nobody")
        self.assertEqual(status["tooltip"], "cliamp: Mitski - Nobody")

    def test_shows_nothing_while_nothing_plays(self):
        self.player("cliamp", "Paused", "Mitski", "Nobody")
        self.assertEqual(json.loads(self.run_script())["text"], "")

    def test_long_titles_are_shortened_and_markup_is_escaped(self):
        self.player("cliamp", "Playing", "A & B", "x" * 60)
        text = json.loads(self.run_script())["text"]
        self.assertTrue(text.startswith("\U000f0388 A &amp; B - xxx"), text)
        self.assertTrue(text.endswith("…"), text)

    def test_a_player_without_track_names_shows_its_own_name(self):
        self.player("firefox.instance9", "Playing")
        self.assertEqual(json.loads(self.run_script())["text"], "\U000f0388 firefox")

    def test_click_and_scroll_act_on_the_playing_player(self):
        self.player("chromium", "Paused")
        self.player("cliamp", "Playing", "a", "b")
        self.run_script("toggle")
        self.run_script("next")
        self.assertEqual(
            self.log.read_text().splitlines(), ["cliamp play-pause", "cliamp next"]
        )

    def focus(self, tree, owner_pid="", parents=""):
        """Run focus with a sway tree, the player's D-Bus process, and a
        "pid ppid" table for ps; return what swaymsg and notify-send got."""
        (self.tmp / "tree.json").write_text(json.dumps(tree))
        (self.tmp / "parents").write_text(parents)
        log = self.log
        self.stub_bin(
            "swaymsg",
            f'if [ "$1" = -t ]; then cat "{self.tmp}/tree.json"; '
            f'else echo "swaymsg $*" >> "{log}"; fi',
        )
        self.stub_bin("busctl", f'[ -n "{owner_pid}" ] && echo "u {owner_pid}"')
        self.stub_bin(
            "ps",
            f'awk -v p="${{@: -1}}" \'$1 == p {{ print $2 }}\' "{self.tmp}/parents"',
        )
        self.stub_bin("notify-send", f'echo "notify-send $*" >> "{log}"')
        self.run_script("focus")
        return log.read_text().splitlines() if log.exists() else []

    def stub_bin(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def test_focus_finds_the_terminal_a_player_runs_in(self):
        self.player("cliamp", "Playing", "Mitski", "Nobody")
        tree = {
            "nodes": [
                {"id": 5, "pid": 100, "app_id": "kitty", "name": "~"},
                {"id": 9, "pid": 300, "app_id": "kitty", "name": "cliamp"},
            ]
        }
        # cliamp (pid 500) runs in a shell (400) in the second kitty (300)
        calls = self.focus(tree, owner_pid="500", parents="500 400\n400 300\n")
        self.assertEqual(calls, ["swaymsg -q [con_id=9] focus"])

    def test_focus_falls_back_to_the_app_name_then_the_title(self):
        self.player("firefox.instance_1_2", "Playing", "A", "Video Title")
        tree = {
            "nodes": [
                {"id": 3, "pid": 10, "app_id": "kitty", "name": "~"},
                {
                    "id": 7,
                    "pid": 20,
                    "app_id": "app.zen_browser.zen",
                    "name": "Video Title - YouTube",
                },
            ]
        }
        self.assertEqual(self.focus(tree), ["swaymsg -q [con_id=7] focus"])

    def test_focus_says_so_when_no_window_is_found(self):
        self.player("cliamp", "Playing", "a", "b")
        tree = {"nodes": [{"id": 3, "pid": 10, "app_id": "kitty", "name": "~"}]}
        calls = self.focus(tree)
        self.assertEqual(len(calls), 1)
        self.assertIn("Can't find the window playing", calls[0])


if __name__ == "__main__":
    unittest.main()
