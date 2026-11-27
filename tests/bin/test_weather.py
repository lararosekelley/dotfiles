"""home/dot_bin/executable_weather against a fake curl."""

from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_weather"

# the parts of wttr.in's ?format=j1 reply the script reads
REPLY = {
    "current_condition": [
        {
            "temp_F": "54",
            "FeelsLikeF": "50",
            "humidity": "72",
            "windspeedMiles": "12",
            "winddir16Point": "SW",
            "weatherCode": "122",
            "weatherDesc": [{"value": "Overcast "}],
        }
    ],
    "weather": [
        {
            "date": "2026-11-27",
            "maxtempF": "57",
            "mintempF": "45",
            "astronomy": [{"sunrise": "07:01 AM", "sunset": "04:40 PM"}],
            "hourly": [{}] * 4 + [{"weatherDesc": [{"value": "Rain & sleet"}]}],
        },
        {
            "date": "2026-11-28",
            "maxtempF": "48",
            "mintempF": "44",
            "hourly": [{}] * 4 + [{"weatherDesc": [{"value": "Cloudy"}]}],
        },
        {
            "date": "2026-11-29",
            "maxtempF": "52",
            "mintempF": "39",
            "hourly": [{}] * 4 + [{"weatherDesc": [{"value": "Sunny"}]}],
        },
    ],
}


class WeatherTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.home = self.tmp / "home"
        self.home.mkdir()
        self.cache = self.tmp / "cache"
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        (self.tmp / "reply.json").write_text(json.dumps(REPLY))
        self.online()

    def online(self):
        # record the URL, then write the reply to curl's -o file
        self.curl(f"""echo "$@" >> "{self.tmp}/urls"
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
cp "{self.tmp}/reply.json" "$out\"""")

    def offline(self):
        self.curl(f'echo "$@" >> "{self.tmp}/urls"; exit 6')

    def curl(self, body):
        script = self.bin / "curl"
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def status(self, location=None):
        env = {
            "HOME": str(self.home),
            "XDG_CACHE_HOME": str(self.cache),
            "PATH": f"{self.bin}:/usr/bin:/bin",
        }
        if location is not None:
            env["WEATHER_LOCATION"] = location
        result = subprocess.run(
            [str(SCRIPT)], env=env, capture_output=True, text=True, check=True
        )
        return json.loads(result.stdout)

    def urls(self):
        path = self.tmp / "urls"
        return path.read_text().splitlines() if path.exists() else []

    def age_cache(self, seconds):
        old = time.time() - seconds
        os.utime(self.cache / "weather.json", (old, old))

    def test_shows_the_temperature_with_the_forecast_on_hover(self):
        status = self.status("New York")
        self.assertTrue(status["text"].endswith(" 54°"), status["text"])
        tooltip = status["tooltip"].splitlines()
        self.assertEqual(tooltip[0], "overcast, 54°F, feels like 50°F")
        self.assertEqual(tooltip[1], "humidity 72%, wind 12 mph SW")
        self.assertEqual(tooltip[3], "Today: high 57°, low 45°, rain &amp; sleet")
        self.assertEqual(tooltip[4], "Tomorrow: high 48°, low 44°, cloudy")
        self.assertEqual(tooltip[5], "Sunday: high 52°, low 39°, sunny")
        self.assertIn("https://wttr.in/New%20York?format=j1", self.urls()[0])

    def test_the_location_can_come_from_environment_file(self):
        (self.home / ".environment").write_text(
            "OTHER=1\nWEATHER_LOCATION='10001'\nMORE=2\n"
        )
        self.status()
        self.assertIn("https://wttr.in/10001?format=j1", self.urls()[0])

    def test_without_a_location_wttr_in_guesses(self):
        self.status()
        self.assertIn("https://wttr.in/?format=j1", self.urls()[0])

    def test_a_fresh_reading_is_reused_without_asking_again(self):
        self.status("x")
        self.status("x")
        self.assertEqual(len(self.urls()), 1)

    def test_a_stale_reading_is_shown_while_offline(self):
        self.status("x")
        self.age_cache(3600)
        self.offline()
        self.assertTrue(self.status("x")["text"].endswith(" 54°"))
        self.assertEqual(len(self.urls()), 2)

    def test_it_hides_with_nothing_recent(self):
        self.offline()
        self.assertEqual(self.status("x")["text"], "")
        self.online()
        self.status("x")
        self.age_cache(4 * 3600)
        self.offline()
        self.assertEqual(self.status("x")["text"], "")


if __name__ == "__main__":
    unittest.main()
