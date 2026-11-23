"""The default session layout and the rules for which tabs a space gets.

Shared by the herdr default-session plugin and the tuios default-session
script, so both multiplexers build the same tabs from layout.json.
"""

from __future__ import annotations

import json
import re
import subprocess
from fnmatch import fnmatch
from pathlib import Path

LAYOUT_ROOT = Path(__file__).resolve().parent
LAYOUT_FILE = LAYOUT_ROOT / "layout.json"
SHELL_NAMES = {"bash", "zsh", "fish", "sh", "dash", "ksh", "nu", "elvish"}


def load_layout() -> dict:
    return json.loads(LAYOUT_FILE.read_text())


def expand(command: str) -> str:
    return command.replace("{layout_root}", str(LAYOUT_ROOT))


def is_git_repo(path: str | None) -> bool:
    if not path or not Path(path).is_dir():
        return False
    result = subprocess.run(
        ["git", "-C", path, "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() == "true"


def repo_cwd(space_cwd: str | None, spec: dict) -> str | None:
    """Where the repo-bound tools should run.

    A space opened on a checkout wins; otherwise fall back to default_repo so
    lazygit/tuicr/gh-dash have something to chew on from a ~-rooted space.
    """
    if is_git_repo(space_cwd):
        return space_cwd

    default = spec.get("default_repo")
    if default:
        expanded = str(Path(default).expanduser())
        if is_git_repo(expanded):
            return expanded
    return space_cwd


def repo_slug(path: str | None) -> str | None:
    """The `owner/name` of a checkout's origin remote, lowercased."""
    if not is_git_repo(path):
        return None
    result = subprocess.run(
        ["git", "-C", path, "remote", "get-url", "origin"],
        capture_output=True,
        text=True,
    )
    match = re.search(r"[:/]([^/:]+/[^/]+?)(?:\.git)?/?$", result.stdout.strip())
    return match.group(1).lower() if match else None


def in_scope(spec: dict, primary: bool | None) -> bool:
    """Whether a tab or a pane's program belongs in this kind of space.

    Global monitors belong in one place, not once per project space, and the
    repo-oriented TUIs have no repo to point at from the ~ space. `primary=None`
    asks for the whole set, which is what an explicit `apply` wants.
    """
    if primary is None:
        return True
    return not spec.get("secondary_only" if primary else "primary_only")


def matches_repo(spec_tab: dict, slug: str | None) -> bool:
    """Whether a tab limited to some repos belongs in a space on this one.

    `repos` holds `owner/name` globs matched against the space's own checkout,
    never default_repo, so a space outside a checkout gets none of these tabs.
    """
    patterns = spec_tab.get("repos")
    if not patterns:
        return True
    return slug is not None and any(fnmatch(slug, p.lower()) for p in patterns)


def for_space(node: dict, primary: bool | None) -> dict:
    """A layout tree with each pane's `in_primary` stand-in swapped in when the
    space is the primary one, and dropped otherwise."""
    if node.get("type") == "split":
        return {
            **node,
            "first": for_space(node["first"], primary),
            "second": for_space(node["second"], primary),
        }
    pane = {key: value for key, value in node.items() if key != "in_primary"}
    if primary and node.get("in_primary"):
        return {"type": "pane", **node["in_primary"]}
    return pane


def resolve_tab(tab: dict, primary: bool | None) -> dict:
    return {**tab, "layout": for_space(tab["layout"], primary)}


def wanted_tabs(
    spec: dict, primary: bool | None, slug: str | None = None
) -> list[dict]:
    """The layout tabs a space should have, resolved for that space."""
    return [
        resolve_tab(tab, primary)
        for tab in spec["tabs"]
        if in_scope(tab, primary) and matches_repo(tab, slug)
    ]
