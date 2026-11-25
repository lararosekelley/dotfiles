#!/usr/bin/env python3
"""Activity leases held by systemd-inhibit; no daemon or third-party packages."""

import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid


def process_identity(pid):
    """Use Linux start ticks as well as PID, including zombie detection."""
    try:
        fields = Path(f"/proc/{int(pid)}/stat").read_text().rsplit(")", 1)[1].split()
        return None if fields[0] == "Z" else fields[19]
    except (OSError, ValueError, IndexError):
        return None


def directory(pid):
    try:
        path = os.readlink(f"/proc/{int(pid)}/cwd")
    except (OSError, ValueError):
        return None
    home = os.path.expanduser("~")
    if path == home or path.startswith(home + "/"):
        return "~" + path[len(home) :]
    return path


def claude_owner():
    pid = os.getppid()
    while pid > 1:
        try:
            base = Path(f"/proc/{pid}")
            comm = (base / "comm").read_text().strip()
            args = (base / "cmdline").read_bytes().split(b"\0")
            if comm == "claude" or any(
                b"/@anthropic-ai/claude-code/" in arg for arg in args[:2]
            ):
                return pid
            pid = int((base / "stat").read_text().rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    raise RuntimeError("Cannot identify Claude's owning process; skipping inhibitor")


def runtime_dir():
    # Do not fall back to a predictable shared /tmp directory.
    root = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    if root.stat().st_uid != os.getuid():
        raise RuntimeError("Runtime directory is not owned by this user")
    root = root / "agent-awake"
    root.mkdir(mode=0o700, exist_ok=True)
    if root.is_symlink() or root.stat().st_uid != os.getuid():
        raise RuntimeError("Invalid agent-awake runtime directory")
    root.chmod(0o700)
    return root


@contextlib.contextmanager
def locked(root):
    with (root / ".lock").open("a") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        yield


def load(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def save(path, state):
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(state))
    temp.replace(path)


def scope_id(client, owner, session):
    return hashlib.sha256(f"{client}:{owner}:{session}".encode()).hexdigest()


STOPPED_KEEP_SECONDS = 24 * 3600


def lease(root, client, owner, session, actor, action):
    """Apply on, off, or end; start and stop are on and off for a subagent.

    A subagent's tool hooks can land after its SubagentStop, which would take
    its lease back for the full TTL. Stopped subagents are remembered, and
    activity from one is ignored until a SubagentStart resumes it.
    """
    scope = scope_id(client, owner, session)
    key = hashlib.sha256(f"{scope}:{actor}".encode()).hexdigest()
    path = root / f"{key}.json"
    stopped_path = root / "stopped.state"
    with locked(root):
        stopped = load(stopped_path)
        if action == "end":
            for item in root.glob("*.json"):
                if load(item).get("scope") == scope:
                    item.unlink(missing_ok=True)
            return
        if action in {"off", "stop"}:
            path.unlink(missing_ok=True)
            if action == "stop":
                now = time.time()
                stopped = {
                    k: at
                    for k, at in stopped.items()
                    if now - at < STOPPED_KEEP_SECONDS
                }
                stopped[key] = now
                save(stopped_path, stopped)
            return
        if action == "start":
            if stopped.pop(key, None) is not None:
                save(stopped_path, stopped)
            action = "on"
        elif key in stopped:
            return
        if action != "on":
            raise ValueError("Expected on, off, end, start, or stop")
        identity = process_identity(owner)
        if not identity:
            return
        ttl = max(1, float(os.environ.get("AGENT_AWAKE_TTL", "7200")))
        state = load(path)
        worker_alive = state.get("worker_start") and (
            process_identity(state.get("worker", 0)) == state["worker_start"]
        )
        if worker_alive and state.get("owner_start") == identity:
            state["expires"] = time.monotonic() + ttl
            save(path, state)
            return
        token = uuid.uuid4().hex
        cwd = directory(owner)
        who = f"{client}, {cwd}" if cwd else client
        state = {
            "scope": scope,
            "client": client,
            "owner": owner,
            "directory": cwd,
            "owner_start": identity,
            "token": token,
            "expires": time.monotonic() + ttl,
        }
        save(path, state)
        try:
            # systemd-inhibit owns the lock FD while _hold runs. No sleep-infinity
            # grandchild can outlive the watchdog and accidentally retain it.
            with (root / "inhibit.log").open("ab") as log:
                child = subprocess.Popen(
                    [
                        "systemd-inhibit",
                        "--what=idle:sleep",
                        "--mode=block",
                        f"--who=Agent Awake ({who})",
                        "--why=Coding agent actively working",
                        sys.executable,
                        str(Path(__file__).resolve()),
                        "_hold",
                        key,
                        token,
                    ],
                    stdin=subprocess.DEVNULL,
                    stdout=log,
                    stderr=log,
                    start_new_session=True,
                    close_fds=True,
                )
            state.update(worker=child.pid, worker_start=process_identity(child.pid))
            save(path, state)
        except OSError:
            path.unlink(missing_ok=True)
            raise


def hold(root, key, token):
    if len(key) != 64 or any(c not in "0123456789abcdef" for c in key):
        raise ValueError("Invalid lease key")
    path = root / f"{key}.json"
    try:
        while True:
            with locked(root):
                state = load(path)
            if state.get("token") != token:
                break
            if time.monotonic() >= state["expires"]:
                break
            if process_identity(state["owner"]) != state["owner_start"]:
                break
            time.sleep(0.5)
    finally:
        with locked(root):
            if load(path).get("token") == token:
                path.unlink(missing_ok=True)


EVENT_LOG_BYTES = 256 * 1024


def log_event(root, event, action):
    """Record which hook fired and what it did, never prompt or tool content."""
    path = root / "events.log"
    entry = {
        "at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "event": event.get("hook_event_name"),
        "session": (event.get("session_id") or "")[:8],
        "agent": event.get("agent_id", "main"),
        "agent_type": event.get("agent_type"),
        "detail": event.get("tool_name") or event.get("notification_type"),
        "action": action,
    }
    with locked(root):
        with contextlib.suppress(OSError):
            if path.stat().st_size > EVENT_LOG_BYTES:
                path.replace(path.with_suffix(".log.1"))
        with path.open("a") as log:
            log.write(json.dumps({k: v for k, v in entry.items() if v}) + "\n")


def claude_action(event):
    kind = event.get("hook_event_name")
    if kind == "SessionEnd":
        return "end"
    if kind == "SubagentStart":
        return "start"
    if kind == "SubagentStop":
        return "stop"
    if kind in {
        "Stop",
        "StopFailure",
        "PermissionRequest",
        "Elicitation",
        "SessionStart",
    }:
        return "off"
    if kind == "Notification":
        if event.get("notification_type") in {
            "permission_prompt",
            "idle_prompt",
            "elicitation_dialog",
            "elicitation_url_dialog",
            "agent_needs_input",
            "agent_completed",
        }:
            return "off"
        return None
    if kind == "PreToolUse":
        # Subagents get their own leases via SubagentStart/Stop. The parent's
        # lease must not keep sleep blocked while the child asks for input.
        return (
            "off"
            if event.get("tool_name")
            in {"AskUserQuestion", "ExitPlanMode", "Agent", "Task"}
            else "on"
        )
    if kind in {
        "UserPromptSubmit",
        "PostToolUse",
        "PostToolUseFailure",
        "PreCompact",
        "PostCompact",
        "ElicitationResult",
    }:
        return "on"
    return None


def main():
    if sys.platform != "linux" or os.environ.get("AGENT_AWAKE_DISABLE") == "1":
        return
    mode = sys.argv[1]
    root = runtime_dir()
    if mode == "_hold":
        hold(root, *sys.argv[2:])
    elif mode == "opencode":
        action, session, owner = sys.argv[2:]
        lease(root, "opencode", int(owner), session, "main", action)
    elif mode == "claude":
        event = json.load(sys.stdin)
        action = claude_action(event)
        log_event(root, event, action)
        if action and event.get("session_id"):
            lease(
                root,
                "claude",
                claude_owner(),
                event["session_id"],
                event.get("agent_id", "main"),
                action,
            )
    elif mode in {"status", "clear"}:
        with locked(root):
            for path in root.glob("*.json"):
                state = load(path)
                if mode == "clear":
                    path.unlink(missing_ok=True)
                else:
                    alive = bool(state.get("worker_start")) and (
                        process_identity(state.get("worker", 0))
                        == state["worker_start"]
                    )
                    print(
                        json.dumps(
                            {
                                "lease": path.stem,
                                "client": state.get("client"),
                                "owner": state.get("owner"),
                                "directory": state.get("directory"),
                                "worker_alive": alive,
                                "seconds_left": max(
                                    0, round(state.get("expires", 0) - time.monotonic())
                                ),
                            }
                        )
                    )
    else:
        raise ValueError("Use claude, opencode, status, or clear")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # An optional power-management hook must never deny an agent's tool call.
        print(f"agent-awake: {error}", file=sys.stderr)
        if len(sys.argv) > 1 and sys.argv[1] == "_hold":
            sys.exit(1)
