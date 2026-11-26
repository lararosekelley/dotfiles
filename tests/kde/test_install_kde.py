import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/install-kde.py"

spec = importlib.util.spec_from_file_location("install_kde", SCRIPT)
kde = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kde)

DUMP = """var plasma = getApiVersion(1);

var layout = {
    "desktops": [{"config": {"/Wallpaper/org.kde.image/General": {"Image": "/x.png"}}}],
    "panels": [
        {
            "applets": [
                {
                    "config": {
                        "/": {"popupHeight": "1", "popupWidth": "2", "keep": "yes"},
                        "/ConfigDialog": {"DialogHeight": "3"},
                        "/WeatherStation": {"placeInfo": "Somewhere"},
                        "/Appearance": {"title": "CPU"}
                    },
                    "plugin": "org.kde.plasma.weather"
                }
            ],
            "config": {"/": {"formfactor": "2", "lastScreen": "0"}},
            "location": "top"
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);
"""


class Layout(unittest.TestCase):
    def test_capture_drops_machine_state(self):
        layout = kde.sanitize(kde.parse_dump(DUMP))
        self.assertEqual(layout["desktops"], [])
        panel = layout["panels"][0]
        self.assertEqual(panel["config"], {"/": {"formfactor": "2"}})
        self.assertEqual(panel["location"], "top")
        self.assertEqual(
            panel["applets"][0]["config"],
            {"/": {"keep": "yes"}, "/Appearance": {"title": "CPU"}},
        )

    def test_apply_script_replaces_panels(self):
        script = kde.layout_script({"panels": []})
        self.assertLess(script.index("panel.remove()"), script.index(kde.LAYOUT_SUFFIX))
        self.assertEqual(kde.parse_dump(script), {"panels": []})

    def test_capture_dry_run_diffs_without_saving(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "layout.json"
            target.write_text("{}\n")
            with patch("sys.stdout", new_callable=io.StringIO) as out:
                kde.capture(DUMP, target, dry_run=True)
            self.assertIn('+  "panels": [', out.getvalue())
            self.assertEqual(target.read_text(), "{}\n")
            with patch("sys.stdout", new_callable=io.StringIO) as out:
                kde.capture(DUMP, target, dry_run=False)
                kde.capture(DUMP, target, dry_run=True)
            self.assertIn("is up to date", out.getvalue())

    def test_failed_shell_call_exits_with_stderr(self):
        error = subprocess.CalledProcessError(
            1, ["qdbus"], stderr="Service not found\n"
        )
        with (
            patch.object(kde, "qdbus", return_value="qdbus"),
            patch.object(kde.subprocess, "run", side_effect=error),
        ):
            with self.assertRaises(SystemExit) as raised:
                kde.shell_call("evaluateScript", "x")
        self.assertEqual(
            str(raised.exception), "evaluateScript failed: Service not found"
        )
        error = subprocess.CalledProcessError(
            2, ["qdbus"], output="Error: UnknownMethod\n", stderr=""
        )
        with (
            patch.object(kde, "qdbus", return_value="qdbus"),
            patch.object(kde.subprocess, "run", side_effect=error),
        ):
            with self.assertRaises(SystemExit) as raised:
                kde.shell_call("evaluateScript", "x")
        self.assertEqual(
            str(raised.exception), "evaluateScript failed: Error: UnknownMethod"
        )

    def test_layout_apply_checks_shell_before_changing_anything(self):
        with (
            patch.object(kde, "shell_call", side_effect=SystemExit("down")),
            patch.object(kde, "run") as run,
        ):
            with self.assertRaises(SystemExit):
                kde.apply({"packages": []}, Path("/h"), dry_run=False, layout=True)
        run.assert_not_called()

    def test_layout_apply_restarts_the_shell_after_replacing_panels(self):
        calls = []
        with (
            patch.object(kde, "shell_call", side_effect=lambda *a: calls.append(a)),
            patch.object(kde, "run"),
            patch.object(kde, "missing_packages", return_value=[]),
            patch.object(kde, "theme_commands", return_value=[]),
            patch.object(kde, "config_commands", return_value=[]),
            patch.object(kde.subprocess, "run") as subprocess_run,
        ):
            subprocess_run.return_value.returncode = 0
            settings = {"packages": [], "widgets": [], "config": {}}
            kde.apply(settings, Path("/h"), dry_run=False, layout=True)
        self.assertEqual(calls[-1][0], "evaluateScript")
        subprocess_run.assert_called_with(
            ["systemctl", "--user", "restart", "plasma-plasmashell"]
        )

    def test_committed_layout_is_sanitized(self):
        layout = json.loads((REPO / "scripts/kde/layout.json").read_text())
        self.assertEqual(kde.sanitize(layout), layout)


class Settings(unittest.TestCase):
    def test_config_writes_single_keys_under_home(self):
        commands = kde.config_commands(
            {"kwinrc": {"NightColor": {"Active": "true"}}}, Path("/h/.config")
        )
        self.assertEqual(
            commands,
            [
                [
                    "kwriteconfig6",
                    "--file",
                    "/h/.config/kwinrc",
                    "--group",
                    "NightColor",
                    "--key",
                    "Active",
                    "true",
                ]
            ],
        )

    def test_widget_at_pinned_version_is_skipped(self):
        widget = {"id": "w", "repo": "r", "ref": "v1.2", "path": "package"}
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            meta = home / ".local/share/plasma/plasmoids/w/metadata.json"
            meta.parent.mkdir(parents=True)
            meta.write_text(json.dumps({"KPlugin": {"Version": "1.2"}}))
            self.assertEqual(kde.installed_version(home, "w"), "1.2")
            kde.install_widget(widget, home, dry_run=False)

    def test_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "apply",
                    "--dry-run",
                    "--layout",
                    "--home",
                    str(home),
                ],
                cwd=tmp,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"--file {home}/.config/kwinrc", result.stdout)
            self.assertIn("Would replace all panels", result.stdout)
            self.assertFalse(home.exists())


if __name__ == "__main__":
    unittest.main()
