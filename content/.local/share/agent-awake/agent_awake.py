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


def lease(root, client, owner, session, actor, action):
    scope = scope_id(client, owner, session)
    key = hashlib.sha256(f"{scope}:{actor}".encode()).hexdigest()
    path = root / f"{key}.json"
    with locked(root):
        if action == "end":
            for item in root.glob("*.json"):
                if load(item).get("scope") == scope:
                    item.unlink(missing_ok=True)
            return
        if action == "off":
            path.unlink(missing_ok=True)
            return
        if action != "on":
            raise ValueError("Expected on, off, or end")
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
        state = {
            "scope": scope,
            "client": client,
            "owner": owner,
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
                        f"--who=Agent Awake ({client})",
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


def claude_action(event):
    kind = event.get("hook_event_name")
    if kind == "SessionEnd":
        return "end"
    if kind in {
        "Stop",
        "StopFailure",
        "SubagentStop",
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
        "SubagentStart",
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
