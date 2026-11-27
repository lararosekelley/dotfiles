"""home/dot_bin/executable_bluetooth-menu against a fake bluetoothctl and rofi."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_bluetooth-menu"

EARBUDS = "AA:AA:AA:AA:AA:01"
PAD = "AA:AA:AA:AA:AA:02"
SPEAKER = "AA:AA:AA:AA:AA:03"


class BluetoothMenuTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.answers = self.tmp / "answers"
        (self.tmp / "powered").write_text("yes\n")
        info = self.tmp / "info"
        info.mkdir()
        (info / EARBUDS).write_text(
            "\tIcon: audio-headset\n\tConnected: yes\n"
            "\tBattery Percentage: 0x50 (80)\n"
        )
        (info / PAD).write_text("\tIcon: input-gaming\n\tConnected: no\n")
        # bluetoothctl: show, devices, and info come from files; the rest is
        # logged, and "scan on" makes the speaker appear
        self.stub(
            "bluetoothctl",
            f"""case "$*" in
  show) echo "Controller 00:00 (public)"; echo "Powered: $(cat "{self.tmp}/powered")" ;;
  "devices Paired") printf 'Device {PAD} Pad\\nDevice {EARBUDS} Earbuds\\n' ;;
  devices)
    printf 'Device {PAD} Pad\\nDevice {EARBUDS} Earbuds\\n'
    printf 'Device {SPEAKER} Speaker\\nDevice BB:BB:BB:BB:BB:BB BB-BB-BB-BB-BB-BB\\n' ;;
  "info "*) cat "{info}/$2" ;;
  *) echo "bluetoothctl $*" >> "{self.log}" ;;
esac""",
        )
        self.stub(
            "rofi",
            f"""cat >> "{self.tmp}/shown"
echo "rofi $*" >> "{self.log}"
answer=$(head -n 1 "{self.answers}")
sed -i 1d "{self.answers}"
[ -n "$answer" ] || exit 1
code=0
case "$answer" in alt:*) answer=${{answer#alt:}}; code=10 ;; esac
echo "$answer"
exit $code""",
        )
        self.stub("notify-send", f'echo "notify-send $*" >> "{self.log}"')
        self.stub("kitty", f'echo "kitty $*" >> "{self.log}"')

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def run_menu(self, *answers, args=()):
        self.answers.write_text("".join(f"{a}\n" for a in answers))
        self.log.write_text("")
        (self.tmp / "shown").write_text("")
        result = subprocess.run(
            [str(SCRIPT), *args],
            env={"PATH": f"{self.bin}:/usr/bin:/bin"},
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.log.read_text()

    def rows(self):
        lines = (self.tmp / "shown").read_text().splitlines()
        return [line.split("  ", 1)[1] for line in lines]

    def test_lists_connected_devices_first_with_their_battery(self):
        self.run_menu()
        self.assertEqual(
            self.rows(),
            [
                "Earbuds  (connected, 80%)",
                "Pad",
                "pair a new device",
                "turn Bluetooth off",
                "open bluetoothctl",
            ],
        )

    def test_enter_connects_a_device_or_disconnects_a_connected_one(self):
        self.assertIn(f"bluetoothctl connect {PAD}", self.run_menu("1"))
        self.assertIn(f"bluetoothctl disconnect {EARBUDS}", self.run_menu("0"))

    def test_alt_enter_forgets_a_device_after_asking(self):
        self.assertIn(f"bluetoothctl remove {PAD}", self.run_menu("alt:1", "yes"))
        self.assertNotIn("remove", self.run_menu("alt:1", "no"))

    def test_the_actions_after_the_devices(self):
        self.assertIn("bluetoothctl power off", self.run_menu("3"))
        self.assertIn("kitty --class bluetoothctl bluetoothctl", self.run_menu("4"))

    def test_pairing_offers_only_new_named_devices(self):
        log = self.run_menu("0", args=["pair"])
        self.assertIn("bluetoothctl --timeout 10 scan on", log)
        self.assertEqual(self.rows(), ["Speaker"])
        for step in ("pair", "trust", "connect"):
            self.assertIn(f"bluetoothctl {step} {SPEAKER}", log)
        self.assertIn("Paired Speaker", log)

    def test_with_bluetooth_off_it_offers_to_turn_it_on(self):
        (self.tmp / "powered").write_text("no\n")
        log = self.run_menu("0")
        self.assertIn("bluetoothctl power on", log)
        self.assertNotIn("connect", log)


if __name__ == "__main__":
    unittest.main()
