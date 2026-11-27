"""What chezmoi installs from home/: the KDE answer, ignored caches, and modes."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
CHEZMOI = shutil.which("chezmoi")
KDE_FILES = {
    ".config/kwinrulesrc",
    ".config/powerdevilrc",
    ".local/share/applications/org.kde.discover.desktop",
}


def chezmoi(tmp, source, kde, *args, machine="framework"):
    config = tmp / "chezmoi.toml"
    data = f"[data]\n  kde = {str(kde).lower()}\n"
    if machine is not None:
        data += f'  machine = "{machine}"\n'
    config.write_text(data)
    (tmp / "home").mkdir(exist_ok=True)
    command = [
        CHEZMOI,
        "--source",
        str(source),
        "--config",
        str(config),
        "--persistent-state",
        str(tmp / "state.boltdb"),
        "--cache",
        str(tmp / "cache"),
        "--destination",
        str(tmp / "home"),
        "--no-tty",
        *args,
    ]
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout


def managed(source, kde):
    with tempfile.TemporaryDirectory() as tmp:
        out = chezmoi(
            Path(tmp),
            source,
            kde,
            "managed",
            "--include",
            "files",
            "--path-style",
            "relative",
        )
    return set(out.split())


@unittest.skipUnless(CHEZMOI or os.environ.get("CI"), "chezmoi is not installed")
class SourceTest(unittest.TestCase):
    def test_kde_files_follow_the_kde_answer(self):
        with_kde = managed(REPO, True)
        without_kde = managed(REPO, False)
        self.assertLessEqual(KDE_FILES, with_kde)
        self.assertTrue(KDE_FILES.isdisjoint(without_kde))
        self.assertEqual(with_kde - KDE_FILES, without_kde)

    def test_caches_are_never_installed(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "repo"
            shutil.copytree(REPO / "home", source / "home")
            shutil.copy(REPO / ".chezmoiroot", source / ".chezmoiroot")
            cache = source / "home/dot_local/share/agent-awake/__pycache__"
            cache.mkdir()
            (cache / "agent_awake.cpython-313.pyc").write_bytes(b"")
            files = managed(source, True)
        self.assertFalse([f for f in files if "__pycache__" in f or f.endswith(".pyc")])
        self.assertIn(".local/share/agent-awake/agent_awake.py", files)

    def test_sway_reads_the_per_machine_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            chezmoi(tmp, REPO, False, "apply", "--force", "--exclude", "scripts")
            sway = tmp / "home/.config/sway"
            machine = (sway / "machine.conf").read_text()
            config = (sway / "config").read_text()
        self.assertIn("(framework)", machine)
        self.assertIn("output eDP-1", machine)
        self.assertIn("include ~/.config/sway/machine.conf", config)
        self.assertIn("include ~/.config/sway/session.conf", config)

    def test_every_machine_loads_the_session_setup_but_sway_nested_does_not(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            sway = tmp / "home/.config/sway"
            out = {}
            for machine in ("framework", "desktop"):
                for name in ("session.conf", "nested.conf", "machine.conf"):
                    out[machine, name] = chezmoi(
                        tmp, REPO, False, "cat", str(sway / name), machine=machine
                    )
        for machine in ("framework", "desktop"):
            self.assertIn("include /etc/sway/config.d/*", out[machine, "session.conf"])
            self.assertIn(
                "--autostart --environment sway", out[machine, "session.conf"]
            )
            nested = out[machine, "nested.conf"]
            self.assertNotIn("include ~/.config/sway/session.conf", nested)
            self.assertIn("include ~/.config/sway/machine.conf", nested)
            self.assertIn("set $mod Mod1", nested)
            self.assertNotIn("bindsym $mod+Mod1+space", nested)
            self.assertNotIn("sway-startup", nested)
            self.assertIn("exec sway-startup", out[machine, "session.conf"])
        self.assertNotIn("Mod1", out["desktop", "machine.conf"])
        self.assertIn("output DP-3", out["desktop", "machine.conf"])

    def test_ssh_config_gets_add_keys_to_agent_and_keeps_its_hosts(self):
        hosts = "Host example\n  User me\n"
        block = "Host *\n  AddKeysToAgent yes\n"
        cases = {
            None: block,
            hosts: hosts + "\n" + block,
            "Host example\n  User me": "Host example\n  User me\n\n" + block,
            hosts + "Host *\n  addkeystoagent no\n": None,
            hosts + "Host *\n  AddKeysToAgent=confirm\n": None,
            hosts + "Host *\n  AddKeysToAgent = yes\n": None,
        }
        for current, expected in cases.items():
            with self.subTest(current=current), tempfile.TemporaryDirectory() as tmp:
                tmp = Path(tmp)
                ssh = tmp / "home/.ssh"
                ssh.mkdir(parents=True)
                if current is not None:
                    (ssh / "config").write_text(current)
                target = str(ssh / "config")
                result = chezmoi(tmp, REPO, False, "cat", target)
                self.assertEqual(result, expected or current)
                # a second pass over the result changes nothing
                (ssh / "config").write_text(result)
                self.assertEqual(chezmoi(tmp, REPO, False, "cat", target), result)

    def test_swaylock_lets_every_machine_start_a_fingerprint_unlock(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            target = str(tmp / "home/.config/swaylock/config")
            for machine in ("framework", "desktop"):
                config = chezmoi(tmp, REPO, False, "cat", target, machine=machine)
                self.assertNotIn("ignore-empty-password", config.splitlines())

    def test_an_unknown_machine_stops_with_a_clear_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            target = str(tmp / "home/.config/sway/machine.conf")
            with self.assertRaises(subprocess.CalledProcessError) as raised:
                chezmoi(tmp, REPO, False, "cat", target, machine="fedora")
        self.assertIn('unknown machine "fedora"', raised.exception.stderr)

    def test_a_config_from_before_the_machine_question_says_to_rerun_init(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            target = str(tmp / "home/.config/sway/machine.conf")
            with self.assertRaises(subprocess.CalledProcessError) as raised:
                chezmoi(tmp, REPO, False, "cat", target, machine=None)
        self.assertIn("no machine chosen", raised.exception.stderr)

    def test_private_and_executable_modes_are_installed(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            chezmoi(tmp, REPO, True, "apply", "--force", "--exclude", "scripts")
            home = tmp / "home"

            def mode(path):
                return (home / path).stat().st_mode & 0o777

            self.assertEqual(mode(".codex/config.toml"), 0o600)
            self.assertEqual(mode(".config/fish"), 0o700)
            self.assertTrue(mode(".bin/copy") & 0o100)
            self.assertFalse(mode(".git_prompt") & 0o111)


if __name__ == "__main__":
    unittest.main()
