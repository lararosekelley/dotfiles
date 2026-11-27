"""home/dot_bin/executable_dotfiles-doctor, and the manual-steps.toml it reads."""

from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_bin/executable_dotfiles-doctor"
MACHINES = {"desktop", "framework", "thinkpad"}
DISTROS = {"fedora", "arch"}
FIELDS = {"id", "title", "needed_for", "docs"}
OPTIONAL = {"machines", "distro", "when", "check", "fix"}

STEPS = """
[[step]]
id = "everywhere-done"
title = "Done everywhere"
needed_for = "nothing"
docs = "docs/a.md"
check = "true"

[[step]]
id = "everywhere-todo"
title = "Left to do"
needed_for = "the test"
docs = "docs/a.md#b"
check = "[ -f marker ]"
fix = "touch marker on $MACHINE"

[[step]]
id = "unchecked"
title = "Check by eye"
needed_for = "looks"
docs = "docs/a.md"

[[step]]
id = "laptops"
title = "Laptop only"
needed_for = "laptops"
docs = "docs/a.md"
machines = ["framework", "thinkpad"]
check = "false"

[[step]]
id = "arch"
title = "Arch only"
needed_for = "arch"
docs = "docs/a.md"
distro = "arch"
check = "false"

[[step]]
id = "no-hardware"
title = "Needs hardware"
needed_for = "hardware"
docs = "docs/a.md"
when = "false"
check = "false"
"""


class DoctorTest(unittest.TestCase):
    def setUp(self):
        self.repo = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.repo)
        (self.repo / "manual-steps.toml").write_text(STEPS)

    def doctor(self, *args):
        return subprocess.run(
            [str(SCRIPT), "--machine", "desktop", "--distro", "fedora", *args],
            env={"DOTFILES_REPO": str(self.repo), "PATH": "/usr/bin:/bin"},
            capture_output=True,
            text=True,
        )

    def test_lists_what_is_left_and_what_to_confirm(self):
        result = self.doctor()
        self.assertEqual(result.returncode, 1, result.stderr)
        out = result.stdout
        self.assertIn("[todo] Left to do", out)
        self.assertIn("fix: touch marker on desktop", out)
        self.assertIn("docs: docs/a.md#b", out)
        self.assertIn("[ ?? ] Check by eye", out)
        for hidden in ("Done everywhere", "Laptop only", "Arch only", "hardware"):
            self.assertNotIn(hidden, out)
        self.assertIn(
            "1 to do, 1 to confirm yourself, 1 done, 3 not for this machine", out
        )

    def test_checks_run_from_the_repo_and_pass_once_done(self):
        (self.repo / "marker").write_text("")
        result = self.doctor()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("Left to do", result.stdout)

    def test_all_shows_every_step(self):
        out = self.doctor("--all").stdout
        self.assertIn("[ ok ] Done everywhere", out)
        self.assertIn("[ -- ] Laptop only", out)
        self.assertIn("[ -- ] Arch only", out)
        self.assertIn("[skip] Needs hardware", out)

    def test_machine_and_distro_pick_their_steps(self):
        out = subprocess.run(
            [str(SCRIPT), "--machine", "framework", "--distro", "arch"],
            env={"DOTFILES_REPO": str(self.repo), "PATH": "/usr/bin:/bin"},
            capture_output=True,
            text=True,
        ).stdout
        self.assertIn("[todo] Laptop only", out)
        self.assertIn("[todo] Arch only", out)


def anchors(markdown):
    """GitHub's anchors for a Markdown file's headings."""
    found = set()
    for line in markdown.splitlines():
        heading = re.match(r"#+\s+(.*)", line)
        if heading:
            text = heading.group(1).strip().lower()
            found.add(re.sub(r"[^\w\- ]", "", text).replace(" ", "-"))
    return found


class ManualStepsTest(unittest.TestCase):
    def setUp(self):
        self.steps = tomllib.loads((REPO / "manual-steps.toml").read_text())["step"]

    def test_each_step_has_its_fields_and_a_unique_id(self):
        ids = [step.get("id") for step in self.steps]
        self.assertEqual(len(ids), len(set(ids)))
        for step in self.steps:
            with self.subTest(step=step.get("id")):
                self.assertLessEqual(FIELDS, set(step))
                self.assertLessEqual(set(step), FIELDS | OPTIONAL)
                self.assertLessEqual(set(step.get("machines", [])), MACHINES)
                self.assertIn(step.get("distro", "fedora"), DISTROS)

    def test_each_docs_link_reaches_a_heading(self):
        for step in self.steps:
            with self.subTest(step=step["id"]):
                path, _, anchor = step["docs"].partition("#")
                doc = REPO / path
                self.assertTrue(doc.is_file(), path)
                if anchor:
                    self.assertIn(anchor, anchors(doc.read_text()))

    def test_each_command_is_valid_bash(self):
        for step in self.steps:
            for field in ("when", "check", "fix"):
                if field in step:
                    with self.subTest(step=step["id"], field=field):
                        result = subprocess.run(
                            ["bash", "-n", "-c", step[field]], capture_output=True
                        )
                        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
