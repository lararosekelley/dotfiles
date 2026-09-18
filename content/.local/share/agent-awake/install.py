#!/usr/bin/env python3
"""Install from this dotfiles checkout, preserving unrelated live settings."""

import argparse
from datetime import datetime
import json
from pathlib import Path
import shutil

COMMAND = 'python3 "$HOME/.local/share/agent-awake/agent_awake.py" claude'


def merge_hooks(existing, template):
    hooks = existing.setdefault("hooks", {})
    for event, groups in template["hooks"].items():
        ours = []
        for group in groups:
            handlers = [h for h in group["hooks"] if h.get("command") == COMMAND]
            if handlers:
                ours.append({**group, "hooks": handlers})
        if not ours:
            continue
        kept = []
        for group in hooks.get(event, []):
            handlers = [h for h in group["hooks"] if h.get("command") != COMMAND]
            if handlers:
                kept.append({**group, "hooks": handlers})
        hooks[event] = kept + ours
    return existing


def install(content, home):
    source = content / ".local/share/agent-awake/agent_awake.py"
    plugin = content / ".config/opencode/plugins/agent-awake.js"
    target = home / ".claude/settings.json"
    template = json.loads((content / ".claude/settings.json").read_text())
    current = json.loads(target.read_text()) if target.exists() else {}
    merged = json.dumps(merge_hooks(current, template), indent=2) + "\n"
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    for src, dst in (
        (source, home / ".local/share/agent-awake/agent_awake.py"),
        (plugin, home / ".config/opencode/plugins/agent-awake.js"),
    ):
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists() and dst.read_bytes() == src.read_bytes():
            continue
        if dst.exists():
            shutil.copy2(dst, dst.with_name(f"{dst.name}.{stamp}.bak"))
        shutil.copyfile(src, dst)
        print(f"Installed {dst}")
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists() or target.read_text() != merged:
        if target.exists():
            backup = target.with_name(f"settings.json.{stamp}.bak")
            shutil.copy2(target, backup)
            backup.chmod(0o600)
            print(f"Settings backup: {backup}")
        target.write_text(merged)
        target.chmod(0o600)
        print(f"Merged hooks into {target}")
    print("Restart OpenCode and Claude Code to load the activity integrations.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home())
    args = parser.parse_args()
    install(Path(__file__).resolve().parents[3], args.home)
