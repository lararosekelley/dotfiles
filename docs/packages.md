# Packages

Where each installed program comes from and how to update it. Versions are left
out; ask the package manager.

## dnf

Most CLI tools and desktop apps come from Fedora and RPM Fusion. `dnf history list`
shows what was installed explicitly, as opposed to pulled in as a dependency.

Third-party repos in use:

| repo                      | provides                      |
| ------------------------- | ----------------------------- |
| `docker-ce-stable`        | Docker Engine and plugins     |
| `google-chrome`           | Chrome                        |
| `google-cloud-cli`        | `gcloud`                      |
| `protonvpn-fedora-stable` | Proton VPN                    |
| `tableplus`               | TablePlus                     |
| `copr:dejan/lazygit`      | `lazygit`                     |
| `rpmfusion-*`             | Steam, codecs, NVIDIA, akmods |

Some RPMs are installed from a downloaded file and have no repo, so `dnf upgrade`
never updates them. Download the new RPM and `dnf install ./file.rpm` it:

- Zoom, Proton Pass, Proton Mail Bridge, Plex Media Server
- Docker Desktop, GitKraken, balenaEtcher, AppImageLauncher
- Muse Sounds Manager, sfizz, AWS `session-manager-plugin`
- Morgen (installs to `/opt/Morgen`)

`kmod-v4l2loopback` is built locally by akmods for each kernel and needs no action.

```bash
sudo dnf upgrade
dnf list --installed | awk '$3 == "@commandline"'  # the file-installed RPMs above
```

## Flatpak

GUI apps, mostly from Flathub: Zen, Slack, Discord, Signal, Thunderbird, Obsidian,
Todoist, Calibre, Bitwig, Reaper, Ardour, FreeCAD, RetroArch, Bottles, GitHub
Desktop, ZAP, Steam ROM Manager.

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
firebase-tools, joplin-mcp-server, markdownlint-cli, neovim, pm2, yarn.

```bash
npm outdated -g
sudo npm update -g
```

`npm update -g` stays within the current major version; install `<pkg>@latest`
to cross one.

## Rust

The toolchain is `rustup`. Crates installed with `cargo install` (or
`cargo binstall`): cargo-binstall, cargo-dist, cargo-release, cargo-watch,
cargo-nextest, emacs-lsp-booster, ghzinga, git-cliff, just, rustlings, selene,
sqlx-cli, stylua, viu.

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

AppImages live in `~/Applications` (Joplin, MuseScore, Slippi) and are managed by
AppImageLauncher.
