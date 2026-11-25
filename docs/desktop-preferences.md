# Desktop preferences

## Managed settings

- `~/.config/powerdevilrc`: suspend after 600 seconds idle on AC power and
  block Zen's video-playback sleep inhibition.
- `~/.config/kwinrulesrc`: the Emacs window-position rule. Its class match
  names the Emacs PGTK version, so check it after changing Emacs builds.

Sync replaces these files in full. Review home changes before accepting an update,
especially after adding window rules or changing power profiles. KDE may rewrite
them while running; log out and back in after restoring desktop configuration.

## Theme, widgets, and panels

`scripts/install-kde.py` sets up the Plasma desktop on another machine from
`scripts/kde/`:

- `settings.json`: packages, the global theme, color scheme and accent, icon
  theme, third-party widgets pinned to upstream tags, and individual config keys.
  Keys are written one at a time with `kwriteconfig6`, so the rest of each file
  stays as it is.
- `layout.json`: panels and their widgets, without desktop icon positions,
  wallpaper, screen indexes, dialog sizes, or the weather location.

```bash
python3 scripts/install-kde.py apply --dry-run   # preview
python3 scripts/install-kde.py apply             # theme, widgets, settings
python3 scripts/install-kde.py apply --layout    # also replace every panel
python3 scripts/install-kde.py capture --dry-run # diff this machine's panels
python3 scripts/install-kde.py capture           # save this machine's panels
```

With `just`, `just kde-apply [--dry-run] [--layout]` and
`just kde-capture [--dry-run]` run the same commands.

`apply` prints a `dnf install` command for missing packages instead of running
it. Icon packs and widgets come from packages or upstream, not this repo. Set
the wallpaper and the weather location by hand.

## Private machine-specific settings

Keep these files local rather than replacing hardware matches with broad wildcards:

- `~/.config/kwinrc`: XWayland scaling at 1.25 and quarter/half/quarter tiling
  layouts. The KDE installer sets only its night color keys. Tiling sections are keyed by desktop and
  monitor IDs; configure layouts for the actual monitors in System Settings.
- `~/.config/wireplumber/wireplumber.conf.d/00-plasma-pa.conf`: audio-device
  labels and Scarlett output tuning. The Scarlett output rule sets ALSA headroom
  and period size to 512, period count to 64, and maximum node latency to
  `16384/48000`. Device matches include a webcam serial and Bluetooth address.
  Back up the exact file privately; recreate labels and test audio tuning against
  the actual devices on a new machine.

These values describe preferences, not portable device identities. Do not copy
monitor IDs or device addresses from a different machine.
