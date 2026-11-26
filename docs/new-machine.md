# New machine

Setting up another computer from this repo. Steps that differ between the Fedora
desktop and the Arch laptop say so (see [Machines](../README.md#machines)).

## 1. Packages

Install `git` and `chezmoi`; `chezmoi apply` in step 2 installs the rest of
the [packages](./packages.md#distro-packages-that-config-depends-on). For the Rust
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

pyenv, nodenv, and rbenv, with their build plugins, are git checkouts that
`chezmoi apply` clones in step 2; both shells load whichever are present.

## 2. Sync

```bash
git clone git@github.com:lararosekelley/dotfiles ~/Code/personal/dotfiles
chezmoi init --source ~/Code/personal/dotfiles
chezmoi apply --interactive
```

`init` asks whether to install the KDE settings (answer no on the Arch laptop)
and the machine's name (`framework`, `thinkpad`, or `desktop`).
See [Syncing](./syncing.md) for the everyday commands. Copy over the private
files the repo leaves out, such as `~/.environment`.

## 3. Tools outside the repo

- Reinstall the binaries in
  [Self-updating and standalone binaries](./packages.md#self-updating-and-standalone-binaries),
  including `herdr`, `navi`, `tuicr`, `git-stk`, and `claude` in `~/.local/bin`.
- The configs that live in their own repos (nvim, emacs.d, kitty, herdr, tuios)
  are cloned by `chezmoi apply` in step 2, which then runs the nvim repo's
  `scripts/install-deps` for what Neovim needs. It asks before installing system
  packages and ends with anything left to install by hand.

  herdr also needs its plugins linked and agent integrations installed; its
  README lists the commands.

- The GUI apps under [Flatpak](./packages.md#flatpak) are installed for your
  user by `chezmoi apply` in step 2.

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
