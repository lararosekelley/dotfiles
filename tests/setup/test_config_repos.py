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
# stands in for herdr: reports the Claude integration as installed once its hook
# script exists, and records each install
HERDR = """#!/usr/bin/env bash
hook="$HOME/.claude/hooks/herdr-agent-state.sh"
case "$1 $2" in
"integration status")
  if [ -e "$hook" ]; then echo "claude: current (v11) ($hook)"
  else echo "claude: not installed ($hook)"; fi ;;
"integration install")
  echo "install $3" >> "$HOME/herdr.log"
  mkdir -p "${hook%/*}" && : > "$hook" ;;
esac
"""


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
        # only the stand-in herdr, never one installed on this machine
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        herdr = self.bin / "herdr"
        herdr.write_text(HERDR)
        herdr.chmod(0o755)
        self.env["PATH"] = f"{self.bin}:/usr/local/bin:/usr/bin:/bin"

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

    def herdr_installs(self):
        log = self.home / "herdr.log"
        return log.read_text().splitlines() if log.exists() else []

    def test_herdr_claude_hook_is_installed_once(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("present: herdr's claude integration", result.stdout)
        self.assertEqual(self.herdr_installs(), ["install claude"])

    def test_a_dry_run_does_not_install_the_herdr_hook(self):
        result = self.run_script("--dry-run")
        self.assertIn("would run: herdr integration install claude", result.stdout)
        self.assertEqual(self.herdr_installs(), [])

    def test_without_herdr_the_hook_is_skipped_with_a_warning(self):
        (self.bin / "herdr").unlink()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("herdr is not installed", result.stderr)

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
