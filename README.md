# Dotfiles

> My dotfiles (Linux-oriented)

---

This repository contains the configuration files I use on Linux computers.
Dotfiles live under the `content/` directory.

Only tested on Fedora as of 2026, confirmed to work with Fedora 40+.

## System dependencies

### Required

- `git` - cloning, the `oh-my-git` submodule, the prompt
- `rust` - builds and runs the sync CLI
- `mold` - linker selected in `content/.cargo/config.toml`; every cargo build fails without it
- `pyenv`, `nodenv`, `rbenv` - `.bashrc` evals each unguarded, so a missing one errors on every shell
- `bash-completion` - sourced by `.bashrc`
- `nvim` - `$EDITOR` and the `vim`/`vi` aliases

### Optional

Repo tooling:

- `just` - runs every recipe in this README
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
- `youtube-dl` - the `dl` alias
- `ffmpeg`, `gifsicle` - the `flac2mp3`/`vid2mp4`/`vidslice`/`mov2gif` functions

Git:

- `diff-so-fancy` - git pager
- `git-lfs` - the lfs filters in `.gitconfig`
- `git-stk` - stacked branches; the `stk` wrapper and `[stk]` config

Tools with config here:

- `herdr` - the `herd` function and `content/.config/herdr` (see the table below for what its layout expects)
- `restic` - `content/.bin/backup.sh`, keyed off `content/.config/restic`
- `recoll` - full-text index; the `recollindex` unit override and the `recoll-search` Claude skill
- `navi` - PR-review alerts; installed to `~/.local/bin` and run by `navi.service`
- `claude`, `opencode` - the `ai` function
- `codegraph` - Claude `SessionStart` hook and MCP server
- `uvx`, `npx` - run the aws and circleci MCP servers in `.claude/.mcp.json`
- `gh`, `glab`, `gt` - GitHub, GitLab, and Graphite CLIs
- `gcalcli`, `fastfetch` - configured under `content/.config`

RGB lighting:

If you use `openrgb` and know what you're doing:

```bash
D=~/folder/you/cloned/repo/to/dotfiles/system

mkdir -p ~/.config/OpenRGB
cp $D/*.orp $D/*.ors $D/OpenRGB.json ~/.config/OpenRGB/

sudo mkdir -p /root/.config/OpenRGB
sudo cp $D/*.orp /root/.config/OpenRGB/

sudo install -m 644 $D/openrgb*.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now openrgb.service
sudo systemctl enable openrgb-resume.service openrgb-sleep.service
```

Modify the profiles (defaults are `off.orp` and `pink.orp`, included when syncing the main
dotfiles in `content/` to suit your needs / case lighting setup.

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

#### Previewing changes

Two ways to see what a sync would do, neither of which writes anything:

```bash
cargo run -- status --diff                 # per-file status plus a unified diff
cargo run -- sync to-home --dry-run --yes  # the exact actions sync would take
```

`status --diff` shows, for every file whose contents differ, a `diff -U3`-style
hunk of the destination's current contents against the incoming ones. Binary
files are reported as a size change rather than dumped, and files missing at the
destination are summarised by line count. Diffs are skipped under `--symlink`,
which never rewrites contents.

Diffs are coloured like git's — removals red, additions green, file headers
bold — when stdout is a terminal and `NO_COLOR` is unset. `--color` overrides
that:

```bash
cargo run -- status --diff --color=always | less -R  # keep colour through a pipe
cargo run -- status --diff --color=never             # plain output on a terminal
```

`--dry-run` prints the `copy`, `symlink`, `remove`, `backup`, and `mkdir -p`
operations instead of performing them. Pair it with `--yes`; without it, sync
still asks about each file one at a time.

Justfile shortcuts:

```bash
just diff
just diff-to-repo
just sync-to-home-dry-run
just sync-to-repo-dry-run
```

### Keep the machine awake while coding agents work

[Agent Awake](./content/.local/share/agent-awake/README.md) integrates OpenCode lifecycle events and Claude Code hooks with Linux sleep inhibitors. It releases leases when turns finish or need input, with crash cleanup and independent leases for concurrent sessions.

Install the helper and integrations without replacing unrelated live Claude settings:

```bash
python3 content/.local/share/agent-awake/install.py
```

Restart both clients afterward. See the linked guide for Fedora dependencies, verification, uninstall steps, and Claude's permission-approval timing limitation.

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

### Discover (KDE) backends

`content/.local/share/applications/org.kde.discover.desktop` shadows the packaged
entry in `/usr/share/applications` so Discover loads every backend except
`snap-backend`. It is a verbatim copy of the system file with `--backends` added to
both `Exec` lines, and nothing else changed. Keep the two `Exec` lines in step: one
is the main entry, the other the "See Available Updates" action, and editing only
one makes behaviour depend on how Discover was launched.

Discover waits for every loaded backend to report that it has finished fetching
before it clears the "Fetching updates…" state, so a single backend that never
reports back hangs the window indefinitely. Bisecting with `--backends` narrowed
that to `snap-backend`: dropping it loads updates immediately, adding it back
hangs, and `kns-backend` is fine either way. It is not a slow `snapd` — the socket
answers `/v2/system-info` and `/v2/snaps` in single-digit milliseconds and the hung
process holds no open sockets at all. Snaps stay manageable through the `snap` CLI.

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

Copyright (c) 2014-2026 Lara Kelley. MIT License.
