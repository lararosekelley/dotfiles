# Sync CLI

This repo includes a Rust-based CLI for syncing dotfiles with better status output
and optional symlink support:

```bash
cargo run -- sync to-home --symlink
cargo run -- sync to-repo --yes
cargo run -- status --direction to-repo
```

Justfile shortcuts:

```bash
just sync-to-home-symlink
just sync-to-repo
just status
```

## Settings ownership and integration installers

Normal sync treats each selected file as fully managed: accepting an update to
`.claude/settings.json` replaces the whole file, including local preferences and
hooks. Sync never merges structured settings. Decline that file, or exclude it,
when the home copy contains settings you want to retain:

```bash
cargo run -- sync to-home --exclude '.claude/settings.json'
python3 scripts/install-agent-awake.py
```

The checkout-only Agent Awake installer copies its runtime files and merges only
its hooks into live Claude settings, backing up replacements. It can be run from
any working directory using its full path. Runtime files belong in `content/`;
checkout installation tools belong in `scripts/` and are not synced to home.

## Payload selection

Both directions discover regular files under `content/`; syncing to the repository
does not discover new paths in home. The same selection policy applies to status,
copy, and symlink modes, independently of Git tracking or ignore files.

The CLI excludes Python bytecode/cache files, nested Git directories, `.gitkeep`,
nested `.gitignore` files, `.bak`/numbered backups, and OBS runtime/plugin state, logs, updates, and service credentials. The root
`content/.gitignore` is deliberately installed as `~/.gitignore`. Component READMEs
and runtime resources remain eligible. The policy is defined in `bin/fs.rs`.

`--only` narrows eligible paths and `--exclude` removes more; neither overrides
the payload exclusions. Excluded files already installed at home are left alone.
Empty directories represented only by `.gitkeep` are not created. This policy is
not a general secret detector; inspect any files you add to `content/`.

## Documentation boundary

Machine setup and operating guides live in `docs/` and are not installed. Files
under `content/` should be useful at their home destination. Agent skills keep
their runtime instructions in `SKILL.md` beside their code.

The sync policy deliberately permits component READMEs rather than excluding all
Markdown files. Move checkout-only guides to `docs/` instead of maintaining two
copies. `sync to-home --delete` removes copies already installed at home (see
[Removing deleted files](#removing-deleted-files)).

## Removing deleted files

Sync leaves home files alone when their source leaves `content/`, unless
`sync to-home` gets `--delete`:

```bash
cargo run -- sync to-home --delete --dry-run --yes  # list what would go
cargo run -- sync to-home --delete                  # ask about each file
```

Git history decides what counts: a home file is a candidate only if its path
was once tracked under `content/` and is gone now, whether deleted in a commit,
renamed, or deleted but not yet committed. Home files the repo never tracked,
paths excluded from the payload or by `--only`/`--exclude`, and files inside
another git checkout (a config that moved to a repo of its own) are never
candidates.

Each deletion is confirmed like a copy. A file edited since it left the repo is
flagged in the prompt, and `--yes` keeps it rather than deleting it. `--backup`
saves a `.bak` copy first.

## Previewing changes

Two ways to see what a sync would do, neither of which writes anything:

```bash
cargo run -- status --diff                 # per-file status plus a unified diff
cargo run -- sync to-home --dry-run --yes  # the exact actions sync would take
```

`status --diff` shows, for every file whose contents differ, a `diff -U3`-style
hunk of the destination's current contents against the incoming ones. Binary
files are reported as a size change rather than dumped, and files missing at the
destination are summarised by line count. Diffs are skipped under `--symlink`,
which never rewrites contents.

Diffs are coloured like git's — removals red, additions green, file headers
bold — when stdout is a terminal and `NO_COLOR` is unset. `--color` overrides
that:

```bash
cargo run -- status --diff --color=always | less -R  # keep colour through a pipe
cargo run -- status --diff --color=never             # plain output on a terminal
```

`--dry-run` prints the `copy`, `symlink`, `remove`, `delete`, `backup`, and `mkdir -p`
operations instead of performing them. Pair it with `--yes`; without it, sync
still asks about each file one at a time.

Justfile shortcuts:

```bash
just diff
just diff-to-repo
just sync-to-home-dry-run
just sync-to-repo-dry-run
```
