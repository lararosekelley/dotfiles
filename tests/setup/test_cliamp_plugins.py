"""scripts/setup/cliamp-plugins against a fake cliamp in a throwaway home."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/cliamp-plugins"
LIST = """\
# name       source
album-art    someone/cliamp-plugin-album-art@v1.0.0
other        https://example.com/other.lua
"""

# Records each call, and keeps the installed plugins in a file as "name
# version" lines: `plugins list` prints them as cliamp does, and `plugins
# install --yes SOURCE` adds one.
CLIAMP = """\
#!/usr/bin/env bash
echo "cliamp $*" >> "{log}"
case "$1 $2" in
  "plugins list")
    if [ -s "{state}" ]; then
      echo "NAME TYPE VERSION TRUST DESCRIPTION"
      while read -r name version; do
        echo "$name hook $version trusted x"
      done < "{state}"
    else
      echo "No plugins installed."
    fi ;;
  "plugins install")
    case "$4" in
      *album-art*) echo "album-art 1.0.0" >> "{state}" ;;
      *) echo "other 0.1.0" >> "{state}" ;;
    esac ;;
esac
"""


class CliampPluginsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.state = self.tmp / "installed"
        self.state.write_text("")
        self.list = self.tmp / "cliamp-plugins.txt"
        self.list.write_text(LIST)
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "awk", "dirname"):
            (system / command).symlink_to(shutil.which(command))
        self.system = system
        cliamp = self.bin / "cliamp"
        cliamp.write_text(CLIAMP.format(log=self.log, state=self.state))
        cliamp.chmod(0o755)

    def run_script(self, *args, path=None):
        self.log.write_text("")
        return subprocess.run(
            [str(SCRIPT), *args],
            env={
                "PATH": path or f"{self.bin}:{self.system}",
                "HOME": str(self.tmp),
                "SETUP_CLIAMP_PLUGINS": str(self.list),
            },
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
        )

    def installs(self):
        return [
            line
            for line in self.log.read_text().splitlines()
            if line.startswith("cliamp plugins install")
        ]

    def test_a_fresh_home_gets_every_plugin_then_a_rerun_changes_nothing(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.installs(),
            [
                "cliamp plugins install --yes someone/cliamp-plugin-album-art@v1.0.0",
                "cliamp plugins install --yes https://example.com/other.lua",
            ],
        )
        again = self.run_script()
        self.assertEqual(again.returncode, 0, again.stderr)
        self.assertEqual(self.installs(), [])
        self.assertIn("2 already installed", again.stdout)

    def test_another_version_is_left_alone_with_a_warning(self):
        self.state.write_text("album-art 0.9.0\nother 0.1.0\n")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.installs(), [])
        self.assertIn("album-art is 0.9.0, not 1.0.0", result.stderr)

    def test_dry_run_changes_nothing(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.installs(), [])
        self.assertIn("would run: cliamp plugins install --yes", result.stdout)
        self.assertEqual(self.state.read_text(), "")

    def test_without_cliamp_it_warns_and_skips(self):
        result = self.run_script(path=str(self.system))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("cliamp is missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
