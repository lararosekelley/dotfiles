# Dotfiles

> My dotfiles (Linux-oriented)

---

This repository contains the configuration files I use on Linux computers.
Dotfiles live under `home/`, which [chezmoi](https://www.chezmoi.io) installs.

## Machines

The docs refer to two setups:

- **Fedora desktop**: Fedora 40+ with KDE Plasma, and the only machine with
  OpenRGB lighting (`system/`, which sync never installs).
- **Arch laptop**: CachyOS, which is Arch-based, with sway.

Steps that differ between them name the distro. [Packages](./docs/packages.md)
maps package names between Fedora and Arch, and
[New machine](./docs/new-machine.md) is the setup checklist.

## System dependencies

### Required

- `git` - cloning and the prompt
- `chezmoi` - installs `home/` into the home directory
- `bash-completion` - sourced by `.bashrc`
- `nvim` - `$EDITOR` and the `vim`/`vi` aliases

### Optional

Repo tooling:

- `just` - runs the recipes in these docs
- `node`/`npm` - husky hooks, commitlint, markdownlint-cli2, oxfmt, oxlint
- `pipx` - installs black and flake8 for `just lint-python`
- `shellcheck`, `shfmt` - `just lint-shell`

Shell:

- `pyenv` (with `pyenv-virtualenv`), `nodenv`, `rbenv` - language versions, loaded when installed
- `rg` - the `rgs`/`rgf` aliases and the `sub` script
- `zoxide` - directory jumping with `z` and `zi`, or `j` and `ji`, hooked into `PROMPT_COMMAND`
- `wl-clipboard` (Wayland) or `xclip` (X11) - the `copy` script and `pbcopy` alias
- `tmux` + `tpm` - `.tmux.conf` and the `mux` script
- `python3` - the `serve` script
- `awscli` - the `aws-work`/`aws-personal`/`aws-current` helpers
- `figlet` - the `big` alias
- `yt-dlp` - the `dl` alias
- `ffmpeg`, `gifsicle` - the `flac2mp3`/`vid2mp4`/`vidslice`/`mov2gif` scripts
- `fish` - the alternative shell (see [fish](./docs/fish.md)); its plugins use `fzf`, `fd`, `bat`, and `curl`

Git:

- `diff-so-fancy` - git pager
- `git-lfs` - the lfs filters in `.gitconfig`
- `git-stk` - stacked branches; the `stk` wrapper and `[stk]` config

Tools with config here:

- `rust`, `mold` - `~/.cargo/config.toml` links with mold, so every cargo build fails without it
- `herdr`, `tuios` - terminal multiplexers, configured in their own repos (below)
- `restic` - `~/.bin/backup.sh`, keyed off `~/.config/restic`
- `recoll` - full-text index; the `recollindex` unit override and the `recoll-search` Claude skill. Needs `perl-JSON` (Fedora) or `perl-json` (Arch) for image metadata, which recoll does not pull in
- `navi` - PR-review alerts; installed to `~/.local/bin` and run by `navi.service`
- `claude`, `opencode` - the `ai` script
- `codegraph` - Claude `SessionStart` hook and MCP server
- `uvx`, `npx` - run the aws and circleci MCP servers in `.claude/.mcp.json`
- `gh`, `glab`, `gt` - GitHub, GitLab, and Graphite CLIs
- `gcalcli`, `fastfetch` - configured under `~/.config`
- `openrgb` - case lighting; see [RGB lighting](./docs/rgb-lighting.md)

## Getting started

Clone the repository:

```bash
git clone git@github.com:lararosekelley/dotfiles
```

Point chezmoi at the checkout and install, confirming each file:

```bash
chezmoi init --source ~/Code/personal/dotfiles
chezmoi apply --interactive
```

`.git_prompt` is installed with the rest, and `.bashrc` sources it for Git prompt
support. See [Syncing](./docs/syncing.md) for previewing changes and copying home
edits back.

## Guides

Setup and management notes for this machine and its devices live in [`docs/`](./docs):

- [New machine](./docs/new-machine.md) - setting up another computer from this repo
- [Syncing](./docs/syncing.md) - installing with chezmoi, previewing, and copying edits back
- [Packages](./docs/packages.md) - where each program comes from and how to update it
- [AI agents](./docs/ai-agents.md) - shared review, explanation, reflection, and handoff commands; activity-based sleep inhibition
- [fish](./docs/fish.md) - the fish setup, and what it shares with bash
- [Sway](./docs/sway.md) - the desktop on the Arch laptop
- [Kubernetes](./docs/kubernetes.md) - cluster tools, remote clusters over Tailscale, and a local k3d cluster
- [Background services](./docs/background-services.md) - user systemd units
- [Media server](./docs/media-server.md) - Jellyfin on the desktop, its media folders, and cliamp
- [Desktop preferences](./docs/desktop-preferences.md) - KDE theme, widgets, panels, and private hardware-specific configuration
- [Audio plugins and OBS](./docs/audio-and-obs.md)
- [RGB lighting](./docs/rgb-lighting.md) - OpenRGB profiles and services
- [Discover (KDE) backends](./docs/kde-discover.md) - why `snap-backend` is disabled
- [KDE Connect (Android)](./docs/kde-connect-android.md) - phone-to-desktop clipboard and staying connected
- [Formatting and linting](./docs/formatting-and-linting.md)
- [IG Plus](https://github.com/lararosekelley/ig-plus) - Chrome and Firefox extension for posting Instagram stories from desktop and hiding the feed and Reels

Neovim, Emacs, Kitty, herdr, and tuios configs live in their own repos:
[nvim](https://github.com/lararosekelley/nvim),
[emacs.d](https://github.com/lararosekelley/emacs.d),
[kitty](https://github.com/lararosekelley/kitty),
[herdr](https://github.com/lararosekelley/herdr), and
[tuios](https://github.com/lararosekelley/tuios). The herdr and tuios repos also
provide the `herd` and `tui` commands; `.exports` puts them on `PATH` once cloned.

## License

Copyright (c) 2014-2026 Lara Kelley. MIT License.
