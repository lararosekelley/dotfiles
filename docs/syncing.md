# Syncing

[chezmoi](https://www.chezmoi.io) installs `home/` into the home directory.
`.chezmoiroot` points it at `home/`, so the repo's own files (docs, scripts,
tests) are never installed.

## Setup

```bash
chezmoi init --source ~/Code/personal/dotfiles
```

`init` writes chezmoi's config from `home/.chezmoi.toml.tmpl` and asks two
questions once per machine: whether to install the KDE settings (yes by default
in a KDE session), and the machine's name for per-machine settings (`framework`,
`thinkpad`, or `desktop`; the hostname by default). Rerun `init` to answer a
question added later.

## Everyday commands

```bash
chezmoi diff                 # what apply would change
chezmoi apply --interactive  # install, asking about each file
chezmoi re-add               # copy edits made at home back into home/
chezmoi add ~/.config/foo    # start tracking a new file
chezmoi cd                   # open a shell in the repo
```

chezmoi remembers what it last installed, so `apply` asks before overwriting a
file that changed at home since.

## Setup scripts

`chezmoi apply` also runs the scripts in `scripts/setup/`, through the
`run_onchange_after_*` wrappers in `home/`. A wrapper includes a checksum of its
script, so chezmoi runs it on a machine's first apply and again whenever the
script changes. Each script checks before it acts: it leaves anything already in
place alone, never deletes, warns about what it skips, and accepts `--dry-run`
to show its plan. They can be run by hand too:

| Script | What it does |
| --- | --- |
| `scripts/setup/version-managers` | clones pyenv, nodenv, and rbenv with their build plugins |
| `scripts/setup/config-repos` | clones nvim, emacs.d, kitty, herdr, and tuios, then runs nvim's `install-deps` and installs herdr's Claude hook |
| `scripts/setup/packages` | installs the missing packages in `scripts/setup/packages.txt`, asking before `sudo` |
| `scripts/setup/flatpaks` | installs the missing apps in `scripts/setup/flatpaks.txt` for your user, adding their remotes |
| `scripts/setup/apps` | installs the missing apps in `scripts/setup/apps.txt` from vendor repos and RPMs, the AUR, or their own install scripts, asking first |
| `scripts/setup/services` | enables the units in `scripts/setup/services.txt`, asking before `sudo` |

## Names

Source names encode how a file is installed: `dot_config/` becomes `.config/`,
`executable_copy` an executable `copy`, and a `private_` prefix makes a file
`600` or a directory `700`. `chezmoi add` picks these names, so prefer it to
creating files in `home/` by hand.

## What is installed

`home/.chezmoiignore` leaves out Python caches and, on machines that answered no
at `init`, the KDE settings (`kwinrulesrc`, `powerdevilrc`, and the Discover
launcher). Names in `home/` that start with `.`, such as `.gitkeep`, are never
installed. None of this is a secret detector; inspect any file you add.

Deleting a file from `home/` leaves the installed copy in place. List it in
`home/.chezmoiremove`, creating the file if needed, and the next `apply`
removes it.

## Settings ownership and integration installers

chezmoi treats each file as fully managed: accepting an update to
`.claude/settings.json` replaces the whole file, including local preferences and
hooks. Decline that file in `chezmoi apply --interactive` when the home copy has
settings you want to keep, then run the Agent Awake installer:

```bash
python3 scripts/install-agent-awake.py
```

It copies its runtime files and merges only its hooks into live Claude settings,
backing up anything it replaces. It runs from any working directory. Runtime
files belong in `home/`; checkout-only tools belong in `scripts/` and are never
installed.

## Documentation boundary

Machine setup and operating guides live in `docs/` and are not installed. Files
under `home/` should be useful at their installed location. Agent skills keep
their runtime instructions in `SKILL.md` beside their code.
