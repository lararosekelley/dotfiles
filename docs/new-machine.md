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

Name the machine after its role, the same name `chezmoi init` asks for below
(`desktop`, `framework`, or `thinkpad`). chezmoi then picks it as the default,
and it's the name other machines reach it by on the network and the tailnet,
such as cliamp's `http://desktop:8096`:

```bash
sudo hostnamectl hostname desktop
```

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
- Join the personal tailnet, which the machines share (cliamp reaches the
  desktop's Jellyfin over it), and let `tailscale switch` run without sudo.
  Add the work account too, to switch to when needed; see
  [Kubernetes](./kubernetes.md#remote-clusters-over-tailscale):

  ```bash
  sudo tailscale up            # log in with the personal account
  sudo tailscale set --operator=$USER
  tailscale login              # the work account, then switch back:
  tailscale switch <personal-account>
  ```

  On Arch, if `tailscale status` warns that NetworkManager and
  systemd-resolved are wired together incorrectly, `/etc/resolv.conf` is
  NetworkManager's own file while systemd-resolved is running. Point it at
  systemd-resolved's stub, which NetworkManager then follows, and restart both:

  ```bash
  sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
  sudo systemctl restart NetworkManager tailscaled
  ```

- On Arch, build pkgfile's database once with `sudo pkgfile --update`, so fish
  can name the package a missing command is in; a timer keeps it current after
  that. Fedora's PackageKit does the same without setup.
- Make fish the login shell, then log out and back in:

  ```bash
  chsh -s /usr/bin/fish
  ```

- Install the binaries in
  [Self-updating and standalone binaries](./packages.md#self-updating-and-standalone-binaries),
  including `claude`, `herdr`, `navi`, and `git-stk` in `~/.local/bin`, and the
  `gh` extensions listed there. `chezmoi apply` installs `codegraph` and
  `tuicr`. herdr also needs its plugins linked and agent integrations
  installed; its README lists the commands. `scripts/setup/config-repos`
  installs the Claude integration, so rerun it once herdr is installed.
- On Fedora, install IosevkaTerm Nerd Font, which no package covers, from
  [Nerd Fonts](https://www.nerdfonts.com/font-downloads), and download cliamp
  into `~/.local/bin` (see
  [Packages](./packages.md#self-updating-and-standalone-binaries)).
- If you use `rustup`, it installs no toolchain at first: run
  `rustup default stable` once.

On the desktop:

- Apply the KDE theme, widgets, and settings with `just kde-apply` (see
  [Desktop preferences](./desktop-preferences.md)).
- Install Callie and Jot with their own install scripts, and sfizz by hand.
- Set up Jellyfin's libraries as in [Media server](./media-server.md), and
  OpenRGB as in [RGB lighting](./rgb-lighting.md).
- Load the drivers for the board's fan headers and the SATA drive's
  temperature at every boot, for waybar's hardware pill (see
  [Sway](./sway.md#status-bar)):

  ```bash
  sudo install -m 644 system/modules-load.d/sensors.conf /etc/modules-load.d/
  sudo modprobe nct6683 drivetemp
  ```

- Run the case and radiator fans at full speed, set again at every boot and
  after sleep, since the Commander Pro and the Kraken forget it when they lose
  power. The Kraken's pump keeps its own curve:

  ```bash
  sudo install -m 755 system/fans-full /usr/local/sbin/
  sudo install -m 644 system/fans-full.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now fans-full.service
  ```

On a machine with a fingerprint reader, set up fingerprint login. `chezmoi
apply` installs fprintd; enroll a finger and check it matches:

```bash
fprintd-enroll
fprintd-verify
```

If enrolling fails on the Framework, update the reader's firmware first with
`fwupdmgr refresh && fwupdmgr update`. On Fedora, turn it on for every service
that asks for a password with `sudo authselect enable-feature with-fingerprint`.
On Arch, add this line before the other `auth` lines in each PAM file that
should accept a fingerprint. A password still works wherever it's added:

```text
auth  sufficient  pam_fprintd.so
```

- `/etc/pam.d/sudo`, for `sudo`.
- `/etc/pam.d/polkit-1`, for apps that ask for your password. Arch ships it as
  `/usr/lib/pam.d/polkit-1`; copy that to `/etc/pam.d` first.
- `/etc/pam.d/login`, after its `pam_nologin` line. ly's file (CachyOS's login
  screen, `ly@tty2`) includes it, so this covers ly and a text console.

Add it to those files rather than `system-auth`, which every service shares. A
fingerprint login doesn't unlock the keyring, which needs the password.

On an Arch laptop, see [Sway](./sway.md) for the desktop.

### Fingerprint unlock

Fingerprint-first PAM files ignore a typed password until the reader times out,
so the lock screen gets its own, which checks the password first. Install it on
every machine, keeping the packaged file:

```bash
sudo cp /etc/pam.d/swaylock /etc/pam.d/swaylock.orig
sudo install -m 644 system/pam.d/swaylock /etc/pam.d/swaylock
```

On the lock screen, type the password, or press Enter on the empty field and
then touch the reader. With a reader, a wrong password waits for a fingerprint
for up to 15 seconds before showing the failure.

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
