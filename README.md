# Dotfiles

> My dotfiles

---

This repository contains the configuration files I use on Linux computers.
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

Next, either copy files manually to your home directory, or
use the provided `copy` script:

```bash
cd dotfiles && ./copy
```

It will prompt you to copy each file individually, so that no unexpected changes are made.

### Neovim configuration

For my Neovim configuration, check out my [nvim](https://github.com/lararosekelley/nvim) repository.

### Emacs configuration

For my Emacs configuration, check out my [emacs.d](https://github.com/lararosekelley/emacs.d) repository.

## License

Copyright (c) 2014-2025 Lara Kelley. MIT License.
