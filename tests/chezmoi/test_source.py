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


def chezmoi(tmp, source, kde, *args):
    config = tmp / "chezmoi.toml"
    config.write_text(f"[data]\n  kde = {str(kde).lower()}\n")
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
