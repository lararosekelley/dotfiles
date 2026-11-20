#!/usr/bin/env python3
"""Apply the KDE Plasma desktop from this checkout, or capture its panel layout."""

import argparse
import difflib
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile

DATA = Path(__file__).resolve().parent / "kde"
LAYOUT_PREFIX = "var layout = "
LAYOUT_SUFFIX = "plasma.loadSerializedLayout(layout);"
# Per-machine state: dialog sizes, screen indexes, and the weather location.
DROP_GROUPS = {"/ConfigDialog", "/WeatherStation"}
DROP_KEYS = {"popupHeight", "popupWidth", "lastScreen"}


def config_commands(config, config_dir):
    commands = []
    for name, groups in config.items():
        for group, entries in groups.items():
            for key, value in entries.items():
                commands.append(
                    [
                        "kwriteconfig6",
                        "--file",
                        str(config_dir / name),
                        "--group",
                        group,
                        "--key",
                        key,
                        value,
                    ]
                )
    return commands


def theme_commands(settings):
    return [
        ["plasma-apply-lookandfeel", "--apply", settings["look_and_feel"]],
        ["plasma-apply-colorscheme", settings["color_scheme"]],
        ["plasma-apply-colorscheme", "--accent-color", settings["accent_color"]],
        ["/usr/libexec/plasma-changeicons", settings["icon_theme"]],
    ]


def missing_packages(packages):
    if not shutil.which("rpm"):
        print("rpm not found; skipping package check")
        return []
    return [
        name
        for name in packages
        if subprocess.run(["rpm", "-q", name], capture_output=True).returncode
    ]


def installed_version(home, widget_id):
    metadata = home / ".local/share/plasma/plasmoids" / widget_id / "metadata.json"
    if not metadata.exists():
        return None
    return json.loads(metadata.read_text()).get("KPlugin", {}).get("Version")


def install_widget(widget, home, dry_run):
    version = widget["ref"].removeprefix("v")
    current = installed_version(home, widget["id"])
    if current == version:
        return
    action = "--upgrade" if current else "--install"
    print(f"{widget['id']}: {current or 'not installed'} to {version}")
    if dry_run:
        return
    with tempfile.TemporaryDirectory() as tmp:
        run(
            ["git", "clone", "--quiet", "--depth", "1", "--branch", widget["ref"]]
            + [widget["repo"], tmp]
        )
        run(
            [
                "kpackagetool6",
                "--type",
                "Plasma/Applet",
                action,
                str(Path(tmp) / widget["path"]),
            ]
        )


def qdbus():
    for name in ("qdbus6", "qdbus-qt6", "qdbus"):
        if shutil.which(name):
            return name
    raise SystemExit("qdbus not found")


def shell_call(method, *args):
    command = [
        qdbus(),
        "org.kde.plasmashell",
        "/PlasmaShell",
        f"org.kde.PlasmaShell.{method}",
        *args,
    ]
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout


def parse_dump(script):
    start = script.index(LAYOUT_PREFIX) + len(LAYOUT_PREFIX)
    end = script.rindex(LAYOUT_SUFFIX)
    return json.loads(script[start:end].strip().rstrip(";"))


def clean_config(config):
    cleaned = {}
    for group, entries in config.items():
        if group in DROP_GROUPS:
            continue
        kept = {k: v for k, v in entries.items() if k not in DROP_KEYS}
        if kept:
            cleaned[group] = kept
    return cleaned


def sanitize(layout):
    """Keep panels and widgets; desktops hold icon positions and wallpaper paths."""
    panels = []
    for panel in layout["panels"]:
        applets = [
            {**applet, "config": clean_config(applet["config"])}
            for applet in panel["applets"]
        ]
        panels.append(
            {**panel, "applets": applets, "config": clean_config(panel["config"])}
        )
    return {**layout, "desktops": [], "panels": panels}


def layout_script(layout):
    return (
        "var plasma = getApiVersion(1);\n"
        "panels().forEach(function (panel) { panel.remove(); });\n"
        f"{LAYOUT_PREFIX}{json.dumps(layout)};\n"
        f"{LAYOUT_SUFFIX}\n"
    )


def run(command):
    subprocess.run(command, check=True)


def apply(settings, home, dry_run, layout):
    missing = missing_packages(settings["packages"])
    if missing:
        print("Install missing packages first: sudo dnf install " + " ".join(missing))
    for widget in settings["widgets"]:
        install_widget(widget, home, dry_run)
    commands = theme_commands(settings) + config_commands(
        settings["config"], home / ".config"
    )
    for command in commands:
        if dry_run:
            print(shlex.join(command))
        else:
            run(command)
    if layout:
        script = layout_script(json.loads((DATA / "layout.json").read_text()))
        if dry_run:
            print("Would replace all panels with scripts/kde/layout.json")
        else:
            shell_call("evaluateScript", script)
            print("Replaced panels with scripts/kde/layout.json")
    if not dry_run:
        print("Log out and back in to apply every setting.")


def capture(dump, target, dry_run):
    layout = sanitize(parse_dump(dump))
    text = json.dumps(layout, indent=2, ensure_ascii=False) + "\n"
    current = target.read_text() if target.exists() else ""
    if text == current:
        print(f"{target} is up to date")
        return
    if dry_run:
        diff = difflib.unified_diff(
            current.splitlines(keepends=True),
            text.splitlines(keepends=True),
            str(target),
            "captured",
        )
        print("".join(diff), end="")
        return
    target.write_text(text)
    print(f"Saved {target}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    apply_parser = commands.add_parser("apply", help="apply theme, widgets, settings")
    apply_parser.add_argument("--home", type=Path, default=Path.home())
    apply_parser.add_argument("--dry-run", action="store_true")
    apply_parser.add_argument(
        "--layout", action="store_true", help="replace all panels with layout.json"
    )
    capture_parser = commands.add_parser(
        "capture", help="save the current panels to layout.json"
    )
    capture_parser.add_argument(
        "--dry-run", action="store_true", help="print the diff instead of saving"
    )
    args = parser.parse_args(argv)
    if args.command == "capture":
        dump = shell_call("dumpCurrentLayoutJS")
        capture(dump, DATA / "layout.json", args.dry_run)
    else:
        settings = json.loads((DATA / "settings.json").read_text())
        apply(settings, args.home, args.dry_run, args.layout)


if __name__ == "__main__":
    main()
