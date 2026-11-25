# New machine

Setting up another computer from this repo. Steps that differ between the Fedora
desktop and the Arch laptop say so (see [Machines](../README.md#machines)).

## 1. Packages

Install `git`, `chezmoi`, and the packages in
[Packages](./packages.md#distro-packages-that-config-depends-on). For the Rust
tools under [Rust](./packages.md#rust), install `rustup` (or the distro's
`rust`); `rustup` installs no toolchain at first, so run `rustup default stable`
once.

On Arch, packages outside the official repos come from the AUR. Build the paru
helper once by hand, then `paru -S <package>` installs from the repos or the AUR,
showing each AUR build script for review, and `paru` alone updates everything:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

`.exports` sets `LC_ALL=en_US.UTF-8`. On Arch, uncomment `en_US.UTF-8 UTF-8` in
`/etc/locale.gen` and run `sudo locale-gen`, or every program warns about the
locale.

pyenv, nodenv, and rbenv are optional git checkouts, and both shells load
whichever are present. pyenv builds Python itself; nodenv and rbenv need the
node-build and ruby-build plugins for `nodenv install` and `rbenv install`:

```bash
git clone https://github.com/pyenv/pyenv ~/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv ~/.pyenv/plugins/pyenv-virtualenv
git clone https://github.com/nodenv/nodenv ~/.nodenv
git clone https://github.com/nodenv/node-build ~/.nodenv/plugins/node-build
git clone https://github.com/rbenv/rbenv ~/.rbenv
git clone https://github.com/rbenv/ruby-build ~/.rbenv/plugins/ruby-build
```

## 2. Sync

```bash
git clone git@github.com:lararosekelley/dotfiles ~/Code/personal/dotfiles
chezmoi init --source ~/Code/personal/dotfiles
chezmoi apply --interactive
```

`init` asks whether to install the KDE settings; answer no on the Arch laptop.
See [Syncing](./syncing.md) for the everyday commands. Copy over the private
files the repo leaves out, such as `~/.environment`.

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

  Expect a lot of errors from Neovim at first, mostly around missing
  dependencies. Not having `gem`, `npm`, `pip`, etc. will cause a lot of
  problems. To work through the rest of the Neovim setup, follow the guide in the
  nvim repo.

- Install `flatpak`, then the GUI apps listed under
  [Flatpak](./packages.md#flatpak), starting with Zen:

  ```bash
  flatpak install app.zen_browser.zen
  ```

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

## 6. Desktop

On the Arch laptop, build out the sway desktop as described in [Sway](./sway.md).
