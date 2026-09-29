# Desktop preferences

## Managed settings

- `content/.config/powerdevilrc`: suspend after 600 seconds idle on AC power and
  block Zen's video-playback sleep inhibition.
- `content/.config/kwinrulesrc`: the Emacs window-position rule. Its class match
  names the Emacs PGTK version, so check it after changing Emacs builds.

Sync replaces these files in full. Review home changes before accepting an update,
especially after adding window rules or changing power profiles. KDE may rewrite
them while running; log out and back in after restoring desktop configuration.

## Private machine-specific settings

Keep these files local rather than replacing hardware matches with broad wildcards:

- `~/.config/kwinrc`: night color at 3000 K, XWayland scaling at 1.25, and
  quarter/half/quarter tiling layouts. Tiling sections are keyed by desktop and
  monitor IDs; configure layouts for the actual monitors in System Settings.
- `~/.config/wireplumber/wireplumber.conf.d/00-plasma-pa.conf`: audio-device
  labels and Scarlett output tuning. The Scarlett output rule sets ALSA headroom
  and period size to 512, period count to 64, and maximum node latency to
  `16384/48000`. Device matches include a webcam serial and Bluetooth address.
  Back up the exact file privately; recreate labels and test audio tuning against
  the actual devices on a new machine.

These values describe preferences, not portable device identities. Do not copy
monitor IDs or device addresses from a different machine.
