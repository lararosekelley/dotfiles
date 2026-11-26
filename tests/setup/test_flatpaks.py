"""scripts/setup/flatpaks against a fake flatpak in a throwaway home."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/flatpaks"
LIST = """\
# remote       app             also
flathub        org.example.A
flathub        org.example.B   net.example.B
artcraft-oci   ai.example.C
"""

# Records each call, and keeps the installed apps in a file: `info` succeeds
# for an app listed there, and `install` adds to it.
FLATPAK = """\
#!/usr/bin/env bash
echo "flatpak $*" >> "{log}"
case "$1" in
  info) grep -qx -- "$2" "{state}" ;;
  install)
    shift 4
    printf '%s\\n' "$@" >> "{state}"
    ;;
esac
"""


class FlatpaksTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.state = self.tmp / "installed"
        self.state.write_text("")
        self.list = self.tmp / "flatpaks.txt"
        self.list.write_text(LIST)
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "grep", "dirname"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"
        flatpak = self.bin / "flatpak"
        flatpak.write_text(FLATPAK.format(log=self.log, state=self.state))
        flatpak.chmod(0o755)

    def run_script(self, *args):
        self.log.write_text("")
        env = {
            "PATH": self.path,
            "HOME": str(self.tmp),
            "SETUP_FLATPAKS": str(self.list),
        }
        return subprocess.run(
            [str(SCRIPT), *args],
            env=env,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
        )

    def changes(self):
        return [
            line
            for line in self.log.read_text().splitlines()
            if not line.startswith("flatpak info")
        ]

    def test_a_fresh_home_gets_every_app_per_user(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.changes(),
            [
                "flatpak remote-add --user --if-not-exists flathub "
                "https://dl.flathub.org/repo/flathub.flatpakrepo",
                "flatpak install --user --noninteractive flathub "
                "org.example.A org.example.B",
                "flatpak remote-add --user --if-not-exists artcraft-oci "
                "https://getartcraft.com/artcraft-oci.flatpakrepo",
                "flatpak install --user --noninteractive artcraft-oci ai.example.C",
            ],
        )

    def test_a_second_run_changes_nothing(self):
        self.run_script()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("flatpaks: all present", result.stdout)
        self.assertEqual(self.changes(), [])

    def test_only_the_missing_apps_and_their_remotes_are_added(self):
        self.state.write_text("org.example.A\nai.example.C\n")
        self.run_script()
        self.assertEqual(len(self.changes()), 2)
        self.assertIn(
            "flatpak install --user --noninteractive flathub org.example.B",
            self.changes(),
        )

    def test_another_id_for_the_same_app_counts_as_installed(self):
        self.state.write_text("org.example.A\nnet.example.B\nai.example.C\n")
        result = self.run_script()
        self.assertIn("flatpaks: all present", result.stdout)

    def test_a_dry_run_touches_nothing(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: flatpak install --user", result.stdout)
        self.assertEqual(self.changes(), [])

    def test_an_unknown_remote_is_skipped(self):
        self.list.write_text("elsewhere org.example.D\n")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unknown remote elsewhere", result.stderr)
        self.assertEqual(self.changes(), [])

    def test_without_flatpak_nothing_runs(self):
        (self.bin / "flatpak").unlink()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("flatpak is missing", result.stderr)

    def test_a_failed_install_fails_the_script(self):
        (self.bin / "flatpak").write_text(
            f'#!/usr/bin/env bash\necho "flatpak $*" >> "{self.log}"\n'
            '[ "$1" = install ] && exit 1\n[ "$1" != info ]\n'
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("failed: flatpak install", result.stderr)

    def test_the_real_list_is_well_formed(self):
        lines = (REPO / "scripts/setup/flatpaks.txt").read_text().splitlines()
        entries = [line.split() for line in lines if line and not line.startswith("#")]
        self.assertGreater(len(entries), 20)
        for remote, *ids in entries:
            self.assertIn(remote, ("flathub", "artcraft-oci"))
            self.assertTrue(ids)


if __name__ == "__main__":
    unittest.main()
