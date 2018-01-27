# Setup

> Bootstrap your Mac for software development

[![Build status][1]][2]

---

**NOTE**: This is currently broken. Fixes coming soon!


TBD

## Prerequisites

- macOS 10.13 (High Sierra)

These scripts have been tested previously on macOS 10.11 and 10.12, but are no longer guaranteed to work on those
operating systems. Upgrade or run at your own risk!

## Installation

Before installing anything, be sure to read through the [installation script][5]. Everything is commented thoroughly,
so it shouldn't take too much time to understand what's happening under the hood. Once you've done that, you can
download and run the script:

```bash
$ bash <(curl -s https://raw.githubusercontent.com/tylucaskelley/setup.sh/master/bin/setup)
```

You'll be prompted for your password at the beginning, and asked to confirm a few things as the script runs. When
finished, restart your terminal to see all of the changes.

## Features

Here's what the setup scripts can do:

1. Installs the Xcode command line tools
2. Instals the Homebrew package manager
3. Installs Mac apps with Homebrew Cask
4. Sets up environments and installs packages for a few programming languages:
    - Go
    - Java
    - Node.js (nvm)
    - PHP
    - Python 2 & 3 (pyenv)
    - Ruby (rbenv)
    - Rust
    - Scala
5. Set up the Vim text editor with a great configuration and lots of plugins
6. Creates an SSH key and adds it to the macOS Keychain
7. Changes Terminal theme and Bash prompt
8. Configures Tmux
9. Adds lots of convenient aliases and functions to the shell

## FAQ

1. Can I run this if I've already set up my laptop?
    - Yes; the scripts don't do anything desctructive without your permission, so it's safe to run this even if you've
      already set up your development environment before
2. Do I have to install everything?
    - Nope! There are only a few required steps - namely the Xcode command line tools, Homebrew, and a few dotfiles.
      Everything else is optional.

## Screenshots

`Terminal.app` with the provided `mux` function to create a nice Tmux session:

[Terminal][6]

A Vim window with some open tabs:

[Vim][7]

Vim autocompletion via YouCompleteMe:

[Vim autocomplete][8]

## Contributing

See [CONTRIBUTING.md][4].

## License

Copyright (c) 2014-2018 Ty-Lucas Kelley. MIT License.

[1]: https://travis-ci.org/tylucaskelley/setup.svg?branch=master
[2]: https://travis-ci.org/tylucaskelley/setup
[3]: img/logo.png
[4]: .github/CONTRIBUTING.md
[5]: bin/setup
[6]: img/screenshots/terminal.png
[7]: img/screenshots/vim.png
[8]: img/screenshots/vim-autocomplete.png
