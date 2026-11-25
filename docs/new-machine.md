# New machine

Setting up another computer from this repo. Steps that differ between the Fedora
desktop and the Arch laptop say so (see [Machines](../README.md#machines)).

## 1. Packages

Install `git`, Rust (`rustup`, or the distro's `rust`) for the sync CLI, and the
packages in [Packages](./packages.md#distro-packages-that-config-depends-on).

`.exports` sets `LC_ALL=en_US.UTF-8`. On Arch, uncomment `en_US.UTF-8 UTF-8` in
`/etc/locale.gen` and run `sudo locale-gen`, or every program warns about the
locale.

pyenv, nodenv, and rbenv are optional git checkouts, and both shells load
whichever are present:

```bash
git clone https://github.com/pyenv/pyenv ~/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv ~/.pyenv/plugins/pyenv-virtualenv
git clone https://github.com/nodenv/nodenv ~/.nodenv
git clone https://github.com/rbenv/rbenv ~/.rbenv
```

## 2. Sync

```bash
git clone git@github.com:lararosekelley/dotfiles
cd dotfiles
cargo run -- sync to-home
```

Sync asks about each file. KDE settings are included only in a KDE session, so
the Arch laptop skips them; see
[Machine-specific files](./sync-cli.md#machine-specific-files). Copy over the
private files the repo leaves out, such as `~/.environment`.

## 3. Tools outside the repo

- Reinstall the binaries in
  [Self-updating and standalone binaries](./packages.md#self-updating-and-standalone-binaries),
  including `herdr`, `navi`, `tuicr`, `git-stk`, and `claude` in `~/.local/bin`.
- Clone the configs that live in their own repos:

  ```bash
  git clone https://github.com/lararosekelley/nvim ~/.config/nvim
  git clone https://github.com/lararosekelley/emacs.d ~/.emacs.d
  git clone https://github.com/lararosekelley/kitty ~/.config/kitty
  git clone https://github.com/lararosekelley/herdr ~/.config/herdr
  git clone https://github.com/lararosekelley/tuios ~/.config/tuios
  ```

  herdr also needs its plugins linked and agent integrations installed; its
  README lists the commands.

## 4. fish

Install `fzf`, `fd` (`fd-find` on Fedora), `bat`, and `curl` first: the first
interactive fish shell downloads fisher and the plugins in `fish_plugins`, and
the plugins use those tools. Then, from a terminal (it asks for your password),
make fish the login shell and log out and back in:

```bash
chsh -s /usr/bin/fish
```

## 5. Background services

Enable the user units as described in
[Background services](./background-services.md), including the note there on
starting recoll's indexer under sway.
