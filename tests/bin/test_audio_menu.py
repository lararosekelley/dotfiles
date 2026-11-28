"""home/dot_bin/executable_audio-menu against a fake pactl and rofi."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_audio-menu"

SINKS = [
    {
        "name": "card.analog",
        "description": "Ryzen HD Audio Controller Analog Stereo",
        "properties": {"device.class": "sound", "device.bus": "pci"},
        "ports": [
            {
                "name": "analog-output-speaker",
                "description": "Speakers",
                "availability": "availability unknown",
            },
            {
                "name": "analog-output-headphones",
                "description": "Headphones",
                "availability": "available",
            },
        ],
        "active_port": "analog-output-speaker",
    },
    {
        "name": "bluez_output.buds",
        "description": "Pink Buds",
        "properties": {"device.class": "sound", "device.bus": "bluetooth"},
        "ports": [],
        "active_port": None,
    },
]
SOURCES = [
    {
        "name": "card.analog.monitor",
        "description": "Monitor of Ryzen HD Audio Controller Analog Stereo",
        "properties": {"device.class": "monitor"},
        "ports": [],
    },
    {
        "name": "card.mic",
        "description": "Ryzen HD Audio Controller Analog Stereo",
        "properties": {"device.class": "sound", "device.bus": "pci"},
        "ports": [
            {
                "name": "analog-input-internal-mic",
                "description": "Internal Microphone",
                "availability": "availability unknown",
            },
            {
                "name": "analog-input-headset-mic",
                "description": "Headset Microphone",
                "availability": "not available",
            },
        ],
        "active_port": "analog-input-internal-mic",
    },
]


class AudioMenuTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        (self.tmp / "sinks.json").write_text(json.dumps(SINKS))
        (self.tmp / "sources.json").write_text(json.dumps(SOURCES))
        self.stub(
            "pactl",
            f"""case "$*" in
  "-f json list sinks") cat "{self.tmp}/sinks.json" ;;
  "-f json list sources") cat "{self.tmp}/sources.json" ;;
  get-default-sink) echo card.analog ;;
  get-default-source) echo card.mic ;;
  *) echo "pactl $*" >> "{self.log}" ;;
esac""",
        )
        self.stub("setsid", f'echo "setsid $*" >> "{self.log}"')
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "jq", "cat"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def choose(self, row):
        """Run the menu, with rofi answering with row (an index) or cancelling."""
        answer = "exit 1" if row is None else f"echo {row}"
        self.stub("rofi", f'cat > "{self.tmp}/shown"\n{answer}')
        result = subprocess.run(
            [str(SCRIPT)], env={"PATH": self.path}, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.log.read_text().splitlines()

    def shown(self):
        return (self.tmp / "shown").read_text().splitlines()

    def test_rows_are_ports_or_devices_with_the_ones_in_use_marked(self):
        self.choose(None)
        self.assertEqual(
            self.shown(),
            [
                "󰓃  Speakers  (in use)",
                "󰋋  Headphones",
                "󰂯  Pink Buds",
                "󰍬  Internal Microphone  (in use)",
            ],
        )

    def test_a_port_becomes_the_default_device_and_port(self):
        self.assertEqual(
            self.choose(1),
            [
                "pactl set-default-sink card.analog",
                "pactl set-sink-port card.analog analog-output-headphones",
            ],
        )

    def test_a_device_without_ports_only_becomes_the_default(self):
        self.assertEqual(self.choose(2), ["pactl set-default-sink bluez_output.buds"])

    def test_an_input_becomes_the_default_source(self):
        self.assertEqual(
            self.choose(3),
            [
                "pactl set-default-source card.mic",
                "pactl set-source-port card.mic analog-input-internal-mic",
            ],
        )

    def test_the_mixer_row_appears_where_pavucontrol_is_installed(self):
        self.stub("pavucontrol", "exit 0")
        self.assertEqual(self.choose(4), ["setsid -f pavucontrol"])
        self.assertEqual(self.shown()[-1], "󰕾  open the mixer")

    def test_cancelling_changes_nothing(self):
        self.assertEqual(self.choose(None), [])


if __name__ == "__main__":
    unittest.main()
