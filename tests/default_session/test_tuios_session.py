import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "content/.config/tuios/default-session/session.py"

spec = importlib.util.spec_from_file_location("tuios_default_session", SCRIPT)
session = importlib.util.module_from_spec(spec)
spec.loader.exec_module(session)

LAYOUT = session.rules.load_layout()


def tab(label):
    return next(t for t in LAYOUT["tabs"] if t["label"] == label)


class PaneCommandTest(unittest.TestCase):
    def test_primary_only_run_is_left_out_of_repo_sessions(self):
        main = session.leaves(tab("shell")["layout"])[0]
        self.assertEqual(session.pane_command(main, "/", True, LAYOUT), "fastfetch")
        self.assertIsNone(session.pane_command(main, "/", False, LAYOUT))

    def test_repo_tools_print_a_hint_outside_a_checkout(self):
        lazygit = session.leaves(tab("git")["layout"])[0]
        command = session.pane_command(lazygit, tempfile.mkdtemp(), False, LAYOUT)
        self.assertIn("not in a repo - run: lazygit", command)
        self.assertTrue(command.startswith("printf"))

    def test_agent_placeholder_takes_the_saved_pick(self):
        agent = session.leaves(tab("agents")["layout"])[0]
        with mock.patch.object(session, "chosen_agent", return_value="claude"):
            self.assertEqual(session.pane_command(agent, "/", False, LAYOUT), "claude")


class BuildTreeTest(unittest.TestCase):
    def test_replays_the_split_tree_and_names_each_pane(self):
        calls = []

        def fake_call(verb, params):
            calls.append((verb, params))
            return {"window_id": params["name"]}

        launches = []
        with mock.patch.object(session, "call", side_effect=fake_call):
            session.build_tree(
                "s", tab("shell")["layout"], "main", "/", None, launches, True, LAYOUT
            )

        splits = [(p["window"], p["side"], p["name"]) for _, p in calls]
        self.assertEqual(
            splits, [("main", "right", "scratch"), ("scratch", "down", "watch")]
        )
        self.assertEqual(launches, [("main", "fastfetch")])

    def test_uneven_ratio_becomes_the_new_panes_percent(self):
        node = {
            "type": "split",
            "direction": "down",
            "ratio": 0.7,
            "first": {"type": "pane", "label": "a"},
            "second": {"type": "pane", "label": "b"},
        }
        with mock.patch.object(
            session, "call", return_value={"window_id": "b"}
        ) as call:
            session.build_tree("s", node, "a", "/", None, [], None, LAYOUT)
        self.assertEqual(call.call_args.args[1]["ratio"], 30)


if __name__ == "__main__":
    unittest.main()
