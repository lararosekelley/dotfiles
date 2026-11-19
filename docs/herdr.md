# herdr

[herdr](https://herdr.dev) config lives in `content/.config/herdr`. The startup
layout (tabs, splits, and the TUIs in them) is a local plugin under
`content/.config/herdr/local-plugins/default-session`; see
[its README](../content/.config/herdr/local-plugins/default-session/README.md)
for the layout and keybindings.

Syncing the files is not enough on its own. Plugins are registered in
`plugins.json`, so link the local one and install the third-party ones:

```bash
herdr plugin link ~/.config/herdr/local-plugins/default-session
herdr plugin install persiyanov/herdr-reviewr
herdr plugin install paulbkim-dev/vim-herdr-navigation
```

The agent integrations need installing too, so they are deliberately not synced:

```bash
herdr integration install claude
herdr integration install codex
herdr integration install opencode
```

The tracked `.claude/settings.json` registers the Claude one as a `SessionStart`
hook, so it points at a file that only exists once the command above has run.
`herdr integration status` lists what is installed and whether it's current.

The layout expects these on `PATH`:

| tool         | used by                                                  |
| ------------ | -------------------------------------------------------- |
| `python3`    | the default-session plugin                               |
| `git`        | repo detection for the git, review, and github tabs      |
| `claude`     | `agents` tab, with `herd --agent claude`                 |
| `codex`      | `agents` tab, with `herd --agent codex`                  |
| `opencode`   | `agents` tab, the default                                |
| `nvim`       | `editor` tab                                             |
| `lazygit`    | `git` tab and the `prefix+alt+g` popup                   |
| `glances`    | `system` tab                                             |
| `journalctl` | `system` tab (systemd)                                   |
| `tuicr`      | `review` tab                                             |
| `gh`         | `github` tab, with the gh-dash and gh-enhance extensions |

Anything missing degrades rather than breaks: the pane reports the failure and
drops back to an interactive shell.

## Herdr app

The desktop app (`herdr-app`) and its terminal server, herdr-core (`hc`), are
separate from the `herdr` TUI above: they share no config, plugins, or sessions.
Only `keys.json` and `settings.json` from `~/.config/herdr-app` are tracked. The
app writes everything else there itself.

The window uses the [World of Codecraft](https://github.com/kevinpardo/world-of-codecraft)
layout, installed from its repo rather than synced:

```bash
git clone https://github.com/kevinpardo/world-of-codecraft
world-of-codecraft/tools/install.sh
herdr-app do layout.switch '{"name":"World-of-Codecraft"}'
```

The tracked `keys.json` already has the layout's keys. For the activity scenes,
run `world-of-codecraft/tools/install.sh --integrations`. It links
`~/.claude/hooks/wocc-activity.py`, which the tracked `.claude/settings.json`
already registers.
