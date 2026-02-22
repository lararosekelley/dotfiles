# Dotfiles

> My dotfiles

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

### Neovim configuration

For my Neovim configuration, check out my [nvim](https://github.com/lararosekelley/nvim) repository.

### Emacs configuration

For my Emacs configuration, check out my [emacs.d](https://github.com/lararosekelley/emacs.d) repository.

## License

Copyright (c) 2014-2025 Lara Kelley. MIT License.
