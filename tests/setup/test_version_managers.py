"""scripts/setup/version-managers against local stand-ins for the GitHub repos."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/version-managers"
REPOS = {
    ".pyenv": "pyenv/pyenv",
    ".pyenv/plugins/pyenv-virtualenv": "pyenv/pyenv-virtualenv",
    ".nodenv": "nodenv/nodenv",
    ".nodenv/plugins/node-build": "nodenv/node-build",
    ".rbenv": "rbenv/rbenv",
    ".rbenv/plugins/ruby-build": "rbenv/ruby-build",
}


def git(*args, cwd=None):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


class VersionManagersTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(subprocess.run, ["rm", "-rf", str(self.tmp)])
        self.home = self.tmp / "home"
        self.home.mkdir()
        remotes = self.tmp / "remotes"
        for name in REPOS.values():
            path = remotes / name
            path.mkdir(parents=True)
            git("init", "-q", "-b", "main", cwd=path)
            (path / "README").write_text(name)
            git("add", "README", cwd=path)
            git(
                "-c",
                "user.name=t",
                "-c",
                "user.email=t@t",
                "commit",
                "-qm",
                "init",
                cwd=path,
            )
        # every https://github.com/ clone comes from the local stand-ins instead
        self.env = {
            "PATH": os.environ["PATH"],
            "HOME": str(self.home),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": f"url.file://{remotes}/.insteadOf",
            "GIT_CONFIG_VALUE_0": "https://github.com/",
        }

    def run_script(self, *args):
        return subprocess.run(
            [str(SCRIPT), *args], env=self.env, capture_output=True, text=True
        )

    def origin(self, path):
        return subprocess.run(
            ["git", "-C", str(self.home / path), "config", "remote.origin.url"],
            env=self.env,
            capture_output=True,
            text=True,
        ).stdout.strip()

    def test_a_fresh_home_gets_every_repo(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        for path, name in REPOS.items():
            self.assertEqual(self.origin(path), f"https://github.com/{name}")

    def test_a_second_run_changes_nothing(self):
        self.run_script()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("cloned", result.stdout)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout.count("present: "), len(REPOS))

    def test_a_dry_run_touches_nothing(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: git clone", result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_a_folder_that_is_not_a_checkout_is_left_alone(self):
        (self.home / ".nodenv").mkdir()
        (self.home / ".nodenv/mine").write_text("keep")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(".nodenv exists but is not a git checkout", result.stderr)
        self.assertEqual((self.home / ".nodenv/mine").read_text(), "keep")
        self.assertEqual(self.origin(".rbenv"), "https://github.com/rbenv/rbenv")

    def test_a_checkout_of_another_repo_is_left_alone(self):
        other = self.home / ".rbenv"
        git("init", "-q", str(other))
        git("-C", str(other), "remote", "add", "origin", "https://example.com/fork")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("is a checkout of https://example.com/fork", result.stderr)
        self.assertEqual(self.origin(".rbenv"), "https://example.com/fork")

    def test_an_ssh_remote_counts_as_the_same_repo(self):
        self.run_script()
        git(
            "-C",
            str(self.home / ".pyenv"),
            "remote",
            "set-url",
            "origin",
            "git@github.com:pyenv/pyenv.git",
        )
        result = self.run_script()
        self.assertEqual(result.stderr, "")
        self.assertIn(f"present: {self.home}/.pyenv\n", result.stdout)

    def test_a_plain_plugin_folder_inside_a_checkout_is_not_mistaken_for_it(self):
        self.run_script()
        plugin = self.home / ".pyenv/plugins/pyenv-virtualenv"
        subprocess.run(["rm", "-rf", str(plugin)], check=True)
        plugin.mkdir(parents=True)
        result = self.run_script()
        self.assertIn(
            "pyenv-virtualenv exists but is not a git checkout", result.stderr
        )

    def test_a_failed_manager_clone_skips_its_plugin_and_a_retry_repairs_it(self):
        remote = self.tmp / "remotes/nodenv/nodenv"
        parked = self.tmp / "parked"
        remote.rename(parked)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertFalse((self.home / ".nodenv").exists())
        parked.rename(remote)
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.origin(".nodenv"), "https://github.com/nodenv/nodenv")
        self.assertEqual(
            self.origin(".nodenv/plugins/node-build"),
            "https://github.com/nodenv/node-build",
        )

    def test_a_failed_clone_is_reported_and_the_rest_still_run(self):
        subprocess.run(
            ["rm", "-rf", str(self.tmp / "remotes/nodenv/nodenv")], check=True
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("failed: git clone", result.stderr)
        self.assertEqual(self.origin(".rbenv"), "https://github.com/rbenv/rbenv")


if __name__ == "__main__":
    unittest.main()
