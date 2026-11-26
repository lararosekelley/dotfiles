# New machine

Setting up another computer from this repo. Steps that differ between the Fedora
desktop and the Arch laptops say so (see [Machines](../README.md#machines)).
`chezmoi apply` does most of the work in step 2; the rest of this page is what
it can't do.

## 1. Before chezmoi

Install `git` and `chezmoi`.

On Arch:

- `.exports` sets `LC_ALL=en_US.UTF-8`. Uncomment `en_US.UTF-8 UTF-8` in
  `/etc/locale.gen` and run `sudo locale-gen`, or every program warns about
  the locale.
- Build the paru AUR helper once by hand. The setup installs AUR packages with
  it, and skips them without it:

  ```bash
  sudo pacman -S --needed base-devel git
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si
  ```

- Bring the system up to date with `sudo pacman -Syu`.

Copy or create your SSH keys in `~/.ssh`, and add the public key to GitHub:
the repo and the config repos below are cloned over SSH.

## 2. chezmoi

```bash
git clone git@github.com:lararosekelley/dotfiles ~/Code/personal/dotfiles
chezmoi init --source ~/Code/personal/dotfiles
chezmoi diff
chezmoi apply
```

`init` asks whether to install the KDE settings (answer no on the Arch laptops)
and the machine's name (`framework`, `thinkpad`, or `desktop`). Read `chezmoi
diff` before applying: chezmoi replaces whole files, so back up any config on
the machine you want to keep.

Run `apply` from a terminal, so its setup scripts can ask before using `sudo`;
without one they skip those steps with a warning. They install the distro
packages, Flatpaks, and desktop apps, clone pyenv, nodenv, rbenv, and the
config repos (nvim, emacs.d, kitty, herdr, tuios), run the nvim repo's
`scripts/install-deps`, and enable the user services. See
[Syncing](./syncing.md#setup-scripts) for each script. Each is safe to rerun,
and a step that fails runs again on the next `chezmoi apply`.

## 3. After the first apply

- Copy over the private files the repo leaves out: `~/.environment` (including
  `JELLYFIN_API_KEY`), `~/.config/navi/navi.env` (`chmod 600`), and the host
  entries in `~/.ssh/config`. chezmoi only adds `AddKeysToAgent` to that file.
- Make fish the login shell, then log out and back in:

  ```bash
  chsh -s /usr/bin/fish
  ```

- Install the binaries in
  [Self-updating and standalone binaries](./packages.md#self-updating-and-standalone-binaries),
  including `claude`, `codegraph`, `herdr`, `navi`, `tuicr`, and `git-stk` in
  `~/.local/bin`, and the `gh` extensions listed there. herdr also needs its
  plugins linked and agent integrations installed; its README lists the
  commands.
- Install the fonts no package covers: IosevkaTerm Nerd Font on Fedora, from
  [Nerd Fonts](https://www.nerdfonts.com/font-downloads), and Nunito on Arch.
  On Fedora, also download cliamp into `~/.local/bin` (see
  [Packages](./packages.md#self-updating-and-standalone-binaries)).
- If you use `rustup`, it installs no toolchain at first: run
  `rustup default stable` once.

On the desktop:

- Apply the KDE theme, widgets, and settings with `just kde-apply` (see
  [Desktop preferences](./desktop-preferences.md)).
- Install Callie and Jot with their own install scripts, and sfizz by hand.
- Set up Jellyfin's libraries as in [Media server](./media-server.md), and
  OpenRGB as in [RGB lighting](./rgb-lighting.md).

On an Arch laptop, see [Sway](./sway.md) for the desktop. recoll's indexer
waits for a graphical session target that sway doesn't start; see
[Background services](./background-services.md) for starting it.

## 4. Neovim

- `scripts/install-deps` ends with what it couldn't install, such as npm
  packages when npm's global folder isn't writable, a Python version for
  pyenv's `neovim3` environment, vale, google-java-format, or ueberzugpp. Rerun
  `~/.config/nvim/scripts/install-deps` any time; it only installs what's
  missing.
- Open `nvim` once: lazy.nvim installs the plugins and Mason the language
  servers. Then run `:checkhealth` for anything still missing.

## Keeping it current

`chezmoi update` pulls the repo and applies it; see [Syncing](./syncing.md).
chezmoi never pulls the config repos it cloned, so run `git pull` in
`~/.config/nvim`, `~/.emacs.d`, `~/.config/kitty`, `~/.config/herdr`, and
`~/.config/tuios` when they change.
