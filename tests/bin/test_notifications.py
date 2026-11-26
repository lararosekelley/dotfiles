"""home/dot_bin/executable_notifications against a fake makoctl and rofi."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_notifications"
SHOWING = [{"app_name": "Signal", "summary": "Hi", "body": "just now"}]
HISTORY = [
    {"app_name": "Zen", "summary": "Download finished", "body": "report.pdf"},
    {"app_name": "Slack", "summary": "New message", "body": "two\nlines"},
]


class NotificationsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        (self.tmp / "list.json").write_text(json.dumps(SHOWING))
        (self.tmp / "history.json").write_text(json.dumps(HISTORY))
        (self.tmp / "mode").write_text("default\n")
        self.stub(
            "makoctl",
            f"""case "$1" in
  list) cat "{self.tmp}/list.json" ;;
  history) cat "{self.tmp}/history.json" ;;
  mode) cat "{self.tmp}/mode" ;;
esac""",
        )
        self.stub("rofi", f'cat > "{self.tmp}/shown"; echo 2')
        self.stub("wl-copy", f'cat > "{self.tmp}/copied"')
        self.stub("notify-send", f'echo "$*" > "{self.tmp}/notified"')
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "jq", "grep", "cat"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def run_script(self, *args):
        return subprocess.run(
            [str(SCRIPT), *args],
            env={"PATH": self.path},
            capture_output=True,
            text=True,
        )

    def test_the_menu_lists_showing_then_history_and_copies_the_choice(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.tmp / "shown").read_text().splitlines(),
            [
                "Signal: Hi - just now",
                "Zen: Download finished - report.pdf",
                "Slack: New message - two lines",
            ],
        )
        self.assertEqual((self.tmp / "copied").read_text(), "New message\ntwo\nlines\n")

    def test_status_shows_the_count(self):
        status = json.loads(self.run_script("status").stdout)
        self.assertIn("3 notifications", status["tooltip"])

    def test_the_dnd_pill_follows_the_mode(self):
        dnd = REPO / "home/dot_bin/executable_dnd"
        run = lambda: json.loads(  # noqa: E731
            subprocess.run(
                [str(dnd), "status"],
                env={"PATH": self.path},
                capture_output=True,
                text=True,
            ).stdout
        )
        self.assertEqual(run()["class"], "off")
        (self.tmp / "mode").write_text("default\ndo-not-disturb\n")
        self.assertEqual(run()["class"], "on")

    def test_unreadable_output_counts_as_no_notifications(self):
        (self.tmp / "list.json").write_text("Notification 1: Hi\n  App name: x\n")
        (self.tmp / "history.json").write_text("")
        status = json.loads(self.run_script("status").stdout)
        self.assertIn("0 notifications", status["tooltip"])
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.tmp / "shown").exists())
        self.assertIn("No notifications", (self.tmp / "notified").read_text())

    def test_nothing_to_list_says_so_instead_of_opening_the_menu(self):
        (self.tmp / "list.json").write_text("[]")
        (self.tmp / "history.json").write_text("[]")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.tmp / "shown").exists())
        self.assertIn("No notifications", (self.tmp / "notified").read_text())


if __name__ == "__main__":
    unittest.main()
