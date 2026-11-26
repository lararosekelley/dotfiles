"""home/dot_bin/executable_sway-startup against a fake swaymsg."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_sway-startup"

# Records each call. `exec -- kitty --class startup-NAME ...` adds a window with
# that app_id to the tree, unless NAME is listed in $NEVER; get_tree prints it.
SWAYMSG = """\
#!/usr/bin/env bash
echo "$*" >> "{log}"
case "$*" in
  "-q exec -- kitty --class startup-"*)
    id=$(sed -E 's/.*--class (startup-[a-z]+).*/\\1/' <<< "$*")
    case " $NEVER " in *" ${{id#startup-}} "*) ;; *) echo "$id" >> "{windows}" ;; esac
    ;;
  "-t get_tree")
    jq -R '{{app_id: .}}' "{windows}" | jq -s '{{nodes: .}}'
    ;;
esac
"""


class SwayStartupTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.windows = self.tmp / "windows"
        self.windows.write_text("")
        swaymsg = self.bin / "swaymsg"
        swaymsg.write_text(SWAYMSG.format(log=self.log, windows=self.windows))
        swaymsg.chmod(0o755)
        for program in ("callie", "fastfetch", "cliamp", "nvim"):
            self.install(program)
        system = self.tmp / "system"
        system.mkdir()
        for command in ("bash", "env", "jq", "sed", "seq", "sleep"):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"

    def install(self, program):
        stub = self.bin / program
        stub.write_text("#!/usr/bin/env bash\n")
        stub.chmod(0o755)

    def run_script(self, never=""):
        env = {"PATH": self.path, "NEVER": never, "SWAY_STARTUP_WAIT": "3"}
        return subprocess.run([str(SCRIPT)], env=env, capture_output=True, text=True)

    def calls(self):
        return [c for c in self.log.read_text().splitlines() if c != "-t get_tree"]

    def test_the_layout_is_built_in_order(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(),
            [
                "-q workspace number 1",
                "-q exec -- kitty --class startup-callie --hold callie tui",
                '-q [app_id="startup-callie"] focus, splith',
                "-q exec -- kitty --class startup-fastfetch --hold fastfetch",
                '-q [app_id="startup-fastfetch"] focus, splitv',
                "-q exec -- kitty --class startup-cliamp --hold cliamp",
                "-q workspace number 2",
                "-q exec -- kitty --class startup-nvim --hold nvim",
                "-q workspace number 1",
            ],
        )

    def test_a_missing_program_gets_a_plain_shell(self):
        (self.bin / "callie").unlink()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("-q exec -- kitty --class startup-callie --hold", self.calls())

    def test_a_window_that_never_appears_is_reported_and_the_rest_still_open(self):
        result = self.run_script(never="fastfetch")
        self.assertEqual(result.returncode, 1)
        self.assertIn("startup-fastfetch never appeared", result.stderr)
        calls = self.calls()
        self.assertNotIn('-q [app_id="startup-fastfetch"] focus, splitv', calls)
        self.assertIn("-q exec -- kitty --class startup-cliamp --hold cliamp", calls)
        self.assertIn("-q exec -- kitty --class startup-nvim --hold nvim", calls)
        self.assertEqual(calls[-1], "-q workspace number 1")


if __name__ == "__main__":
    unittest.main()
