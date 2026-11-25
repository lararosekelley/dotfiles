# Background services

`~/.config/systemd/user` holds the user units, which installing them does not
turn on:

| unit                                  | what it does                           |
| ------------------------------------- | -------------------------------------- |
| `navi.service`                        | PR-review alerts, polls every 60s      |
| `recollindex.service.d/override.conf` | keeps recoll's indexer off the desktop |

```bash
systemctl --user daemon-reload
systemctl --user enable --now navi.service
systemctl --user enable --now recollindex.service
```

recoll ships `recollindex.service` on both Fedora and Arch, as
`WantedBy=graphical-session.target`. KDE Plasma starts that target; sway does
not, so under sway the indexer never starts on its own. Start sway through
something that runs the session target, such as uwsm, or start the indexer from
the sway config with `exec systemctl --user start recollindex.service`.

`navi.service` reads its tokens from `~/.config/navi/navi.env`, which is not
synced. Create it by hand (`chmod 600`) with one `KEY=value` per line for the
sources enabled in `config.toml`. The unit tolerates the file being missing, so
navi starts either way and only the sources needing a token stay quiet.
