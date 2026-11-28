"""home/dot_bin/executable_secrets-service against fake busctl and keyrings."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_secrets-service"


class SecretsServiceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.stub("gnome-keyring-daemon", f'echo "gnome-keyring $*" >> "{self.log}"')
        # only the tools the script needs, so this machine's own ksecretd
        # doesn't count
        self.system = self.tmp / "system"
        self.system.mkdir()
        for command in ("bash", "env", "cat", "grep", "seq", "sleep"):
            (self.system / command).symlink_to(shutil.which(command))

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def owned_after(self, calls):
        """busctl: the secrets service has no owner for the first calls."""
        count = self.tmp / "count"
        self.stub(
            "busctl",
            f'n=$(($(cat "{count}" 2>/dev/null || echo 0) + 1)); echo $n > "{count}"\n'
            f'[ $n -gt {calls} ] && echo "b true" || echo "b false"',
        )

    def run_script(self):
        result = subprocess.run(
            [str(SCRIPT)],
            env={"PATH": f"{self.bin}:{self.system}", "SECRETS_SERVICE_WAIT": "20"},
            capture_output=True,
            text=True,
            timeout=10,
        )
        calls = self.log.read_text().splitlines() if self.log.exists() else []
        return result.returncode, calls

    def test_with_kdes_wallet_it_waits_for_the_wallet(self):
        self.stub("ksecretd", "")
        self.owned_after(3)
        self.assertEqual(self.run_script(), (0, []))

    def test_without_kdes_wallet_it_starts_gnome_keyring(self):
        self.owned_after(0)
        code, calls = self.run_script()
        self.assertEqual(code, 0)
        self.assertEqual(
            calls, ["gnome-keyring --start --foreground --components=secrets"]
        )

    def test_a_wallet_that_never_comes_falls_back_to_gnome_keyring(self):
        self.stub("ksecretd", "")
        self.owned_after(1000)
        code, calls = self.run_script()
        self.assertEqual(code, 0)
        self.assertEqual(len(calls), 1)


if __name__ == "__main__":
    unittest.main()
