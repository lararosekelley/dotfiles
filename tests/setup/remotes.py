"""Local stand-ins for GitHub repos, for testing the setup scripts offline."""

import os
from pathlib import Path
import subprocess


def git(*args, cwd=None):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


def make_remote(remotes, name, files=None):
    """Create remotes/<owner>/<repo> as a repo with one commit."""
    path = Path(remotes) / name
    path.mkdir(parents=True)
    git("init", "-q", "-b", "main", cwd=path)
    for relative, (text, executable) in (files or {"README": (name, False)}).items():
        file = path / relative
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(text)
        if executable:
            file.chmod(0o755)
    git("add", ".", cwd=path)
    git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "init", cwd=path)
    return path


def environment(home, remotes):
    """An environment where every https://github.com/ clone comes from remotes."""
    return {
        "PATH": os.environ["PATH"],
        "HOME": str(home),
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_GLOBAL": "/dev/null",
        "GIT_CONFIG_COUNT": "1",
        "GIT_CONFIG_KEY_0": f"url.file://{remotes}/.insteadOf",
        "GIT_CONFIG_VALUE_0": "https://github.com/",
    }


def config(env, path, key):
    """A git config value of the checkout at path, or "" if unset."""
    return subprocess.run(
        ["git", "-C", str(path), "config", "--get", key],
        env=env,
        capture_output=True,
        text=True,
    ).stdout.strip()
