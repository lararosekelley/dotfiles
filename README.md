# Dotfiles

> My dotfiles (Linux-oriented)

---

This repository contains the configuration files I use on Linux computers.
Dotfiles live under the `content/` directory.
Only tested on Fedora as of 2024, confirmed to work with Fedora 41.

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
layout — tabs, splits, and the TUIs in them — is a local plugin under
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

The layout expects these on `PATH`:

| tool         | used by                                            |
| ------------ | -------------------------------------------------- |
| `python3`    | the default-session plugin                         |
| `git`        | repo detection for the git, review, and prs tabs   |
| `nvim`       | `editor` tab                                       |
| `lazygit`    | `git` tab and the `prefix+alt+g` popup             |
| `glances`    | `system` tab                                       |
| `journalctl` | `system` tab (systemd)                             |
| `tuicr`      | `review` tab                                       |
| `ghzinga`    | `prs` tab (`cargo install ghzinga`)                |
| `gh`         | picking which PR the `prs` tab opens               |

Anything missing degrades rather than breaks: the pane reports the failure and
drops back to an interactive shell.

### Neovim configuration

For my Neovim configuration, check out my [nvim](https://github.com/lararosekelley/nvim) repository.

### Emacs configuration

For my Emacs configuration, check out my [emacs.d](https://github.com/lararosekelley/emacs.d) repository.

### Kitty configuration

For my Kitty configuration, check out my [kitty](https://github.com/lararosekelley/kitty) repository.

## License

Copyright (c) 2014-2025 Lara Kelley. MIT License.
