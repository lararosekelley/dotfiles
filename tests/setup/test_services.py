"""scripts/setup/services against a fake systemctl in a throwaway home."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/services"
LIST = """\
# scope  unit            needs           machine
user     alpha.service   ~/bin/alpha     -
user     beta.service    beta            -
system   gamma.service   gamma           desktop
system   delta.service   delta           framework
"""

# A unit is enabled when its name is in the state file,
# and `enable` adds to it; `show-environment` fails without a user session.
SYSTEMCTL = """\
args=("$@")
[ "$1" = --user ] && args=("${{@:2}}")
case "${{args[0]}}" in
  is-enabled) grep -qx -- "${{args[-1]}}" "{state}" ;;
  enable) printf '%s\\n' "${{args[@]:2}}" >> "{state}" ;;
  show-environment) [ ! -e "{tmp}/no-session" ] ;;
esac
"""


class ServicesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.state = self.tmp / "enabled"
        self.state.write_text("")
        self.list = self.tmp / "services.txt"
        self.list.write_text(LIST)
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "grep", "dirname"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"
        (self.tmp / "bin/alpha").write_text("")
        for name in ("beta", "gamma", "delta"):
            self.stub(name)
        self.stub("sudo", '"$@"')
        self.stub(
            "systemctl",
            SYSTEMCTL.format(state=self.state, tmp=self.tmp),
        )

    def stub(self, name, body="exit 0"):
        script = self.bin / name
        script.write_text(
            f'#!/usr/bin/env bash\necho "{name} $*" >> "{self.log}"\n{body}\n'
        )
        script.chmod(0o755)

    def run_script(self, *args, machine="desktop"):
        self.log.write_text("")
        env = {
            "PATH": self.path,
            "HOME": str(self.tmp),
            "SETUP_SERVICES": str(self.list),
            "SETUP_MACHINE": machine,
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
            c
            for c in self.log.read_text().splitlines()
            if "enable --now" in c or "daemon-reload" in c
        ]

    def test_a_fresh_desktop_enables_its_units(self):
        result = self.run_script("--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.changes(),
            [
                "systemctl --user daemon-reload",
                "systemctl --user enable --now alpha.service beta.service",
                "sudo systemctl enable --now gamma.service",
                "systemctl enable --now gamma.service",
            ],
        )

    def test_a_second_run_changes_nothing(self):
        self.run_script("--yes")
        result = self.run_script("--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.changes(), [])
        self.assertEqual(result.stdout.count("enabled: "), 3)

    def test_other_machines_skip_the_desktop_units(self):
        self.run_script("--yes", machine="framework")
        self.assertIn("sudo systemctl enable --now delta.service", self.changes())
        self.assertNotIn("sudo systemctl enable --now gamma.service", self.changes())

    def test_a_unit_whose_program_is_missing_is_skipped(self):
        (self.tmp / "bin/alpha").unlink()
        result = self.run_script("--yes")
        self.assertIn("alpha.service: ~/bin/alpha is not installed", result.stderr)
        self.assertIn("systemctl --user enable --now beta.service", self.changes())

    def test_without_a_terminal_sudo_is_never_run(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            "systemctl --user enable --now alpha.service beta.service",
            self.changes(),
        )
        self.assertFalse([c for c in self.changes() if c.startswith("sudo")])
        self.assertIn("not enabled (no terminal, or declined)", result.stderr)

    def test_without_a_user_session_user_units_are_reported(self):
        (self.tmp / "no-session").write_text("")
        result = self.run_script("--yes")
        self.assertIn("no systemd user session", result.stderr)
        self.assertFalse([c for c in self.changes() if "--user" in c])

    def test_a_dry_run_changes_nothing(self):
        result = self.run_script("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: sudo systemctl enable --now", result.stdout)
        self.assertEqual(self.changes(), [])

    def test_a_failed_enable_fails_the_script(self):
        self.stub("sudo", "exit 1")
        result = self.run_script("--yes")
        self.assertEqual(result.returncode, 1)

    def test_the_real_list_is_well_formed(self):
        lines = (REPO / "scripts/setup/services.txt").read_text().splitlines()
        entries = [line.split() for line in lines if line and not line.startswith("#")]
        self.assertTrue(entries)
        for scope, unit, needs, machine in entries:
            self.assertIn(scope, ("user", "system"))
            self.assertTrue(unit.endswith((".service", ".timer")), unit)
            self.assertIn(machine, ("-", "framework", "thinkpad", "desktop"))


if __name__ == "__main__":
    unittest.main()
