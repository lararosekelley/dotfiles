import concurrent.futures
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]
CONTENT = REPO / "content"
SOURCE = CONTENT / ".local/share/agent-awake"


def module(name):
    spec = importlib.util.spec_from_file_location(name, SOURCE / f"{name}.py")
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


awake = module("agent_awake")
installer = module("install")


def wait_for(predicate):
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.05)
    raise AssertionError("Timed out waiting for watchdog cleanup")


class Leases(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        # Fake only acquisition: execute the real watchdog, without a real
        # system sleep inhibitor. It keeps the same PID across exec.
        fake = self.base / "systemd-inhibit"
        fake.write_text(
            f"#!{sys.executable}\nimport os,sys\n"
            "os.execv(sys.argv[5], sys.argv[5:])\n"
        )
        fake.chmod(0o755)
        self.env = patch.dict(
            os.environ,
            {
                "XDG_RUNTIME_DIR": str(self.base),
                "PATH": f"{self.base}:{os.environ['PATH']}",
                "AGENT_AWAKE_TTL": "30",
            },
        )
        self.env.start()
        self.root = awake.runtime_dir()
        self.owner = subprocess.Popen(["sleep", "60"])
        self.workers = set()

    def tearDown(self):
        self.owner.terminate()
        self.owner.wait()
        for path in self.root.glob("*.json"):
            state = awake.load(path)
            if state.get("worker"):
                self.workers.add(state["worker"])
            path.unlink()
        for pid in self.workers:
            wait_for(lambda: awake.process_identity(pid) is None)
            try:
                os.waitpid(pid, os.WNOHANG)
            except ChildProcessError:
                pass
        self.env.stop()
        self.temp.cleanup()

    def change(self, session="one", actor="main", action="on"):
        awake.lease(self.root, "test", self.owner.pid, session, actor, action)
        for path in self.root.glob("*.json"):
            state = awake.load(path)
            self.workers.add(state["worker"])

    def test_idempotent_refresh_and_stop(self):
        self.change()
        path = next(self.root.glob("*.json"))
        before = awake.load(path)
        self.change()
        after = awake.load(path)
        self.assertEqual(before["worker"], after["worker"])
        self.assertGreater(after["expires"], before["expires"])
        self.change(action="off")
        wait_for(lambda: awake.process_identity(before["worker"]) is None)

    def test_concurrent_start_has_one_worker(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            list(pool.map(lambda _: self.change(), range(6)))
        self.assertEqual(len(self.workers), 1)

    def test_independent_sessions_and_subagents(self):
        self.change()
        self.change(actor="child")
        self.change(session="two")
        self.change(action="off")
        self.assertEqual(len(list(self.root.glob("*.json"))), 2)
        self.change(action="end")
        self.assertEqual(len(list(self.root.glob("*.json"))), 1)

    def test_owner_exit_releases_lock(self):
        self.change()
        self.owner.terminate()
        self.owner.wait()
        wait_for(lambda: not list(self.root.glob("*.json")))

    def test_expiration_releases_lock(self):
        with patch.dict(os.environ, {"AGENT_AWAKE_TTL": "1"}):
            self.change()
        wait_for(lambda: not list(self.root.glob("*.json")))

    def test_pid_reuse_does_not_keep_lease(self):
        self.change()
        path = next(self.root.glob("*.json"))
        with awake.locked(self.root):
            state = awake.load(path)
            state["owner_start"] = "different-start-time"
            awake.save(path, state)
        wait_for(lambda: not path.exists())

    def test_restart_does_not_let_old_watchdog_delete_new_lease(self):
        self.change()
        old_worker = next(iter(self.workers))
        self.change(action="off")
        self.change()
        wait_for(lambda: awake.process_identity(old_worker) is None)
        states = [awake.load(p) for p in self.root.glob("*.json")]
        self.assertEqual(len(states), 1)
        self.assertNotEqual(states[0]["worker"], old_worker)

    def test_missing_inhibitor_cleans_up_request(self):
        with patch.object(awake.subprocess, "Popen", side_effect=FileNotFoundError):
            with self.assertRaises(FileNotFoundError):
                self.change()
        self.assertEqual(list(self.root.glob("*.json")), [])


class HooksAndInstall(unittest.TestCase):
    def test_claude_lifecycle(self):
        for event in [
            "UserPromptSubmit",
            "PostToolUse",
            "PostToolUseFailure",
            "SubagentStart",
            "PreCompact",
            "ElicitationResult",
        ]:
            self.assertEqual(awake.claude_action({"hook_event_name": event}), "on")
        for event in [
            "Stop",
            "StopFailure",
            "SubagentStop",
            "PermissionRequest",
            "Elicitation",
        ]:
            self.assertEqual(awake.claude_action({"hook_event_name": event}), "off")
        self.assertEqual(awake.claude_action({"hook_event_name": "SessionEnd"}), "end")
        for tool in ["AskUserQuestion", "ExitPlanMode", "Agent"]:
            self.assertEqual(
                awake.claude_action(
                    {"hook_event_name": "PreToolUse", "tool_name": tool}
                ),
                "off",
            )
        self.assertEqual(
            awake.claude_action({"hook_event_name": "PreToolUse", "tool_name": "Bash"}),
            "on",
        )
        self.assertIsNone(
            awake.claude_action(
                {"hook_event_name": "Notification", "notification_type": "auth_success"}
            )
        )

    def test_install_preserves_preferences_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            target = home / ".claude/settings.json"
            target.parent.mkdir()
            original = {
                "model": "keep-my-model",
                "hooks": {
                    "Stop": [
                        {"hooks": [{"type": "command", "command": "keep-my-hook"}]}
                    ]
                },
            }
            target.write_text(json.dumps(original))
            installer.install(CONTENT, home)
            first = json.loads(target.read_text())
            installer.install(CONTENT, home)
            self.assertEqual(first, json.loads(target.read_text()))
            self.assertEqual(first["model"], original["model"])
            self.assertEqual(first["hooks"]["Stop"][0], original["hooks"]["Stop"][0])
            self.assertEqual(len(list(target.parent.glob("*.bak"))), 1)
            template = json.loads((CONTENT / ".claude/settings.json").read_text())
            self.assertEqual(
                first, installer.merge_hooks(copy.deepcopy(first), template)
            )
            self.assertTrue((home / ".config/opencode/plugins/agent-awake.js").exists())


if __name__ == "__main__":
    unittest.main()
