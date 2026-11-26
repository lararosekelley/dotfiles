"""scripts/setup/packages against fake package managers in a throwaway home."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/packages"
LIST = """\
# check        fedora       arch        fallback
fd             fd-find      fd
font:Nunito    nunito-font  -
perl:JSON      perl-JSON    perl-json
/opt/marker    marker       marker
gcalcli        -            -           pipx install gcalcli
shfmt          -            shfmt       go install shfmt
"""


class PackagesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.list = self.tmp / "packages.txt"
        self.list.write_text(LIST.replace("/opt/marker", str(self.tmp / "marker")))
        # what the script itself runs, from the real system
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "grep", "dirname"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"
        for stub in ("sudo", "pipx", "go"):
            self.stub(stub)
        self.stub("perl", "exit 1")
        self.stub("fc-list")

    def stub(self, name, body="exit 0"):
        script = self.bin / name
        script.write_text(
            f'#!/usr/bin/env bash\necho "{name} $*" >> "{self.log}"\n{body}\n'
        )
        script.chmod(0o755)

    def everything_installed(self):
        self.stub("fd")
        self.stub("gcalcli")
        self.stub("shfmt")
        self.stub("perl")
        self.stub("fc-list", 'echo "/usr/share/fonts/Nunito.ttf: Nunito"')
        (self.tmp / "marker").write_text("")

    def run_script(self, distro, *args):
        os_release = self.tmp / "os-release"
        os_release.write_text(f"ID={distro}\n")
        env = {
            "PATH": self.path,
            "HOME": str(self.tmp),
            "SETUP_OS_RELEASE": str(os_release),
            "SETUP_PACKAGES": str(self.list),
        }
        self.log.write_text("")
        return subprocess.run(
            [str(SCRIPT), *args],
            env=env,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
        )

    def calls(self):
        return self.log.read_text().splitlines()

    def installs(self):
        """Calls that install something, leaving out the read-only checks."""
        return [c for c in self.calls() if c.split()[0] in ("sudo", "pipx", "go")]

    def test_fedora_plan_uses_fedora_names(self):
        result = self.run_script("fedora", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        dnf = "sudo dnf install -y --skip-unavailable fd-find nunito-font perl-JSON"
        self.assertIn(f"{dnf} marker", result.stdout)
        self.assertIn("would run: pipx install gcalcli", result.stdout)
        self.assertIn("would run: go install shfmt", result.stdout)
        self.assertEqual(self.installs(), [])

    def test_arch_plan_uses_arch_names_and_leaves_the_font_by_hand(self):
        result = self.run_script("arch", "--dry-run")
        pacman = "sudo pacman -S --needed --noconfirm fd perl-json marker shfmt"
        self.assertIn(pacman, result.stdout)
        self.assertIn("font:Nunito: no arch package", result.stderr)
        self.assertNotIn("go install", result.stdout)

    def test_a_set_up_machine_installs_nothing(self):
        self.everything_installed()
        result = self.run_script("fedora")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("system packages: all present", result.stdout)
        self.assertEqual(self.installs(), [])

    def test_only_the_gaps_are_filled(self):
        self.everything_installed()
        (self.bin / "fd").unlink()
        (self.bin / "gcalcli").unlink()
        result = self.run_script("fedora", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo dnf install -y --skip-unavailable fd-find", self.calls())
        self.assertIn("pipx install gcalcli", self.calls())
        self.assertEqual(len([c for c in self.calls() if c.startswith("sudo")]), 1)

    def test_without_a_terminal_sudo_is_never_run(self):
        self.everything_installed()
        (self.bin / "fd").unlink()
        result = self.run_script("fedora")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse([c for c in self.calls() if c.startswith("sudo")])
        self.assertIn("not installed (no terminal, or declined)", result.stderr)

    def test_a_fallback_needs_its_tool(self):
        (self.bin / "pipx").unlink()
        result = self.run_script("fedora", "--yes")
        self.assertIn("pipx is missing, so this was skipped", result.stderr)

    def test_an_unknown_distro_installs_nothing(self):
        result = self.run_script("debian", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse([c for c in self.calls() if c.startswith("sudo")])
        self.assertIn("isn't recognized", result.stderr)

    def test_a_failed_install_fails_the_script(self):
        self.stub("sudo", "exit 1")
        result = self.run_script("fedora", "--yes")
        self.assertEqual(result.returncode, 1)

    def test_the_real_list_is_well_formed(self):
        lines = (REPO / "scripts/setup/packages.txt").read_text().splitlines()
        entries = [line.split() for line in lines if line and not line.startswith("#")]
        self.assertGreater(len(entries), 20)
        for fields in entries:
            self.assertGreaterEqual(len(fields), 3, fields)
            check, fedora, arch, *fallback = fields
            if "-" in (fedora, arch) and not fallback:
                # only fonts are allowed to have no route on a distro
                self.assertTrue(check.startswith("font:"), fields)


if __name__ == "__main__":
    unittest.main()
