"""scripts/setup/config-repos against local stand-ins for the GitHub repos."""

from pathlib import Path
import subprocess
import tempfile
import unittest

from remotes import config, environment, git, make_remote

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/config-repos"
REPOS = {
    ".config/nvim": "nvim",
    ".emacs.d": "emacs.d",
    ".config/kitty": "kitty",
    ".config/herdr": "herdr",
    ".config/tuios": "tuios",
}
# stands in for the nvim repo's installer: records each run and its arguments
INSTALL_DEPS = (
    '#!/usr/bin/env bash\necho "ran $*" >> "$HOME/deps.log"\nexit "${DEPS_EXIT:-0}"\n'
)


class ConfigReposTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(subprocess.run, ["rm", "-rf", str(self.tmp)])
        self.home = self.tmp / "home"
        self.home.mkdir()
        self.remotes = self.tmp / "remotes"
        for name in REPOS.values():
            files = None
            if name == "nvim":
                files = {"scripts/install-deps": (INSTALL_DEPS, True)}
            make_remote(self.remotes, f"lararosekelley/{name}", files)
        self.env = environment(self.home, self.remotes)

    def run_script(self, *args, **env):
        return subprocess.run(
            [str(SCRIPT), *args],
            env={**self.env, **env},
            capture_output=True,
            text=True,
        )

    def deps_runs(self):
        log = self.home / "deps.log"
        return log.read_text().splitlines() if log.exists() else []

    def test_a_fresh_home_gets_every_repo_with_an_ssh_push_url(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        for path, name in REPOS.items():
            checkout = self.home / path
            url = f"https://github.com/lararosekelley/{name}"
            self.assertEqual(config(self.env, checkout, "remote.origin.url"), url)
            push = config(self.env, checkout, "remote.origin.pushurl")
            self.assertEqual(push, f"git@github.com:lararosekelley/{name}")
        self.assertEqual(self.deps_runs(), ["ran "])

    def test_a_second_run_clones_nothing_and_leaves_push_urls_alone(self):
        self.run_script()
        nvim = self.home / ".config/nvim"
        git("-C", str(nvim), "config", "remote.origin.pushurl", "git@example.com:mine")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("cloned", result.stdout)
        self.assertEqual(result.stderr, "")
        pushurl = config(self.env, nvim, "remote.origin.pushurl")
        self.assertEqual(pushurl, "git@example.com:mine")

    def test_an_existing_ssh_checkout_counts_as_present(self):
        kitty = self.home / ".config/kitty"
        git("init", "-q", str(kitty))
        git(
            "-C",
            str(kitty),
            "remote",
            "add",
            "origin",
            "git@github.com:lararosekelley/kitty",
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"present: {kitty}\n", result.stdout)
        self.assertEqual(config(self.env, kitty, "remote.origin.pushurl"), "")

    def test_a_dry_run_clones_nothing(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: git clone", result.stdout)
        self.assertIn("once nvim is cloned", result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_a_dry_run_passes_dry_run_to_install_deps(self):
        self.run_script()
        self.run_script("--dry-run")
        self.assertEqual(self.deps_runs(), ["ran ", "ran --dry-run"])

    def test_a_failing_install_deps_fails_the_script(self):
        result = self.run_script(DEPS_EXIT="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("failed:", result.stderr)

    def test_an_nvim_checkout_without_install_deps_only_warns(self):
        nvim = self.home / ".config/nvim"
        git("init", "-q", str(nvim))
        git(
            "-C",
            str(nvim),
            "remote",
            "add",
            "origin",
            "https://github.com/lararosekelley/nvim",
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("install-deps is missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
