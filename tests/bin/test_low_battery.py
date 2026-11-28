"""home/dot_bin/executable_low-battery against a fake power supply tree."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_low-battery"


class LowBatteryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.root = self.tmp / "power_supply"
        self.root.mkdir()
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        notify = self.bin / "notify-send"
        notify.write_text(f'#!/usr/bin/env bash\necho "$*" >> "{self.log}"\n')
        notify.chmod(0o755)
        self.supply("AC", type="Mains")

    def supply(self, name, **files):
        path = self.root / name
        path.mkdir(exist_ok=True)
        for file, value in files.items():
            (path / file).write_text(f"{value}\n")

    def battery(self, capacity, status="Discharging"):
        self.supply("BAT0", type="Battery", capacity=capacity, status=status)

    def check(self):
        result = subprocess.run(
            [str(SCRIPT), "check"],
            env={
                "PATH": f"{self.bin}:/usr/bin:/bin",
                "POWER_SUPPLY_ROOT": str(self.root),
                "XDG_RUNTIME_DIR": str(self.tmp),
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_warns_once_at_15_then_urgently_once_at_5(self):
        self.battery(40)
        self.assertEqual(self.check(), [])
        self.battery(15)
        self.check()
        self.battery(12)
        self.check()
        self.battery(5)
        self.check()
        self.battery(3)
        calls = self.check()
        self.assertEqual(len(calls), 2)
        self.assertIn("Battery low: 15%", calls[0])
        self.assertTrue(calls[1].startswith("-u critical Battery at 5%"), calls[1])

    def test_charging_starts_the_warnings_over(self):
        self.battery(10)
        self.check()
        self.battery(10, status="Charging")
        self.check()
        self.battery(10)
        self.assertEqual(len(self.check()), 2)

    def test_two_batteries_are_averaged(self):
        self.battery(10)
        self.supply("BAT1", type="Battery", capacity=60, status="Discharging")
        self.assertEqual(self.check(), [])

    def test_a_wireless_devices_battery_is_ignored(self):
        self.battery(60)
        self.supply(
            "ps-controller-battery",
            type="Battery",
            scope="Device",
            capacity=3,
            status="Discharging",
        )
        self.assertEqual(self.check(), [])

    def test_only_device_batteries_count_as_no_battery(self):
        self.supply("hidpp_battery_0", type="Battery", scope="Device", capacity=2)
        result = subprocess.run(
            [str(SCRIPT), "check"],
            env={
                "PATH": f"{self.bin}:/usr/bin:/bin",
                "POWER_SUPPLY_ROOT": str(self.root),
                "XDG_RUNTIME_DIR": str(self.tmp),
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0)
        self.assertFalse(self.log.exists())

    def test_no_battery_exits_quietly(self):
        result = subprocess.run(
            [str(SCRIPT)],
            env={"PATH": "/usr/bin:/bin", "POWER_SUPPLY_ROOT": str(self.root)},
            capture_output=True,
            text=True,
            timeout=5,
        )
        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
