# Packages

Where each installed program comes from and how to update it, on the Fedora
desktop and the Arch laptop (see [Machines](../README.md#machines)). Versions are
left out; ask the package manager.

## Distro packages that config depends on

On CachyOS, always prefer the `cachyos-` prefixed package sources, for example
`cachyos-extras-znver4` over `extras`, as those are recompiled and
performance-optimized.

Config in `content/` depends on these. Names differ by distro; most are in
Fedora's repos and Arch's official repos, and the exceptions are noted. pyenv,
nodenv, and rbenv are git checkouts on both; see [New machine](./new-machine.md).

| used by                                            | Fedora (dnf)                     | Arch (pacman)                      |
| -------------------------------------------------- | -------------------------------- | ---------------------------------- |
| `.cargo/config.toml` links Rust builds             | `mold`                           | `mold`                             |
| `.config/fish/` and its plugins                    | `fish fzf fd-find bat`           | `fish fzf fd bat`                  |
| the `copy` script                                  | `wl-clipboard` or `xclip`        | `wl-clipboard` or `xclip`          |
| `.config/k9s/` (see [Kubernetes](./kubernetes.md)) | `k9s kubernetes1.34-client helm` | `k9s kubectl helm`                 |
| `.azure/`                                          | `azure-cli`                      | `azure-cli`                        |
| `.bin/backup.sh`                                   | `restic`                         | `restic`                           |
| the `recollindex` override                         | `recoll perl-JSON`               | `recoll perl-json`                 |
| `.config/obs-studio/`                              | `obs-studio`                     | `obs-studio`                       |
| the Headlamp Callie theme's font                   | `vernnobile-nunito-fonts`        | none known; install Nunito by hand |

## Fedora: dnf

Most CLI tools and desktop apps come from Fedora and RPM Fusion. `dnf history list`
shows what was installed explicitly, as opposed to pulled in as a dependency.

Third-party repos in use:

| repo                      | provides                      |
| ------------------------- | ----------------------------- |
| `docker-ce-stable`        | Docker Engine and plugins     |
| `Dropbox`                 | Dropbox (`nautilus-dropbox`)  |
| `google-chrome`           | Chrome                        |
| `google-cloud-cli`        | `gcloud`                      |
| `greylocklabs`            | Callie and Jot                |
| `protonvpn-fedora-stable` | Proton VPN                    |
| `tableplus`               | TablePlus                     |
| `copr:dejan/lazygit`      | `lazygit`                     |
| `rpmfusion-*`             | Steam, codecs, NVIDIA, akmods |
| `home:justkidding`        | `ueberzugpp`                  |

Some RPMs are installed from a downloaded file and have no repo, so `dnf upgrade`
never updates them. Download the new RPM and `dnf install ./file.rpm` it:

- Zoom, Proton Pass, Proton Mail Bridge, Plex Media Server
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

GUI apps, mostly from Flathub: Zen, Slack, Discord, Signal, Thunderbird, Obsidian,
Todoist, Calibre, Reaper, Ardour, RetroArch, GitHub Desktop, Headlamp.

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

## AppImages

AppImages live in `~/Applications`: MuseScore, Slippi, and the Craft suite
(artcraft-launcher, cadcraft, deckcraft, designcraft, effectcraft, figcraft,
filmcraft, gridcraft, lightcraft, pdfcraft, photocraft, soundcraft, vectorcraft,
wordcraft).

[AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher), installed
from its RPM above, integrates them: opening an AppImage offers to move it to
`~/Applications` and add a menu entry. Its `ail-cli` does the same from a
terminal. Update an AppImage by downloading the new release and integrating it.

```bash
ail-cli integrate ~/Downloads/<app>.AppImage
ail-cli unintegrate ~/Applications/<app>.AppImage  # before deleting one
```
