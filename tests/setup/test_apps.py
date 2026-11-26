"""scripts/setup/apps against fake package managers and downloads."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/setup/apps"
LIST = """\
# check  fedora  arch
alpha
  dnf:alpha,alpha-extra
  pacman:alpha
beta,/opt/beta
  rpm:https://example.com/beta-{fedora}.rpm
  aur:beta-bin
gamma
  repo:gamma@https://example.com/gamma.repo
  none
delta
  json:https://example.com/delta.json@.url
  -
"""
# apps-desktop.txt, beside the list
DESKTOP = """\
epsilon
  dnf:epsilon
  aur:epsilon
"""
ROUTES = {
    "alpha": "sudo dnf install -y alpha alpha-extra",
    "beta": "sudo dnf install -y https://example.com/beta-45.rpm",
    "gamma": "sudo dnf install -y gamma",
    "delta": "sudo dnf install -y https://example.com/delta-1.rpm",
    "epsilon": "sudo dnf install -y epsilon",
}

# serves a .repo file defining [gamma-repo], or JSON naming delta's RPM
CURL = """\
case "$*" in
  *.repo*) printf '[gamma-repo]\\nname=Gamma\\n' ;;
  *.json*) echo '{"url": "https://example.com/delta-1.rpm"}' ;;
  *) exit 22 ;;
esac
"""


class AppsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.list = self.tmp / "apps.txt"
        self.list.write_text(LIST)
        (self.tmp / "apps-desktop.txt").write_text(DESKTOP)
        system = self.tmp / "system"
        system.mkdir()
        for command in (
            "bash",
            "env",
            "grep",
            "dirname",
            "sed",
            "tr",
            "awk",
            "head",
            "cat",
            "jq",
        ):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"
        for stub in ("sudo", "paru", "dnf"):
            self.stub(stub)
        self.stub("rpm", "echo 45")
        self.stub("curl", CURL)

    def stub(self, name, body="exit 0"):
        script = self.bin / name
        script.write_text(
            f'#!/usr/bin/env bash\necho "{name} $*" >> "{self.log}"\n{body}\n'
        )
        script.chmod(0o755)

    def run_script(self, distro, *args, machine="desktop"):
        os_release = self.tmp / "os-release"
        os_release.write_text(f"ID={distro}\n")
        env = {
            "PATH": self.path,
            "HOME": str(self.tmp),
            "SETUP_OS_RELEASE": str(os_release),
            "SETUP_APPS": str(self.list),
            "SETUP_MACHINE": machine,
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

    def changes(self):
        """Calls that install something, leaving out the read-only checks."""
        return [c for c in self.calls() if c.split()[0] in ("sudo", "paru")]

    def test_fedora_installs_each_app_by_its_route(self):
        result = self.run_script("fedora", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.changes(),
            [
                ROUTES["alpha"],
                ROUTES["beta"],
                "sudo dnf config-manager addrepo "
                "--from-repofile=https://example.com/gamma.repo",
                ROUTES["gamma"],
                ROUTES["delta"],
                ROUTES["epsilon"],
            ],
        )

    def test_arch_uses_pacman_and_paru_and_reports_what_has_no_route(self):
        result = self.run_script("arch", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.changes(),
            [
                "sudo pacman -S --needed --noconfirm alpha",
                "paru -S --needed --noconfirm beta-bin",
                "paru -S --needed --noconfirm epsilon",
            ],
        )
        self.assertIn("delta: no arch route; install it by hand", result.stderr)

    def test_a_dry_run_installs_nothing(self):
        result = self.run_script("fedora", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"would run: {ROUTES['delta']}", result.stdout)
        self.assertEqual(self.changes(), [])

    def test_installed_apps_are_skipped_under_any_of_their_checks(self):
        for name in ("alpha", "gamma", "delta", "epsilon"):
            self.stub(name)
        s = self.list.read_text().replace("/opt/beta", str(self.tmp / "beta"))
        self.list.write_text(s)
        (self.tmp / "beta").mkdir()
        result = self.run_script("fedora", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("apps: all present", result.stdout)
        self.assertEqual(self.changes(), [])

    def test_other_machines_skip_the_desktop_apps(self):
        for machine in ("framework", ""):
            self.run_script("fedora", "--yes", machine=machine)
            self.assertNotIn(ROUTES["epsilon"], self.changes())
            self.assertIn(ROUTES["alpha"], self.changes())

    def test_a_repo_already_set_up_is_not_added_again(self):
        self.stub("dnf", 'echo "gamma-repo  Gamma"')
        self.run_script("fedora", "--yes")
        self.assertIn(ROUTES["gamma"], self.changes())
        self.assertFalse([c for c in self.changes() if "addrepo" in c])

    def test_without_a_terminal_nothing_is_installed(self):
        result = self.run_script("fedora")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.changes(), [])
        self.assertIn("not installed (no terminal, or declined)", result.stderr)

    def test_the_aur_needs_paru(self):
        (self.bin / "paru").unlink()
        result = self.run_script("arch", "--yes")
        self.assertIn(
            "paru is missing, so this was skipped: aur:beta-bin", result.stderr
        )
        self.assertIn("sudo pacman -S --needed --noconfirm alpha", self.changes())

    def test_a_missing_download_fails_the_script(self):
        self.stub("curl", "exit 22")
        result = self.run_script("fedora", "--yes")
        self.assertEqual(result.returncode, 1)
        self.assertIn(
            "no download found at https://example.com/delta.json", result.stderr
        )

    def test_an_unknown_distro_installs_nothing(self):
        result = self.run_script("debian", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.changes(), [])

    def test_the_real_list_is_well_formed(self):
        lists = ("apps.txt", "apps-desktop.txt")
        text = "\n".join((REPO / "scripts/setup" / n).read_text() for n in lists)
        fields = " ".join(line.split("#")[0] for line in text.splitlines()).split()
        self.assertEqual(len(fields) % 3, 0)
        kinds = ("dnf", "rpm", "repo", "json", "pacman", "aur")
        for i in range(0, len(fields), 3):
            for route in fields[i + 1 : i + 3]:
                if route in ("none", "-"):
                    continue
                kind, value = route.split(":", 1)
                self.assertIn(kind, kinds, route)
                if kind == "repo" and not value.split("@")[1].startswith("https://"):
                    self.assertTrue((REPO / value.split("@")[1]).is_file(), route)


if __name__ == "__main__":
    unittest.main()
