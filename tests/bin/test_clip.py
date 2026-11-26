"""clip-send, clip-receive, and clip-menu against fake tailscale, wl-copy, and rofi."""

from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest
import zlib

REPO = Path(__file__).resolve().parents[2]
BIN = REPO / "home/dot_bin"


def png():
    """A valid 1x1 PNG, so `file` sees an image."""

    def chunk(kind, data):
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data))
        )

    header = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    pixels = zlib.compress(b"\x00\xf0\x8f\xb8")
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", pixels)
        + chunk(b"IEND", b"")
    )


PNG = png()


class ClipTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.home = self.tmp / "home"
        self.home.mkdir()
        self.bin = self.tmp / "bin"
        self.bin.mkdir()
        self.log = self.tmp / "log"
        self.log.write_text("")
        self.incoming = self.tmp / "incoming"
        self.incoming.mkdir()
        self.inbox = self.tmp / "inbox"
        system = self.tmp / "system"
        system.mkdir()
        for command in (
            "bash",
            "env",
            "cat",
            "awk",
            "mktemp",
            "rm",
            "mv",
            "mkdir",
            "basename",
            "file",
            "hostname",
            "date",
            "sleep",
            "cp",
            "chmod",
            "sh",
        ):
            (system / command).symlink_to(shutil.which(command))
        self.path = f"{self.bin}:{system}"
        # tailscale: `file cp` keeps what it was sent; `file get` moves the
        # files waiting in incoming/ into the target directory
        self.stub(
            "tailscale",
            f"""case "$1 $2" in
  "file cp")
    if [ "$3" = --targets ]; then
      printf '100.1.1.1\\tframework\\n100.1.1.2\\tthinkpad\\n'
    else cat > "{self.tmp}/sent"; fi ;;
  "file get") mv "{self.incoming}"/* "${{@: -1}}"/ 2> /dev/null; true ;;
esac""",
        )
        self.stub("wl-paste", "printf 'from the clipboard'")
        self.stub(
            "wl-copy",
            f'cat > "{self.tmp}/copied"\n'
            f'echo "display=$WAYLAND_DISPLAY" >> "{self.log}"',
        )
        self.stub("notify-send")
        # like rofi, read the choices before answering
        self.stub("rofi", "cat > /dev/null; echo thinkpad")
        self.stub("systemctl", "echo WAYLAND_DISPLAY=wayland-9")
        self.stub("xdg-user-dir", "exit 1")

    def stub(self, name, body=""):
        script = self.bin / name
        script.write_text(
            f'#!/usr/bin/env bash\necho "{name} $*" >> "{self.log}"\n{body}\n'
        )
        script.chmod(0o755)

    def run_script(self, script, *args, stdin=b""):
        env = {
            "PATH": self.path,
            "HOME": str(self.home),
            "CLIP_RECEIVE_INBOX": str(self.inbox),
        }
        return subprocess.run(
            [str(BIN / f"executable_{script}"), *args],
            env=env,
            input=stdin,
            capture_output=True,
        )

    def calls(self, name):
        return [c for c in self.log.read_text().splitlines() if c.startswith(name)]

    # clip-send

    def test_send_names_a_text_clip_and_sends_what_was_piped_in(self):
        result = self.run_script("clip-send", "framework", stdin=b"hello")
        self.assertEqual(result.returncode, 0, result.stderr)
        (cp,) = self.calls("tailscale file cp")
        self.assertRegex(cp, r"--name clipboard-\S+-\d{8}-\d{6}\.txt - framework:$")
        self.assertEqual((self.tmp / "sent").read_bytes(), b"hello")
        self.assertFalse(self.calls("rofi"))

    def test_send_names_an_image_clip_png(self):
        self.run_script("clip-send", "framework", stdin=PNG)
        self.assertRegex(self.calls("tailscale file cp")[0], r"\.png - framework:$")
        self.assertEqual((self.tmp / "sent").read_bytes(), PNG)

    def test_send_without_a_device_asks_which_one(self):
        self.run_script("clip-send", stdin=b"hello")
        self.assertTrue(self.calls("rofi"))
        (send,) = self.calls("tailscale file cp --name")
        self.assertTrue(send.endswith(" thinkpad:"), send)

    def test_send_refuses_an_empty_clip(self):
        result = self.run_script("clip-send", "framework", stdin=b"")
        self.assertEqual(result.returncode, 1)
        self.assertFalse(self.calls("tailscale file cp --name"))

    # clip-receive

    def test_receive_puts_a_clip_on_the_clipboard(self):
        (self.incoming / "clipboard-desktop-20261126-120000.txt").write_text("hi")
        result = self.run_script("clip-receive", "--once")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.tmp / "copied").read_text(), "hi")
        self.assertEqual(list(self.inbox.iterdir()), [])
        self.assertIn("display=wayland-9", self.log.read_text())
        self.assertIn("Clipboard from desktop", self.calls("notify-send")[0])

    def test_receive_waits_for_files_in_a_private_folder_on_disk(self):
        env = {"PATH": self.path, "HOME": str(self.home), "XDG_RUNTIME_DIR": "/run/x"}
        subprocess.run(
            [str(BIN / "executable_clip-receive"), "--once"], env=env, check=False
        )
        (get,) = self.calls("tailscale file get")
        inbox = self.home / ".cache/clip-receive"
        self.assertTrue(get.endswith(str(inbox)), get)
        self.assertEqual(inbox.stat().st_mode & 0o777, 0o700)

    def test_receive_moves_other_files_to_downloads_without_overwriting(self):
        downloads = self.home / "Downloads"
        downloads.mkdir()
        (downloads / "notes.txt").write_text("keep")
        (self.incoming / "notes.txt").write_text("new")
        self.run_script("clip-receive", "--once")
        self.assertEqual((downloads / "notes.txt").read_text(), "keep")
        self.assertEqual((downloads / "notes-1.txt").read_text(), "new")
        self.assertFalse(self.calls("wl-copy"))

    def test_receive_keeps_a_clip_it_cannot_copy(self):
        self.stub("wl-copy", "exit 1")
        (self.incoming / "clipboard-desktop-20261126-120000.txt").write_text("hi")
        self.run_script("clip-receive", "--once")
        kept = self.home / "Downloads/clipboard-desktop-20261126-120000.txt"
        self.assertEqual(kept.read_text(), "hi")

    # clip-menu

    def test_menu_enter_copies_and_alt_enter_sends(self):
        self.stub(
            "cliphist", 'case "$1" in list) echo "1\tsecret";; decode) cat;; esac'
        )
        self.stub("clip-send", f'cat > "{self.tmp}/sent-from-menu"')
        self.stub("rofi", 'echo "1\tsecret"')
        self.run_script("clip-menu")
        self.assertEqual((self.tmp / "copied").read_text(), "1\tsecret\n")
        self.stub("rofi", 'echo "1\tsecret"; exit 10')
        self.run_script("clip-menu")
        self.assertEqual((self.tmp / "sent-from-menu").read_text(), "1\tsecret\n")


if __name__ == "__main__":
    unittest.main()
