# Dotfiles

> My dotfiles (Linux-oriented)

---

This repository contains the configuration files I use on Linux computers.
Dotfiles live under the `content/` directory.

Only tested on Fedora as of 2026, confirmed to work with Fedora 40+.

## Getting started

Clone the repository:

```bash
git clone git@github.com:lararosekelley/dotfiles
```

Add the `oh-my-git` submodule:

```bash
git submodule init
ln -s oh-my-git $HOME/.git_prompt
```

Next, sync files to your home directory using the Rust CLI:

```bash
cargo run -- sync to-home
```

Or use the Justfile shortcuts:

```bash
just sync-to-home
```

It will prompt you to copy each file individually, so that no unexpected changes are made.

### Rust CLI (dotfiles)

This repo includes a Rust-based CLI for syncing dotfiles with better status output
and optional symlink support:

```bash
cargo run -- sync to-home --symlink
cargo run -- sync to-repo --yes
cargo run -- status --direction to-repo
```

Justfile shortcuts:

```bash
just sync-to-home-symlink
just sync-to-repo
just status
```

### herdr configuration

[herdr](https://herdr.dev) config lives in `content/.config/herdr`. The startup
layout (tabs, splits, and the TUIs in them) is a local plugin under
`content/.config/herdr/local-plugins/default-session`; see
[its README](./content/.config/herdr/local-plugins/default-session/README.md)
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
| `claude`     | `agents` tab                                     |
| `nvim`       | `editor` tab                                     |
| `lazygit`    | `git` tab and the `prefix+alt+g` popup           |
| `glances`    | `system` tab                                     |
| `journalctl` | `system` tab (systemd)                           |
| `tuicr`      | `review` tab                                     |
| `ghzinga`    | `prs` tab (`cargo install ghzinga`)              |
| `gh`         | picking which PR the `prs` tab opens             |

Anything missing degrades rather than breaks: the pane reports the failure and
drops back to an interactive shell.

### Background services

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

### Neovim configuration

For my Neovim configuration, check out my [nvim](https://github.com/lararosekelley/nvim) repository.

### Emacs configuration

For my Emacs configuration, check out my [emacs.d](https://github.com/lararosekelley/emacs.d) repository.

### Kitty configuration

For my Kitty configuration, check out my [kitty](https://github.com/lararosekelley/kitty) repository.

## Formatting and linting

`just format` and `just lint` cover everything in the repo; `just format-lint`
runs both plus `cargo check`. The per-language recipes are
`format-rust`/`lint-rust` (rustfmt, clippy), `format-python`/`lint-python`
(black, flake8), and `format-markdown`/`lint-markdown` (markdownlint-cli2, whose
globs are passed on the command line rather than read from
`.markdownlint-cli2.yaml`).

`just lint` also runs as a `pre-commit` hook, so a commit fails rather than
landing unformatted. The companion `commit-msg` hook runs commitlint. Both live
in `.husky/` and are installed by `npm install` (via the `prepare` script).

Python here means the scripts under `content/`. [black](https://black.readthedocs.io) owns formatting and
[flake8](https://flake8.pycqa.org) catches the rest; their settings live in
`pyproject.toml` and `.flake8`, with flake8's line length matched to black's 88.
Install the tools once with:

```bash
just install-python-tools
```

## License

Copyright (c) 2014-2025 Lara Kelley. MIT License.
