# Dotfiles

> My dotfiles (Linux-oriented)

---

This repository contains the configuration files I use on Linux computers.
Dotfiles live under the `content/` directory.

Only tested on Fedora as of 2026, confirmed to work with Fedora 40+.

## System dependencies

### Required

- `git` - cloning and the prompt
- `rust` - builds and runs the sync CLI
- `mold` - linker selected in `content/.cargo/config.toml`; every cargo build fails without it
- `pyenv`, `nodenv`, `rbenv` - `.bashrc` evals each unguarded, so a missing one errors on every shell
- `bash-completion` - sourced by `.bashrc`
- `nvim` - `$EDITOR` and the `vim`/`vi` aliases

### Optional

Repo tooling:

- `just` - runs the recipes in these docs
- `node`/`npm` - husky hooks, commitlint, markdownlint-cli2
- `pipx` - installs black and flake8 for `just lint-python`

Shell:

- `rg` - the `rgs`/`rgf` aliases and the `sub` function
- `autojump` - directory jumping, wired into `PROMPT_COMMAND`
- `keychain` - loads the ssh key once per login
- `xclip` - the `copy`/`pbcopy` aliases
- `tmux` + `tpm` - `.tmux.conf` and the `mux` function
- `python3` - the `serve` function and the herdr default-session plugin
- `awscli` - the `aws-work`/`aws-personal`/`aws-current` helpers
- `figlet` - the `big` alias
- `yt-dlp` - the `dl` alias
- `ffmpeg`, `gifsicle` - the `flac2mp3`/`vid2mp4`/`vidslice`/`mov2gif` functions

Git:

- `diff-so-fancy` - git pager
- `git-lfs` - the lfs filters in `.gitconfig`
- `git-stk` - stacked branches; the `stk` wrapper and `[stk]` config

Tools with config here:

- `herdr` - the `herd` function and `content/.config/herdr` (see [herdr](./docs/herdr.md) for what its layout expects)
- `restic` - `content/.bin/backup.sh`, keyed off `content/.config/restic`
- `recoll` - full-text index; the `recollindex` unit override and the `recoll-search` Claude skill
- `navi` - PR-review alerts; installed to `~/.local/bin` and run by `navi.service`
- `claude`, `opencode` - the `ai` function
- `codegraph` - Claude `SessionStart` hook and MCP server
- `uvx`, `npx` - run the aws and circleci MCP servers in `.claude/.mcp.json`
- `gh`, `glab`, `gt` - GitHub, GitLab, and Graphite CLIs
- `gcalcli`, `fastfetch` - configured under `content/.config`
- `openrgb` - case lighting; see [RGB lighting](./docs/rgb-lighting.md)

## Getting started

Clone the repository:

```bash
git clone git@github.com:lararosekelley/dotfiles
```

Sync files to your home directory using the Rust CLI:

```bash
cargo run -- sync to-home
```

Or use the Justfile shortcuts:

```bash
just sync-to-home
```

It will prompt you to copy each file individually, so that no unexpected changes are made.

The sync installs `content/.git_prompt` as `~/.git_prompt`, which `.bashrc` sources
for Git prompt support. No separate prompt installation is needed.

See the [sync CLI guide](./docs/sync-cli.md) for symlinks, status, and previewing changes.

## Guides

Setup and management notes for this machine and its devices live in [`docs/`](./docs):

- [Sync CLI](./docs/sync-cli.md) - syncing, status, and previewing changes
- [Packages](./docs/packages.md) - where each program comes from and how to update it
- [AI agents](./docs/ai-agents.md) - `/finalize`, `/audit`, and keeping the machine awake while agents work
- [herdr](./docs/herdr.md) - plugins, integrations, and the tools the layout expects
- [Background services](./docs/background-services.md) - user systemd units
- [Audio plugins and OBS](./docs/audio-and-obs.md)
- [RGB lighting](./docs/rgb-lighting.md) - OpenRGB profiles and services
- [Discover (KDE) backends](./docs/kde-discover.md) - why `snap-backend` is disabled
- [KDE Connect (Android)](./docs/kde-connect-android.md) - phone-to-desktop clipboard and staying connected
- [Formatting and linting](./docs/formatting-and-linting.md)

Neovim, Emacs, and Kitty configs live in their own repos:
[nvim](https://github.com/lararosekelley/nvim),
[emacs.d](https://github.com/lararosekelley/emacs.d), and
[kitty](https://github.com/lararosekelley/kitty).

## License

Copyright (c) 2014-2026 Lara Kelley. MIT License.
