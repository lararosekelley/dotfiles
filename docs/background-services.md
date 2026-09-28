# Background services

`content/.config/systemd/user` holds the user units, which syncing alone does not
turn on:

| unit                                  | what it does                           |
| ------------------------------------- | -------------------------------------- |
| `navi.service`                        | PR-review alerts, polls every 60s      |
| `recollindex.service.d/override.conf` | keeps recoll's indexer off the desktop |

```bash
systemctl --user daemon-reload
systemctl --user enable --now navi.service
```

`navi.service` reads its tokens from `~/.config/navi/navi.env`, which is not
synced. Create it by hand (`chmod 600`) with one `KEY=value` per line for the
sources enabled in `config.toml`. The unit tolerates the file being missing, so
navi starts either way and only the sources needing a token stay quiet.
