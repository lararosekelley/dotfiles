# Dotfiles

> My dotfiles

---

This repository contains the dotfiles I use on any macOS computer I'm working off of.

## Getting started

1. Clone the repository: `git clone git@github.com:tylucaskelley/dotfiles`
2. Install some recommended programs via the provided `install` script: `./install`
    - Note that this script is safe to run and will not override any existing
      program installations. See below for details.
3. Set up a symbolic link to your home directory for the files: `ln -sv /path/to/dotfiles/src/* ~`

Any time you want to make changes, simply edit the files within the original cloned repository.

## Installation script (TBD)

I provide a Bash script that can ensure your computer is ready to use my dotfiles. It will do the following:

1. Ensure you're on the latest macOS version
2. Install Homebrew and a set of useful tools
3. Installs a few version managers for popular languages: Ruby, Python, and Node.js
4. Installs and configures Neovim
5. Installs and configures tmux
6. Optionally, installs desktop apps via Homebrew Cask

Please use the installation script at your own risk, and review [its contents](./install) before running.

## License

Copyright (c) 2014-2019 Ty-Lucas Kelley. MIT License.
