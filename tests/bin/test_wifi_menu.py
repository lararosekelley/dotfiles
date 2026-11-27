"""home/dot_bin/executable_wifi-menu against a fake nmcli and rofi."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_wifi-menu"

# nmcli -t output: in use, signal, security, then the name with colons escaped
NETWORKS = """\
 :40:WPA2:Cafe
 :90:WPA2:Home
*:60:WPA2:Home
 :70::Open Net
 :80:WPA2:Lab\\:5G
 :20:WPA2:
"""


class WifiMenuTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.answers = self.tmp / "answers"
        (self.tmp / "networks").write_text(NETWORKS)
        (self.tmp / "radio").write_text("enabled\n")
        (self.tmp / "saved").write_text("uuid-cafe:802-11-wireless\n")
        # nmcli: the device, network, and saved connection lists come from
        # files; uuid-cafe is Cafe's saved connection and uuid-lab Lab:5G's; a
        # passwd-file's contents are kept; "fail" makes activation fail; every
        # call is logged
        self.stub(
            "nmcli",
            f"""echo "nmcli $*" >> "{self.log}"
case "$*" in
  "-t -f TYPE device") printf 'ethernet\\nwifi\\n' ;;
  "radio wifi") cat "{self.tmp}/radio" ;;
  "-t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no")
    cat "{self.tmp}/networks" ;;
  "-t -f UUID,TYPE connection show")
    echo uuid-wired:802-3-ethernet; cat "{self.tmp}/saved" ;;
  "-g 802-11-wireless.ssid connection show uuid uuid-cafe") echo Cafe ;;
  "-g 802-11-wireless.ssid connection show uuid uuid-lab") echo 'Lab\\:5G' ;;
  "connection up uuid "*" passwd-file "*)
    cat "${{@: -1}}" > "{self.tmp}/passwd"
    [ ! -e "{self.tmp}/fail" ] || {{ echo "Secrets were required"; exit 4; }} ;;
  "-t -f DEVICE,TYPE,STATE device") echo wlo1:wifi:connected ;;
esac""",
        )
        # rofi: keep what's shown, then answer with the next queued line, or
        # cancel when none is left
        self.stub(
            "rofi",
            f"""cat >> "{self.tmp}/shown"
echo "rofi $*" >> "{self.log}"
answer=$(head -n 1 "{self.answers}")
sed -i 1d "{self.answers}"
[ -n "$answer" ] || exit 1
echo "$answer\"""",
        )
        self.stub("notify-send", f'echo "notify-send $*" >> "{self.log}"')
        self.stub("sleep", "")
        self.stub("nm-connection-editor", f'echo "settings" >> "{self.log}"')

    def stub(self, name, body):
        script = self.bin / name
        script.write_text(f"#!/usr/bin/env bash\n{body}\n")
        script.chmod(0o755)

    def run_menu(self, *answers):
        self.answers.write_text("".join(f"{a}\n" for a in answers))
        self.log.write_text("")
        (self.tmp / "shown").write_text("")
        result = subprocess.run(
            [str(SCRIPT)],
            env={"PATH": f"{self.bin}:/usr/bin:/bin"},
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.log.read_text()

    def rows(self):
        shown = (self.tmp / "shown").read_text().splitlines()
        return [row.split("  ", 1)[1] for row in shown]

    def test_lists_the_connected_network_first_then_by_signal_once_each(self):
        self.run_menu()
        self.assertEqual(
            self.rows(),
            [
                "Home  \U000f033e  (connected: Enter disconnects)",
                "Lab:5G  \U000f033e",
                "Open Net",
                "Cafe  \U000f033e",
                "rescan",
                "turn Wi-Fi off",
                "network settings",
            ],
        )

    def test_a_saved_network_connects_with_its_own_password(self):
        log = self.run_menu("3")
        self.assertIn("nmcli connection up uuid uuid-cafe", log)
        self.assertNotIn("-password", log)
        self.assertIn("notify-send -t 5000 Connected Cafe", log)

    def test_a_saved_network_with_a_colon_in_its_name_is_found(self):
        (self.tmp / "saved").write_text("uuid-lab:802-11-wireless\n")
        log = self.run_menu("1")
        self.assertIn("nmcli connection up uuid uuid-lab", log)
        self.assertNotIn("-password", log)

    def test_a_new_secured_network_gets_its_password_through_a_pipe(self):
        log = self.run_menu("1", "hunter2")
        self.assertIn("rofi -dmenu -password -l 0 -p password for Lab:5G", log)
        self.assertRegex(
            log,
            r"nmcli connection add type wifi con-name Lab:5G ssid Lab:5G "
            r"connection.uuid \S+ wifi-sec.key-mgmt wpa-psk",
        )
        self.assertNotIn("hunter2", log)
        self.assertEqual(
            (self.tmp / "passwd").read_text(),
            "802-11-wireless-security.psk:hunter2\n",
        )
        self.assertIn("Connected Lab:5G", log)

    def test_a_failed_connection_removes_the_new_profile(self):
        (self.tmp / "fail").write_text("")
        log = self.run_menu("1", "wrong")
        self.assertRegex(log, r"nmcli connection delete uuid \S+")
        self.assertIn("Couldn't connect to Lab:5G", log)

    def test_cancelling_the_password_connects_nothing(self):
        log = self.run_menu("1")
        self.assertNotIn("connection add", log)
        self.assertNotIn("wifi connect", log)

    def test_an_enterprise_network_opens_the_settings(self):
        (self.tmp / "networks").write_text(" :80:WPA2 802.1X:Work\n")
        log = self.run_menu("0")
        self.assertIn("settings", log)
        self.assertNotIn("connection add", log)

    def test_with_no_networks_the_actions_keep_their_places(self):
        (self.tmp / "networks").write_text("")
        log = self.run_menu("0")
        self.assertIn("nmcli device wifi rescan", log)
        self.assertNotIn("radio wifi off", log)
        self.assertEqual(self.rows()[0], "rescan")

    def test_an_open_network_connects_without_a_password(self):
        log = self.run_menu("2")
        self.assertIn("nmcli device wifi connect Open Net", log)
        self.assertNotIn("-password", log)

    def test_the_connected_network_disconnects(self):
        log = self.run_menu("0")
        self.assertIn("nmcli device disconnect wlo1", log)

    def test_the_actions_after_the_networks(self):
        self.assertIn("nmcli radio wifi off", self.run_menu("5"))
        self.assertIn("settings", self.run_menu("6"))
        log = self.run_menu("4")
        self.assertIn("nmcli device wifi rescan", log)
        # it reopens the menu after rescanning
        self.assertEqual(log.count("device wifi list"), 2)

    def test_with_wifi_off_it_offers_to_turn_it_on(self):
        (self.tmp / "radio").write_text("disabled\n")
        log = self.run_menu("0")
        self.assertIn("nmcli radio wifi on", log)
        self.assertNotIn("device wifi list", log)

    def test_a_machine_without_wifi_says_so(self):
        self.stub(
            "nmcli",
            f'echo "nmcli $*" >> "{self.log}"; echo ethernet',
        )
        log = self.run_menu()
        self.assertIn("No Wi-Fi", log)
        self.assertNotIn("rofi", log)


if __name__ == "__main__":
    unittest.main()
