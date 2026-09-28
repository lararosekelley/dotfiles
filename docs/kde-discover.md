# Discover (KDE) backends

`content/.local/share/applications/org.kde.discover.desktop` shadows the packaged
entry in `/usr/share/applications` so Discover loads every backend except
`snap-backend`. It is a verbatim copy of the system file with `--backends` added to
both `Exec` lines, and nothing else changed. Keep the two `Exec` lines in step: one
is the main entry, the other the "See Available Updates" action, and editing only
one makes behaviour depend on how Discover was launched.

Discover waits for every loaded backend to report that it has finished fetching
before it clears the "Fetching updates…" state, so a single backend that never
reports back hangs the window indefinitely. `snap-backend` can leave Discover
stuck fetching updates. The desktop override excludes it; snaps remain manageable
through the `snap` CLI.

Changing the file needs two caches refreshed, the second being the one Plasma's
launcher actually reads:

```bash
update-desktop-database ~/.local/share/applications
kbuildsycoca6
```

Discover is single-instance. A running process is re-activated with the backends it
originally started with, so kill it before testing a change:

```bash
kill $(pgrep -x plasma-discover) 2>/dev/null
tr '\0' ' ' < /proc/$(pgrep -x plasma-discover)/cmdline; echo
```

If the packaged entry gains options later, diff it and re-apply `--backends`:

```bash
diff /usr/share/applications/org.kde.discover.desktop \
  content/.local/share/applications/org.kde.discover.desktop
```
