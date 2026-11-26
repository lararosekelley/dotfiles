# Media server

The desktop serves movies, TV, music, and videos from Dropbox with
[Jellyfin](https://jellyfin.org). The repo installs it and starts it; the rest
of its setup lives in Jellyfin's own database, so it is done by hand once per
machine and kept with Jellyfin's backups rather than in this repo.

## Install and start

`chezmoi apply` installs Jellyfin on the desktop only, from
[`apps-desktop.txt`](../scripts/setup/apps-desktop.txt): `jellyfin` from RPM
Fusion on Fedora, `jellyfin-server` and `jellyfin-web` on Arch. It then enables
`jellyfin.service`, a system unit, through `scripts/setup/services`, which asks
first. The server runs as the `jellyfin` user at <http://localhost:8096>.

## Media folders

Jellyfin reads the media folders as the `jellyfin` user. Media files are
usually readable by everyone, but a private folder above them, such as a home
folder, a drive mounted under `/run/media/$USER`, or a Dropbox folder, blocks
the way. Give the `jellyfin` user passage through each private folder on the
path, which lets it reach the media without listing those folders or opening
anything private beside them:

```bash
setfacl -m u:jellyfin:x /path/to/private /path/to/private/sub
sudo -u jellyfin ls /path/to/private/sub/movies  # check
```

Files Dropbox adds later stay readable, since they are created with the usual
`022` umask. A folder made private by hand needs `chmod -R o+rX` before
Jellyfin can scan it.

## First run

Open <http://localhost:8096>, create the admin user, and add a library for each
media folder (movies, TV, music) with its content type. Type each full path into
the folder field rather than browsing to it: the browser can't show a folder
Jellyfin may only pass through.

## cliamp

cliamp plays the music library through its `[jellyfin]` provider, set in
`~/.config/cliamp/config.toml`. Create an API key under Dashboard > API Keys
and put it in `~/.environment`, which is not synced:

```bash
JELLYFIN_API_KEY=...
```

## Backups

Users, libraries, watch history, and metadata live in `/var/lib/jellyfin`, and
server settings in `/etc/jellyfin`. Back them up from Dashboard > Backups, or
include both paths in a restic backup, and restore them on a new machine
instead of setting up the libraries again.
