#!/usr/bin/env python3
"""tuios default session: the shared default-session layout, built in tuios.

    session.py build SESSION...        build sessions holding only their first shell
    session.py apply SESSION           add every layout tab SESSION is missing
    session.py rehydrate [SESSION...]  relaunch programs in panes restored as shells
    session.py open [REPO...]          open home plus a session per repo, then rehydrate
    session.py set-agent NAME          save the harness `{agent}` panes run

A herdr space is a tuios session and a herdr tab is a tuios workspace. Tabs,
panes, and the rules for which tabs a session gets come from
~/.local/share/default-session, which the herdr plugin reads too.

Programs are typed into the pane's shell rather than exec'd, so quitting one
leaves a usable prompt. A shell's command count (tuios shell integration) tells
a pane restored after a daemon restart, which has run nothing, from one that
already ran its program.
"""

from __future__ import annotations

import importlib.util
import json
import os
import shlex
import subprocess
import sys
import time
from pathlib import Path

# ~/.config/tuios/default-session -> ~/.local/share/default-session
SHARED_LAYOUT = (
    Path(__file__).resolve().parents[3] / ".local" / "share" / "default-session"
)
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
AGENT_FILE = STATE_DIR / "tui" / "agent"
TUIOS = os.environ.get("TUIOS_BIN") or "tuios"

# the session opened on ~, which gets the primary_only tabs
PRIMARY_SESSION = "home"
WORKSPACE_COUNT = 9

PROMPT_TIMEOUT_SECONDS = 10.0
POLL_SECONDS = 0.2


def load_rules():
    spec = importlib.util.spec_from_file_location(
        "default_session_layout", SHARED_LAYOUT / "layout.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


rules = load_rules()


# tuios cli
# --------


def tuios(*args: str, check: bool = True) -> subprocess.CompletedProcess:
    result = subprocess.run([TUIOS, *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise RuntimeError(f"tuios {' '.join(args[:2])}: {detail}")
    return result


def call(verb: str, params: dict) -> dict:
    return json.loads(tuios("call", verb, json.dumps(params)).stdout)


def session_names() -> list[str]:
    return [session["name"] for session in call("list-sessions", {})["sessions"]]


def windows(session: str) -> list[dict]:
    return call("list-windows", {"session": session}).get("windows") or []


def workspace_names(session: str) -> dict[int, str]:
    listing = call("list-workspaces", {"session": session})["workspaces"]
    return {space["workspace"]: space["name"] for space in listing if space["name"]}


def used_workspaces(session: str) -> set[int]:
    return {window["workspace"] for window in windows(session)}


# panes
# --------


def is_idle_shell(window: dict) -> bool:
    """True when a pane's shell is at its prompt with nothing in the foreground."""
    if not window.get("at_prompt"):
        return False

    pid = window.get("pid")
    try:
        comm = Path(f"/proc/{pid}/comm").read_text().strip().lstrip("-")
        stat = Path(f"/proc/{pid}/stat").read_text()
    except OSError:
        return False

    # fields after the parenthesised comm: state ppid pgrp session tty tpgid
    tpgid = int(stat[stat.rfind(")") + 2 :].split()[5])
    return comm in rules.SHELL_NAMES and tpgid == pid


def wait_for_prompts(session: str, window_ids: set[str]) -> dict[str, dict]:
    """Wait out rc files so typed commands land at a prompt."""
    deadline = time.monotonic() + PROMPT_TIMEOUT_SECONDS
    while True:
        current = {w["window_id"]: w for w in windows(session)}
        waiting = [i for i in window_ids if not current.get(i, {}).get("at_prompt")]
        if not waiting or time.monotonic() >= deadline:
            return current
        time.sleep(POLL_SECONDS)


def type_command(session: str, window_id: str, command: str) -> None:
    tuios("send-text", "-s", session, "-w", window_id, f"{command}\n")


def is_resumable(session: str, window_id: str) -> bool:
    """Whether tuios holds an agent conversation to resume in this pane."""
    result = tuios(
        "resume-agent", "-s", session, "-w", window_id, "--dry-run", check=False
    )
    return result.returncode == 0


# layout
# --------


def chosen_agent(spec: dict) -> str:
    if AGENT_FILE.is_file() and AGENT_FILE.read_text().strip():
        return AGENT_FILE.read_text().strip()
    return spec["default_agent"]


def leaves(node: dict) -> list[dict]:
    if node.get("type") == "split":
        return leaves(node["first"]) + leaves(node["second"])
    return [node]


def pane_cwd(node: dict, cwd: str, repo: str | None) -> str:
    return (repo or cwd) if node.get("requires_repo") else cwd


def pane_command(node: dict, cwd: str, primary: bool | None, spec: dict) -> str | None:
    """What to type into a pane, or None for a plain shell."""
    run = node.get("run")
    if not run or not rules.in_scope(node, primary):
        return None

    command = rules.expand(run).replace("{agent}", chosen_agent(spec))
    if node.get("requires_repo") and not rules.is_git_repo(cwd):
        return "printf '%s\\n' " + shlex.quote(f"not in a repo - run: {command}")
    return command


def build_tree(
    session: str,
    node: dict,
    window_id: str,
    cwd: str,
    repo: str | None,
    launches: list[tuple[str, str]],
    primary: bool | None,
    spec: dict,
) -> None:
    """Split window_id into node's tree. The window is already named after
    node's first pane, and the split's second half after its own first pane."""
    if node.get("type") != "split":
        command = pane_command(node, pane_cwd(node, cwd, repo), primary, spec)
        if command:
            launches.append((window_id, command))
        return

    first_of_second = leaves(node["second"])[0]
    params = {
        "session": session,
        "window": window_id,
        "side": "right" if node["direction"] == "right" else "down",
        "name": first_of_second.get("label", ""),
        "cwd": pane_cwd(first_of_second, cwd, repo),
        "focus": False,
    }
    # layout.json's ratio is the first half's share; tuios takes the new pane's
    if node.get("ratio", 0.5) != 0.5:
        params["ratio"] = round((1 - node["ratio"]) * 100)
    second_id = call("split-window", params)["window_id"]

    build_tree(session, node["first"], window_id, cwd, repo, launches, primary, spec)
    build_tree(session, node["second"], second_id, cwd, repo, launches, primary, spec)


def build_tabs(
    session: str,
    tabs: list[dict],
    cwd: str,
    primary: bool | None,
    spec: dict,
    reuse_window: str | None = None,
) -> list[int]:
    """Build each tab on the next empty workspace and launch its programs."""
    repo = rules.repo_cwd(cwd, spec)
    free = [
        n for n in range(1, WORKSPACE_COUNT + 1) if n not in used_workspaces(session)
    ]
    if reuse_window:
        free.insert(0, 1)

    launches: list[tuple[str, str]] = []
    built: list[int] = []

    for tab in tabs:
        if not free:
            print(f"{session}: no free workspace for {tab['label']}")
            break

        workspace = free.pop(0)
        first = leaves(tab["layout"])[0]
        if reuse_window and workspace == 1:
            window_id = reuse_window
            call(
                "set-window",
                {
                    "session": session,
                    "window": window_id,
                    "name": first.get("label", ""),
                },
            )
        else:
            window_id = call(
                "new-window",
                {
                    "session": session,
                    "workspace": workspace,
                    "name": first.get("label", ""),
                    "cwd": pane_cwd(first, cwd, repo),
                    "focus": False,
                },
            )["window_id"]

        build_tree(
            session, tab["layout"], window_id, cwd, repo, launches, primary, spec
        )
        call(
            "set-workspace-name",
            {
                "session": session,
                "workspace": workspace,
                "name": rules.display_name(tab),
            },
        )
        built.append(workspace)
        print(f"{session}: workspace {workspace} {tab['label']}")

    wait_for_prompts(session, {window_id for window_id, _ in launches})
    for window_id, command in launches:
        type_command(session, window_id, command)
    return built


def fresh_window(session: str) -> dict | None:
    """The lone untouched shell of a session nothing has been built in."""
    current = windows(session)
    if len(current) != 1 or workspace_names(session):
        return None
    window = current[0]
    if window["workspace"] != 1 or window.get("command_seq"):
        return None
    return window


def build_session(session: str, primary: bool | None) -> bool:
    window = fresh_window(session)
    if not window:
        return False

    spec = rules.load_layout()
    cwd = window["cwd"]
    tabs = rules.wanted_tabs(spec, primary, rules.repo_slug(cwd))
    built = build_tabs(session, tabs, cwd, primary, spec, window["window_id"])

    focus = max(1, int(spec.get("focus_tab", 1)))
    if focus <= len(built):
        call("select-workspace", {"session": session, "workspace": built[focus - 1]})
    return True


def is_primary(session: str) -> bool:
    return session == PRIMARY_SESSION


# entry points
# --------


def cmd_build(sessions: list[str]) -> int:
    for session in sessions:
        if not build_session(session, is_primary(session)):
            print(f"{session}: already has panes, leaving it alone")
    return 0


def cmd_apply(session: str) -> int:
    """Asking by hand means the whole set, primary_only and secondary_only too."""
    if build_session(session, None):
        return 0

    spec = rules.load_layout()
    have = set(workspace_names(session).values())
    cwd = windows(session)[0]["cwd"]
    missing = [
        tab
        for tab in rules.wanted_tabs(spec, None, rules.repo_slug(cwd))
        if tab["label"] not in have and rules.display_name(tab) not in have
    ]
    if not missing:
        print(f"{session}: every layout tab is already open")
        return 0

    build_tabs(session, missing, cwd, None, spec)
    return 0


def rehydrate_session(session: str, spec: dict) -> int:
    """Type each pane's program back into its restored shell."""
    primary = is_primary(session)
    names = workspace_names(session)
    by_name = rules.tabs_by_name(
        [rules.resolve_tab(tab, primary) for tab in spec["tabs"]]
    )
    restored = wait_for_prompts(session, {w["window_id"] for w in windows(session)})
    relaunched = 0

    for window in restored.values():
        tab = by_name.get(names.get(window["workspace"], ""))
        label = window.get("custom_name") or ""
        panes = (
            {node.get("label"): node for node in leaves(tab["layout"])} if tab else {}
        )
        node = panes.get(label)
        if not node:
            continue

        where = f"{session}/{tab['label']}/{label}"
        command = pane_command(node, window["cwd"], primary, spec)
        if not command:
            continue
        if window.get("command_seq") or not is_idle_shell(window):
            continue
        if "{agent}" in node["run"] and is_resumable(session, window["window_id"]):
            print(f"{where}: agent conversation to resume, leaving it to tuios")
            continue

        type_command(session, window["window_id"], command)
        print(f"{where}: relaunched")
        relaunched += 1
    return relaunched


def cmd_rehydrate(sessions: list[str], build: set[str] | None = None) -> int:
    """Relaunch programs everywhere, and build the sessions in `build`.

    Building is limited to sessions `tui` opened, so a session made by hand
    with `tuios new` keeps its single shell.
    """
    spec = rules.load_layout()
    built = relaunched = 0
    for session in sessions or session_names():
        if session in (build or set()) and build_session(session, is_primary(session)):
            built += 1
        else:
            relaunched += rehydrate_session(session, spec)
    print(f"relaunched {relaunched} pane(s), built {built} session(s)")
    return 0


def cmd_open(repos: list[str]) -> int:
    """Open the home session and one per repo, then build or relaunch them all.

    Starting the daemon restores every saved session, so a reboot comes back
    through the same rehydrate pass that fills in new sessions.
    """
    try:
        open_now = set(session_names())
    except RuntimeError:
        tuios("start-server")
        open_now = set(session_names())

    targets = [(PRIMARY_SESSION, Path.home())]
    for repo in repos:
        path = Path(repo).expanduser()
        if path.is_dir():
            targets.append((path.name, path))
        else:
            print(f"skipping missing repo: {repo}")

    for name, path in targets:
        if name in open_now:
            print(f"session already open: {name}")
            continue
        tuios("new", name, "--detach", "--cwd", str(path))
        print(f"session created: {name}")

    return cmd_rehydrate([], build={name for name, _ in targets})


def cmd_set_agent(name: str) -> int:
    AGENT_FILE.parent.mkdir(parents=True, exist_ok=True)
    AGENT_FILE.write_text(f"{name}\n")
    return 0


def main(argv: list[str]) -> int:
    command, args = (argv[1], argv[2:]) if len(argv) > 1 else ("", [])

    if command == "build" and args:
        return cmd_build(args)
    if command == "apply" and len(args) == 1:
        return cmd_apply(args[0])
    if command == "rehydrate":
        return cmd_rehydrate(args)
    if command == "open":
        return cmd_open(args)
    if command == "set-agent" and len(args) == 1:
        return cmd_set_agent(args[0])

    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except (OSError, RuntimeError) as error:
        print(f"tui session: {error}", file=sys.stderr)
        sys.exit(1)
