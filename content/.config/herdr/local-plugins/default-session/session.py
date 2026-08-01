#!/usr/bin/env python3
"""herdr default-session plugin.

Scaffold a default layout on startup, with tab/pane helpers:

    session.py startup            scaffold, but only if the session is untouched
    session.py apply              scaffold the current space unconditionally
    session.py apply-if-new       scaffold a space that has nothing in it yet
    session.py move-tab left      swap the focused tab with its neighbor
    session.py rehydrate          relaunch programs in panes restored as bare shells
    session.py balance            reset every split in the focused tab to 50/50
    session.py toggle-mouse       flip ui.mouse_capture and reload the config

The layout itself lives in layout.json next to this file.
"""

from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import sys
import time
from pathlib import Path

PLUGIN_ROOT = Path(
    os.environ.get("HERDR_PLUGIN_ROOT") or Path(__file__).resolve().parent
)
LAYOUT_FILE = PLUGIN_ROOT / "layout.json"
CONFIG_FILE = Path.home() / ".config" / "herdr" / "config.toml"
SHELL_NAMES = {"bash", "zsh", "fish", "sh", "dash", "ksh", "nu", "elvish"}

# how long to let a freshly spawned pane finish sourcing rc files
SETTLE_TIMEOUT_SECONDS = 5.0
SETTLE_POLL_SECONDS = 0.2

# how long one run's claim on building a space or a tab stays valid
CLAIM_TTL_SECONDS = 60.0

# shells restored from a snapshot have long since settled, so rehydrate only
# needs to outwait rc files, not a cold start
REHYDRATE_SETTLE_SECONDS = 1.5


# socket api
# --------


def socket_path() -> str:
    from_env = os.environ.get("HERDR_SOCKET_PATH")
    if from_env:
        return from_env
    return str(Path.home() / ".config" / "herdr" / "herdr.sock")


def call(method: str, params: dict | None = None) -> dict:
    """Send one newline-delimited json request and return its result."""
    request = json.dumps(
        {"id": f"default-session:{method}", "method": method, "params": params or {}}
    )

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as conn:
        conn.connect(socket_path())
        stream = conn.makefile("rwb")
        stream.write(request.encode() + b"\n")
        stream.flush()
        line = stream.readline()

    if not line:
        raise RuntimeError(f"{method}: no response from herdr")

    message = json.loads(line)
    if "error" in message:
        raise RuntimeError(
            f"{method}: {message['error'].get('message', message['error'])}"
        )
    return message["result"]


def snapshot() -> dict:
    return call("session.snapshot")["snapshot"]


def wait_for_root_pane() -> dict:
    """Snapshot the session once it actually has a pane to look at."""
    deadline = time.monotonic() + SETTLE_TIMEOUT_SECONDS
    while True:
        snap = snapshot()
        if snap.get("panes") or time.monotonic() >= deadline:
            return snap
        time.sleep(SETTLE_POLL_SECONDS)


# reading the session tree
# --------


def space_tabs(snap: dict, workspace_id: str) -> list[dict]:
    return [tab for tab in snap["tabs"] if tab["workspace_id"] == workspace_id]


def space_panes(snap: dict, workspace_id: str) -> list[dict]:
    return [pane for pane in snap["panes"] if pane["workspace_id"] == workspace_id]


def tab_panes(snap: dict, tab_id: str) -> list[dict]:
    return [pane for pane in snap["panes"] if pane["tab_id"] == tab_id]


# layout building
# --------


def shell_wrap(command: str, requires_repo: bool = False) -> list[str]:
    """Run a program, then fall back to an interactive shell instead of dying."""
    command = command.replace("{plugin_root}", str(PLUGIN_ROOT))
    if requires_repo:
        # lazygit/tuicr/ghzinga only make sense inside a checkout; outside one,
        # say so once and leave a usable shell behind
        script = (
            "if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then "
            f"{command}; "
            f'else printf "%s\\n" "not in a repo - run: {command}"; fi'
        )
    else:
        script = command
    return ["bash", "-lc", f'{script}; exec "${{SHELL:-/bin/bash}}"']


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
    lazygit/tuicr/ghzinga have something to chew on from a ~-rooted space.
    """
    if is_git_repo(space_cwd):
        return space_cwd

    default = spec.get("default_repo")
    if default:
        expanded = str(Path(default).expanduser())
        if is_git_repo(expanded):
            return expanded
    return space_cwd


def to_layout_node(node: dict, cwd: str | None, repo: str | None = None) -> dict:
    if node.get("type") == "split":
        return {
            "type": "split",
            "direction": node["direction"],
            "ratio": node["ratio"],
            "first": to_layout_node(node["first"], cwd, repo),
            "second": to_layout_node(node["second"], cwd, repo),
        }

    pane: dict = {"type": "pane"}
    if node.get("label"):
        pane["label"] = node["label"]

    pane_cwd = repo if node.get("requires_repo") else cwd
    if pane_cwd:
        pane["cwd"] = pane_cwd
    if node.get("command"):
        pane["command"] = node["command"]
    elif node.get("run"):
        pane["command"] = shell_wrap(node["run"], bool(node.get("requires_repo")))
    return pane


def load_layout() -> dict:
    return json.loads(LAYOUT_FILE.read_text())


def plugin_context() -> dict:
    raw = os.environ.get("HERDR_PLUGIN_CONTEXT_JSON")
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def space_root_cwd(snap: dict, workspace_id: str) -> str | None:
    """Anchor every pane to the space's own cwd rather than whatever has focus."""
    context = plugin_context()

    # only trust the invocation context for the space it actually describes,
    # otherwise rebuilding several spaces would give them all the focused cwd
    if context.get("workspace_id") == workspace_id and context.get("workspace_cwd"):
        return context["workspace_cwd"]

    panes = space_panes(snap, workspace_id)
    return panes[0]["cwd"] if panes else None


def target_workspace(snap: dict) -> str:
    return os.environ.get("HERDR_WORKSPACE_ID") or snap["focused_workspace_id"]


def wanted_tabs(spec: dict, primary: bool) -> list[dict]:
    """The layout tabs a space should have.

    Global monitors belong in one place, not once per project space.
    """
    return [tab for tab in spec["tabs"] if primary or not tab.get("primary_only")]


def apply_tab(
    spec_tab: dict,
    cwd: str | None,
    repo: str | None,
    tab_id: str | None = None,
    workspace_id: str | None = None,
) -> str:
    """Build one tab from its layout spec, replacing tab_id when given."""
    params: dict = {
        "tab_label": spec_tab["label"],
        "root": to_layout_node(spec_tab["layout"], cwd, repo),
        "focus": False,
    }
    # tab_id and workspace_id are mutually exclusive: replacing a tab already
    # implies its space
    if tab_id:
        params["tab_id"] = tab_id
    else:
        params["workspace_id"] = workspace_id

    return call("layout.apply", params)["layout"]["tab_id"]


def apply_layout(snap: dict, workspace_id: str, primary: bool = True) -> None:
    spec = load_layout()
    cwd = space_root_cwd(snap, workspace_id)
    repo = repo_cwd(cwd, spec)
    tabs = space_tabs(snap, workspace_id)

    # the first tab replaces the tab we start from, the rest are appended
    replace_tab_id = tabs[0]["tab_id"] if tabs else None
    created: list[str] = []

    for index, tab in enumerate(wanted_tabs(spec, primary)):
        tab_id = apply_tab(
            tab,
            cwd,
            repo,
            tab_id=replace_tab_id if index == 0 else None,
            workspace_id=workspace_id,
        )
        created.append(tab_id)
        print(f"tab {index + 1}: {tab['label']} -> {tab_id}")

    focus_index = max(1, int(spec.get("focus_tab", 1))) - 1
    if focus_index < len(created):
        call("tab.focus", {"tab_id": created[focus_index]})

        # focusing a tab drags focus into its space, which is wrong when we are
        # building a space in the background
        focused_before = snap.get("focused_workspace_id")
        if focused_before and focused_before != workspace_id:
            call("workspace.focus", {"workspace_id": focused_before})


# entry points
# --------


def is_idle_shell(pane_id: str) -> bool:
    """True when a pane is sitting at a shell prompt with nothing running."""
    try:
        info = call("pane.process_info", {"pane_id": pane_id})["process_info"]
    except RuntimeError:
        return False

    foreground = info.get("foreground_processes") or []
    if len(foreground) != 1:
        return False
    name = (foreground[0].get("name") or "").lstrip("-")
    return name in SHELL_NAMES and info.get("foreground_process_group_id") == info.get(
        "shell_pid"
    )


def settles_to_idle_shell(
    pane_id: str, timeout: float = SETTLE_TIMEOUT_SECONDS
) -> bool:
    """Wait out .bashrc before judging whether a pane is busy.

    Startup hooks fire milliseconds after the root pane spawns, while the shell
    is still sourcing rc files and running completion subshells. Sampling once
    there reads as "something is running", so poll until it goes quiet.
    """
    deadline = time.monotonic() + timeout
    while True:
        if is_idle_shell(pane_id):
            return True
        if time.monotonic() >= deadline:
            return False
        time.sleep(SETTLE_POLL_SECONDS)


def agent_panes(panes: list[dict]) -> list[str]:
    """Panes herdr tracks as agents, including ones waiting to be resumed.

    Agent session refs are persisted, so a restored claude pane can still look
    like an idle shell for a moment. Rebuilding it would throw away a resumable
    conversation, so agent metadata vetoes a rebuild on its own.
    """
    return [
        pane["pane_id"]
        for pane in panes
        if pane.get("agent") or pane.get("agent_session")
    ]


def busy_pane(panes: list[dict], settle_seconds: float) -> str | None:
    """The first pane with something running in it, if any."""
    return next(
        (
            pane["pane_id"]
            for pane in panes
            if not settles_to_idle_shell(pane["pane_id"], settle_seconds)
        ),
        None,
    )


def in_use_reason(panes: list[dict], settle_seconds: float) -> str | None:
    """Why these panes hold real work, or None when they are all bare shells."""
    agents = agent_panes(panes)
    if agents:
        return f"agent in {', '.join(agents)}"

    busy = busy_pane(panes, settle_seconds)
    if busy:
        return f"something is running in {busy}"
    return None


def not_fresh_reason(
    snap: dict, workspace_id: str, settle_seconds: float = SETTLE_TIMEOUT_SECONDS
) -> str | None:
    """Why this space should be left alone, or None when it is ours to build.

    A restored space already has its tabs (and possibly running agents), so a
    single tab holding a single idle shell is the signal that this one is fresh.
    Judged per space, not per session: other spaces being open says nothing about
    whether this one has anything in it.
    """
    tabs = space_tabs(snap, workspace_id)
    panes = space_panes(snap, workspace_id)
    if len(tabs) != 1 or len(panes) != 1:
        return f"{len(tabs)} tab(s) and {len(panes)} pane(s) already open"

    return in_use_reason(panes, settle_seconds)


def claim_path(key: str) -> Path:
    state_dir = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR") or "/tmp")
    state_dir.mkdir(parents=True, exist_ok=True)
    return state_dir / f"building-{key.replace(':', '_')}"


def claim(key: str) -> bool:
    """Take a short-lived claim on building a space or a single tab.

    The startup hook and the workspace.created event can both fire for the space
    a fresh session opens with. Whoever claims it first builds it; the other
    backs off. Claims are released when the build finishes and age out if a run
    dies holding one, so a later rebuild is never blocked by a stale claim.
    """
    marker = claim_path(key)

    try:
        os.close(os.open(marker, os.O_CREAT | os.O_EXCL | os.O_WRONLY))
        return True
    except FileExistsError:
        pass
    except OSError:
        return True  # no writable state dir; don't let the guard block work

    age = time.time() - marker.stat().st_mtime
    if age < CLAIM_TTL_SECONDS:
        return False

    marker.touch()
    return True


def release(key: str) -> None:
    try:
        claim_path(key).unlink()
    except OSError:
        pass


def cmd_startup() -> int:
    """Build a fresh session, or relaunch a restored one.

    Every space that comes back as bare shells starts programs again. Panes get
    the longer settle window here, since a server that just started is still
    spawning shells and resuming agents.
    """
    if load_layout().get("rehydrate_on_startup", True):
        return rehydrate_pass(SETTLE_TIMEOUT_SECONDS)

    snap = wait_for_root_pane()
    workspace_id = target_workspace(snap)

    reason = not_fresh_reason(snap, workspace_id)
    if reason:
        print(f"leaving the session alone: {reason}")
        return 0

    if not claim(workspace_id):
        print(f"{workspace_id} is already being built; leaving it alone")
        return 0

    try:
        apply_layout(snap, workspace_id)
    finally:
        release(workspace_id)
    return 0


def cmd_apply() -> int:
    snap = snapshot()
    apply_layout(snap, target_workspace(snap))
    return 0


def is_primary(snap: dict, workspace_id: str) -> bool:
    """Session's first space is the primary one, whichever path builds it."""
    spaces = snap["workspaces"]
    return bool(spaces) and spaces[0]["workspace_id"] == workspace_id


def cmd_apply_if_new() -> int:
    """workspace.created path: build the space only if nothing is in it yet."""
    snap = wait_for_root_pane()
    workspace_id = target_workspace(snap)

    tabs = space_tabs(snap, workspace_id)
    if len(tabs) > 1:
        print(f"{workspace_id} already has {len(tabs)} tabs; leaving it alone")
        return 0

    if not claim(workspace_id):
        print(f"{workspace_id} is already being built; leaving it alone")
        return 0

    try:
        apply_layout(snap, workspace_id, primary=is_primary(snap, workspace_id))
    finally:
        release(workspace_id)
    return 0


def rehydrate_space(snap: dict, space: dict, spec: dict, settle_seconds: float) -> int:
    """Relaunch the programs in one restored space, tab by tab.

    Tab at a time rather than space at a time because the agents tab is expected
    to hold a claude herdr resumed on restore: vetoing the whole space over it
    would leave nvim, lazygit, and the monitors sitting as bare shells for the
    rest of the session. Tabs are matched to the layout by label, so a tab that
    isn't in layout.json is left where it is.
    """
    workspace_id = space["workspace_id"]
    cwd = space_root_cwd(snap, workspace_id)
    repo = repo_cwd(cwd, spec)
    by_label = {
        tab["label"]: tab for tab in wanted_tabs(spec, is_primary(snap, workspace_id))
    }
    relaunched = 0

    for tab in space_tabs(snap, workspace_id):
        tab_id = tab["tab_id"]
        where = f"{space['label']}/{tab['label']}"

        spec_tab = by_label.get(tab["label"])
        if not spec_tab:
            print(f"{where}: not in layout.json, leaving it alone")
            continue

        reason = in_use_reason(tab_panes(snap, tab_id), settle_seconds)
        if reason:
            print(f"{where}: {reason}, leaving it alone")
            continue

        if not claim(tab_id):
            print(f"{where}: already being built, leaving it alone")
            continue

        print(f"{where}: relaunching")
        try:
            apply_tab(spec_tab, cwd, repo, tab_id=tab_id)
        finally:
            release(tab_id)
        relaunched += 1

    return relaunched


def rehydrate_pass(settle_seconds: float) -> int:
    """Restore previous processes in each pane in every space/tab.

    A restored session brings back spaces, tabs, splits, and cwds, but every
    pane comes back as a bare shell. Relaunch what belongs in those panes, and
    leave anything with real work in it alone. A space with nothing in it yet
    gets the whole layout instead.
    """
    snap = wait_for_root_pane()
    spec = load_layout()
    built = 0
    relaunched = 0

    for space in snap["workspaces"]:
        workspace_id = space["workspace_id"]

        if not_fresh_reason(snap, workspace_id, settle_seconds):
            relaunched += rehydrate_space(snap, space, spec, settle_seconds)
            continue

        if not claim(workspace_id):
            print(f"{space['label']}: already being built, leaving it alone")
            continue

        print(f"{space['label']}: building")
        try:
            apply_layout(snap, workspace_id, primary=is_primary(snap, workspace_id))
        finally:
            release(workspace_id)
        built += 1

    print(f"rehydrated {relaunched} tab(s), built {built} space(s)")
    return 0


def cmd_rehydrate() -> int:
    return rehydrate_pass(REHYDRATE_SETTLE_SECONDS)


def cmd_move_tab(direction: str) -> int:
    snap = snapshot()
    workspace_id = target_workspace(snap)
    tabs = [
        tab["tab_id"] for tab in snap["tabs"] if tab["workspace_id"] == workspace_id
    ]
    focused = os.environ.get("HERDR_TAB_ID") or snap.get("focused_tab_id")

    if focused not in tabs or len(tabs) < 2:
        return 0

    index = tabs.index(focused)
    if direction == "left":
        if index == 0:
            return 0
        target = index - 1
    else:
        if index >= len(tabs) - 1:
            return 0
        # insert_index counts positions before the tab is lifted out, so moving
        # one slot right means skipping past both it and its neighbor
        target = index + 2

    call("tab.move", {"tab_id": focused, "insert_index": target})
    return 0


def split_paths(node: dict, path: list[bool] | None = None) -> list[list[bool]]:
    """Every split in a layout tree, addressed the way layout.set_split_ratio wants."""
    path = path or []
    if node.get("type") != "split":
        return []
    return (
        [path]
        + split_paths(node["first"], path + [False])
        + split_paths(node["second"], path + [True])
    )


def cmd_balance() -> int:
    tab_id = os.environ.get("HERDR_TAB_ID") or snapshot().get("focused_tab_id")
    if not tab_id:
        return 0

    layout = call("layout.export", {"tab_id": tab_id})["layout"]
    paths = split_paths(layout["root"])
    for path in paths:
        call("layout.set_split_ratio", {"tab_id": tab_id, "path": path, "ratio": 0.5})

    print(f"balanced {len(paths)} split(s) in {tab_id}")
    return 0


def cmd_toggle_mouse() -> int:
    """prefix+m / prefix+M, as a single toggle."""
    text = CONFIG_FILE.read_text()
    match = re.search(r"^(\s*mouse_capture\s*=\s*)(true|false)\s*$", text, re.MULTILINE)
    if not match:
        print(f"no mouse_capture setting found in {CONFIG_FILE}", file=sys.stderr)
        return 1

    enabled = match.group(2) == "true"
    CONFIG_FILE.write_text(
        text[: match.start()]
        + f"{match.group(1)}{str(not enabled).lower()}"
        + text[match.end() :]
    )
    call("server.reload_config")

    state = "off" if enabled else "on"
    call(
        "notification.show",
        {"title": "herdr", "body": f"mouse mode: {state}", "sound": "none"},
    )
    print(f"mouse capture {state}")
    return 0


def main(argv: list[str]) -> int:
    command = argv[1] if len(argv) > 1 else "startup"

    if command == "startup":
        return cmd_startup()
    if command == "apply":
        return cmd_apply()
    if command == "apply-if-new":
        return cmd_apply_if_new()
    if command == "move-tab":
        return cmd_move_tab(argv[2] if len(argv) > 2 else "right")
    if command == "rehydrate":
        return cmd_rehydrate()
    if command == "balance":
        return cmd_balance()
    if command == "toggle-mouse":
        return cmd_toggle_mouse()

    print(f"unknown command: {command}", file=sys.stderr)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except (OSError, RuntimeError) as error:
        print(f"default-session: {error}", file=sys.stderr)
        sys.exit(1)
