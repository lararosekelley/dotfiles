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
herdr integration install opencode
```

The tracked `.claude/settings.json` registers the Claude one as a `SessionStart`
hook, so it points at a file that only exists once the command above has run.
`herdr integration status` lists what is installed and whether it's current.

The layout expects these on `PATH`:

| tool         | used by                                          |
| ------------ | ------------------------------------------------ |
| `python3`    | the default-session plugin                       |
| `git`        | repo detection for the git, review, and prs tabs |
| `opencode`   | `agents` tab                                     |
| `nvim`       | `editor` tab                                     |
| `lazygit`    | `git` tab and the `prefix+alt+g` popup           |
| `glances`    | `system` tab                                     |
| `journalctl` | `system` tab (systemd)                           |
| `tuicr`      | `review` tab                                     |
| `ghzinga`    | `prs` tab (`cargo install ghzinga`)              |
| `gh`         | picking which PR the `prs` tab opens             |

Anything missing degrades rather than breaks: the pane reports the failure and
drops back to an interactive shell.
