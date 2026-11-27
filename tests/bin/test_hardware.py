"""home/dot_bin/executable_hardware against fake hwmon trees."""

from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_hardware"


class HardwareTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        self.count = 0

    def chip(self, name, model=None, **files):
        """A hwmon chip directory; files maps names like temp1_input to values,
        and a model becomes the device's model file."""
        path = self.root / f"hwmon{self.count}"
        self.count += 1
        path.mkdir()
        (path / "name").write_text(name + "\n")
        for file, value in files.items():
            (path / file).write_text(f"{value}\n")
        if model:
            (path / "device").mkdir()
            (path / "device/model").write_text(model + "   \n")

    def status(self):
        result = subprocess.run(
            [str(SCRIPT)],
            env={"HWMON_ROOT": str(self.root), "PATH": "/usr/bin:/bin"},
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)

    def desktop(self, cpu=56000, junction=39000):
        # in a different order from the tooltip's, as hwmon numbers may be
        self.chip(
            "nvme",
            model="Samsung SSD 980 PRO 2TB",
            temp1_input=36000,
            temp1_label="Composite",
            temp2_input=51000,
            temp2_label="Sensor 2",
        )
        self.chip(
            "amdgpu",
            temp1_input=32000,
            temp1_label="edge",
            temp2_input=junction,
            temp2_label="junction",
            temp3_input=36000,
            temp3_label="mem",
            fan1_input=0,
            power1_average=14000000,
            power1_label="PPT",
        )
        self.chip(
            "k10temp",
            temp1_input=cpu,
            temp1_label="Tctl",
            temp3_input=60000,
            temp3_label="Tccd1",
        )
        self.chip("nzxtsmart2", fan1_input=0, fan2_input=0)
        self.chip(
            "z53",
            temp1_input=37000,
            temp1_label="Coolant temp",
            fan1_input=1376,
            fan1_label="Pump speed",
            fan2_input=726,
            fan2_label="Fan speed",
        )
        self.chip(
            "nct6687",
            fan1_input=1365,
            fan2_input=0,
            temp1_input=81000,
            temp1_label="AMD TSI Addr 98h",
        )
        self.chip("drivetemp", model="ST8000VN004-2M21", temp1_input=26000)
        self.chip("r8169_0_2a00:00", temp1_input=38500)

    def test_the_bar_shows_cpu_and_gpu_and_the_tooltip_everything_else(self):
        self.desktop()
        status = self.status()
        self.assertEqual(status["text"], "\U000f0ee0 56°  \U000f08ae 39°")
        self.assertEqual(status["class"], "normal")
        lines = status["tooltip"].removeprefix("<tt>").removesuffix("</tt>")
        rows = [" ".join(line.split()) for line in lines.split("\n")]
        self.assertEqual(
            rows,
            [
                "CPU 56°C (CCD1 60°C)",
                "",
                "GPU 39°C (edge 32°C, memory 36°C)",
                "GPU fan stopped (idle)",
                "GPU power 14 W",
                "",
                "Coolant 37°C",
                "Pump 1376 rpm",
                "Radiator fans 726 rpm",
                "Board fans 1365 rpm",
                "",
                "Samsung SSD 980 PRO 2TB 36°C",
                "ST8000VN004-2M21 26°C",
            ],
        )

    def test_a_warm_cpu_or_hot_gpu_colors_the_pill(self):
        self.desktop(cpu=86000)
        self.assertEqual(self.status()["class"], "warm")
        shutil.rmtree(self.root)
        self.root.mkdir()
        self.count = 0
        self.desktop(junction=106000)
        self.assertEqual(self.status()["class"], "hot")

    def test_a_laptop_shows_its_cpu_and_fan_and_no_integrated_gpu(self):
        self.chip("coretemp", temp1_input=48000, temp1_label="Package id 0")
        self.chip("amdgpu", temp1_input=45000, temp1_label="edge")
        self.chip("thinkpad", fan1_input=2400)
        status = self.status()
        self.assertEqual(status["text"], "\U000f0ee0 48°")
        self.assertIn("Fan  2400 rpm", status["tooltip"])
        self.assertNotIn("GPU", status["tooltip"])

    def test_no_sensors_shows_nothing(self):
        self.assertEqual(self.status()["text"], "")

    def test_drive_names_are_escaped_for_the_tooltip(self):
        self.chip("drivetemp", model="R&D <disk>", temp1_input=30000)
        self.assertIn("R&amp;D &lt;disk&gt;", self.status()["tooltip"])


if __name__ == "__main__":
    unittest.main()
