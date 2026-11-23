import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SHARED = REPO / "content/.local/share/default-session"


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


rules = module("default_session_layout", SHARED / "layout.py")
LAYOUT = json.loads((SHARED / "layout.json").read_text())


def checkout(origin):
    """A throwaway git checkout whose origin remote is `origin`."""
    path = tempfile.mkdtemp()
    subprocess.run(["git", "init", "-q", path], check=True)
    if origin:
        subprocess.run(
            ["git", "-C", path, "remote", "add", "origin", origin], check=True
        )
    return path


def labels(slug, primary=False):
    return [tab["label"] for tab in rules.wanted_tabs(LAYOUT, primary, slug)]


class RepoSlugTest(unittest.TestCase):
    def test_reads_owner_and_name_from_common_remote_forms(self):
        for origin in (
            "git@github.com:Higharc/GitOps.git",
            "https://github.com/higharc/gitops",
            "https://github.com/higharc/gitops.git/",
            "ssh://git@github.com/higharc/gitops.git",
        ):
            with self.subTest(origin=origin):
                self.assertEqual(rules.repo_slug(checkout(origin)), "higharc/gitops")

    def test_none_outside_a_checkout_or_without_origin(self):
        self.assertIsNone(rules.repo_slug(tempfile.mkdtemp()))
        self.assertIsNone(rules.repo_slug(checkout(None)))
        self.assertIsNone(rules.repo_slug(None))


class RepoScopedTabsTest(unittest.TestCase):
    def test_k8s_tab_only_in_matching_repos_between_git_and_review(self):
        for slug in ("higharc/gitops", "higharc/infra"):
            with self.subTest(slug=slug):
                tabs = labels(slug)
                self.assertEqual(
                    tabs[tabs.index("git") + 1 : tabs.index("review")], ["k8s"]
                )

        for slug in ("higharc/product", "lararosekelley/dotfiles", None):
            with self.subTest(slug=slug):
                self.assertNotIn("k8s", labels(slug))

    def test_explicit_apply_still_respects_repos(self):
        self.assertNotIn("k8s", labels("higharc/product", primary=None))
        self.assertIn("k8s", labels("higharc/gitops", primary=None))

    def test_tabs_without_repos_are_unaffected(self):
        unscoped = [tab["label"] for tab in LAYOUT["tabs"] if not tab.get("repos")]
        self.assertEqual([t for t in labels("higharc/product", primary=None)], unscoped)

    def test_globs_match_case_insensitively(self):
        tab = {"label": "x", "repos": ["Higharc/*"]}
        self.assertTrue(rules.matches_repo(tab, "higharc/anything"))
        self.assertFalse(rules.matches_repo(tab, "other/anything"))


class PrimaryPanesTest(unittest.TestCase):
    def shell_panes(self, primary):
        shell = next(
            t for t in rules.wanted_tabs(LAYOUT, primary) if t["label"] == "shell"
        )
        second = shell["layout"]["second"]
        return [second["first"], second["second"]]

    def test_home_space_gets_calendar_and_music(self):
        panes = self.shell_panes(True)
        self.assertEqual(
            [(p["label"], p.get("run")) for p in panes],
            [("calendar", "callie"), ("music", "cliamp")],
        )
        self.assertTrue(all(p["type"] == "pane" for p in panes))

    def test_repo_spaces_and_apply_keep_scratch_and_watch(self):
        for primary in (False, None):
            with self.subTest(primary=primary):
                panes = self.shell_panes(primary)
                self.assertEqual([p["label"] for p in panes], ["scratch", "watch"])
                self.assertFalse(any("in_primary" in p for p in panes))


class TabIconTest(unittest.TestCase):
    def test_every_tab_has_an_icon_before_its_name(self):
        for tab in LAYOUT["tabs"]:
            with self.subTest(tab=tab["label"]):
                self.assertEqual(
                    rules.display_name(tab), f"{tab['icon']} {tab['label']}"
                )

    def test_names_from_before_icons_still_match(self):
        tab = {"label": "git", "icon": "x"}
        by_name = rules.tabs_by_name([tab])
        self.assertIs(by_name["git"], tab)
        self.assertIs(by_name["x git"], tab)
        self.assertEqual(rules.display_name({"label": "plain"}), "plain")


class MultiplexerScriptsTest(unittest.TestCase):
    def test_both_scripts_load_the_shared_rules(self):
        herdr = module(
            "herdr_session",
            REPO / "content/.config/herdr/local-plugins/default-session/session.py",
        )
        tuios = module(
            "tuios_session", REPO / "content/.config/tuios/default-session/session.py"
        )
        self.assertEqual(herdr.load_layout(), LAYOUT)
        self.assertEqual(tuios.rules.load_layout(), LAYOUT)


if __name__ == "__main__":
    unittest.main()
