# Packages

Where each installed program comes from and how to update it, on the Fedora
desktop and the Arch laptops (see [Machines](../README.md#machines)). Versions are
left out; ask the package manager.

## Distro packages that config depends on

On CachyOS, always prefer the `cachyos-` prefixed package sources, for example
`cachyos-extras-znver4` over `extras`, as those are recompiled and
performance-optimized.

Config in `home/` depends on the packages in
[`scripts/setup/packages.txt`](../scripts/setup/packages.txt), which gives each
one's Fedora and Arch name, or a fallback such as `pipx install` where a distro
has none. `chezmoi apply` installs whatever is missing through
`scripts/setup/packages`, asking first. On Arch it installs with
`pacman -Syu`, which also brings the system up to date. Two fonts are left to
install by hand: Nunito on Arch, and IosevkaTerm Nerd Font on Fedora. pyenv, nodenv, and rbenv are git checkouts on
both; see
[New machine](./new-machine.md).

## Fedora: dnf

Most CLI tools and desktop apps come from Fedora and RPM Fusion. `dnf history list`
shows what was installed explicitly, as opposed to pulled in as a dependency.

The apps from outside the distro's own repos are listed in
[`scripts/setup/apps.txt`](../scripts/setup/apps.txt), with their Fedora and Arch
sources, plus [`apps-desktop.txt`](../scripts/setup/apps-desktop.txt) (Jellyfin) for
the desktop only. `chezmoi apply` installs whatever is missing through
`scripts/setup/apps`, asking first; on Arch it builds AUR packages with paru.
Callie and Jot are left out, as is everything machine-specific below
(NVIDIA, akmods, `ueberzugpp`).

Third-party repos in use:

| repo                      | provides                      |
| ------------------------- | ----------------------------- |
| `docker-ce-stable`        | Docker Engine and plugins     |
| `Dropbox`                 | Dropbox (`nautilus-dropbox`)  |
| `google-chrome`           | Chrome                        |
| `google-cloud-cli`        | `gcloud`                      |
| `greylocklabs`            | Callie and Jot                |
| `protonvpn-fedora-stable` | Proton VPN                    |
| `rpmfusion-*`             | Steam, codecs, NVIDIA, akmods |
| `home:justkidding`        | `ueberzugpp`                  |

Some RPMs are installed from a downloaded file and have no repo, so `dnf upgrade`
never updates them. Download the new RPM and `dnf install ./file.rpm` it:

- Zoom, Proton Pass, Proton Mail Bridge
- Docker Desktop, GitKraken, balenaEtcher, AppImageLauncher
- Muse Sounds Manager, sfizz, AWS `session-manager-plugin`

Callie and Jot install with their own `install.sh` scripts, which add the
`greylocklabs` repo. An install script may leave its RPM marked as from a file,
but `dnf upgrade` still updates it from the repo.

`kmod-v4l2loopback` is built locally by akmods for each kernel and needs no action.

```bash
sudo dnf upgrade
dnf list --installed | awk '$3 == "@commandline"'  # the file-installed RPMs above
```

## Flatpak

GUI apps, listed in
[`scripts/setup/flatpaks.txt`](../scripts/setup/flatpaks.txt) and installed per
user (`flatpak --user`) by `scripts/setup/flatpaks` on `chezmoi apply`. Most
come from Flathub; ArtCraft and its Craft apps come from ArtCraft's own
`artcraft-oci` remote (see [getartcraft.com/linux](https://getartcraft.com/linux)).
Apps already installed system-wide, as on the desktop, are left there.

```bash
flatpak update
flatpak uninstall --unused
```

## Snap

Only `ngrok`. Discover skips the snap backend (see
[Discover (KDE) backends](./kde-discover.md)), so update from the CLI:

```bash
sudo snap refresh
```

## Python

Interpreters come from `pyenv`. The `neovim3` and `neovim2` virtualenvs provide
Neovim's Python providers; Neovim uses each only if it exists.

Isolated CLI tools are installed with `pipx`: black, flake8, gcalcli, glances,
konsave, litecli, poetry, sqlfluff, vale. `aider` is installed with `uv tool`.

```bash
pipx upgrade-all
uv tool upgrade --all
```

## Node

Interpreters come from `nodenv`, with the global set to `system` (Fedora's
`nodejs`). Global packages install to `/usr/local/lib`: eask, prettierd,
mermaid-cli, linear-cli, graphite-cli, ccusage, diff-so-fancy, eslint,
firebase-tools, markdownlint-cli, neovim, pm2, yarn.

```bash
npm outdated -g
sudo npm update -g
```

`npm update -g` stays within the current major version; install `<pkg>@latest`
to cross one.

## Rust

The toolchain is `rustup`. Crates installed with `cargo install` (or
`cargo binstall`): cargo-binstall, cargo-dist, cargo-release, cargo-watch,
cargo-nextest, emacs-lsp-booster, git-cliff, just, rustlings, selene, sqlx-cli,
stylua, viu.

```bash
rustup update
cargo install --list
cargo binstall -y <crate>  # reinstalls at the latest version
```

## Go

`GOPATH` is `~/.go`; binaries land in `~/.go/bin`: gopls, tea, gophish.

```bash
go install golang.org/x/tools/gopls@latest
```

## Self-updating and standalone binaries

These install outside a package manager and update themselves or by re-downloading:

| binary                                     | location         | update                   |
| ------------------------------------------ | ---------------- | ------------------------ |
| `claude`                                   | `~/.local/bin`   | updates itself           |
| `codegraph`                                | `~/.local/bin`   | `codegraph upgrade`      |
| `cliamp` (Fedora; AUR on Arch)             | `~/.local/bin`   | `cliamp upgrade`         |
| `herdr`, `navi`, `tuicr`, `git-stk`        | `~/.local/bin`   | re-download a release    |
| `yt-dlp`                                   | `~/.local/bin`   | `yt-dlp -U`              |
| `uv`                                       | `~/.local/bin`   | `uv self update`         |
| `aws`                                      | `/usr/local/bin` | re-run the AWS installer |
| `circleci`, `ollama`, `railway`, `mailpit` | `/usr/local/bin` | re-run each installer    |
| `terraform`                                | `~/.bin`         | re-download a release    |
| `k3d`                                      | `/usr/local/bin` | re-run the k3d installer |
| `krew` and its `ctx`, `ns`, `stern`        | `~/.krew/bin`    | `kubectl krew upgrade`   |

`gh` extensions: dlvhdr/gh-dash and dlvhdr/gh-enhance, for herdr's `github` tab.

```bash
gh extension install dlvhdr/gh-dash
gh extension install dlvhdr/gh-enhance
gh extension upgrade --all
```
