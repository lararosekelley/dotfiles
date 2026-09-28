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

`--dry-run` prints the `copy`, `symlink`, `remove`, `backup`, and `mkdir -p`
operations instead of performing them. Pair it with `--yes`; without it, sync
still asks about each file one at a time.

Justfile shortcuts:

```bash
just diff
just diff-to-repo
just sync-to-home-dry-run
just sync-to-repo-dry-run
```
