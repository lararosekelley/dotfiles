# Background services

`~/.config/systemd/user` holds the user units. `chezmoi apply` enables and
starts them, and `jellyfin.service` on the desktop (see
[Media server](./media-server.md)), through `scripts/setup/services`, which
skips a unit whose program isn't installed yet. To enable them by hand:

| unit                                  | what it does                           |
| ------------------------------------- | -------------------------------------- |
| `ssh-agent.socket`                    | the SSH agent, from the distro         |
| `pkgfile-update.timer` (Arch)         | refreshes pkgfile's database daily     |
| `navi.service`                        | PR-review alerts, polls every 60s      |
| `clip-receive.service`                | Taildrop clips onto the clipboard      |
| `recollindex.service.d/override.conf` | keeps recoll's indexer off the desktop |

```bash
systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.socket
systemctl --user enable --now navi.service
systemctl --user enable --now recollindex.service
```

recoll ships `recollindex.service` on both Fedora and Arch, as
`WantedBy=graphical-session.target`. KDE Plasma starts that target; sway does
not, so the sway session config starts the indexer itself with
`exec systemctl --user start recollindex.service`.

`navi.service` reads its tokens from `~/.config/navi/navi.env`, which is not
synced. Create it by hand (`chmod 600`) with one `KEY=value` per line for the
sources enabled in `config.toml`. The unit tolerates the file being missing, so
navi starts either way and only the sources needing a token stay quiet.

`ssh-agent.socket` comes with OpenSSH on both Fedora and Arch, and `.exports`
points `SSH_AUTH_SOCK` at it. `~/.ssh/config` stays local, but chezmoi's
`modify_private_config` adds `AddKeysToAgent yes` under `Host *` when no
`AddKeysToAgent` line is there, so a key's passphrase is asked once per
session.
