"""system/fans-full against fake hwmon trees."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "system/fans-full"


class FansFullTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        self.count = 0

    def chip(self, name, *files):
        path = self.root / f"hwmon{self.count}"
        self.count += 1
        path.mkdir()
        (path / "name").write_text(name + "\n")
        for file in files:
            (path / file).write_text("128\n")
        return path

    def run_script(self):
        return subprocess.run(
            [str(SCRIPT)],
            env={
                "HWMON_ROOT": str(self.root),
                "FANS_FULL_WAIT": "1",
                "PATH": "/usr/bin:/bin",
            },
            capture_output=True,
            text=True,
        )

    def test_sets_every_commander_pro_fan_and_the_kraken_fan_but_not_its_pump(self):
        self.chip("nvme", "pwm1")
        cpro = self.chip("corsaircpro", "pwm1", "pwm2")
        kraken = self.chip("z53", "pwm1", "pwm2", "pwm1_enable", "pwm2_enable")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((cpro / "pwm1").read_text(), "255\n")
        self.assertEqual((cpro / "pwm2").read_text(), "255\n")
        self.assertEqual((kraken / "pwm2_enable").read_text(), "1\n")
        self.assertEqual((kraken / "pwm2").read_text(), "255\n")
        self.assertEqual((kraken / "pwm1").read_text(), "128\n")
        self.assertEqual((self.root / "hwmon0/pwm1").read_text(), "128\n")

    def test_a_missing_controller_fails_but_the_other_is_still_set(self):
        cpro = self.chip("corsaircpro", "pwm1")
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no NZXT Kraken found", result.stderr)
        self.assertEqual((cpro / "pwm1").read_text(), "255\n")


if __name__ == "__main__":
    unittest.main()
