# Dotfiles

## Boundaries

- `content/` mirrors paths under home and contains the installed payload.
- `system/` holds configuration requiring separate system-level installation.
- `scripts/` holds checkout-only installers; `docs/` holds operating/setup guides.
- `bin/` is the Rust sync CLI. Rust integration tests and Agent Awake tests live
  under `tests/`.
- Global agent rules live in `content/.config/opencode/AGENTS.md`;
  `content/.claude/CLAUDE.md` imports them. Edit the canonical file.

## Sync behavior

Sync replaces selected files in full; it does not merge settings or delete stale
home files. Both directions discover paths from `content/`, using the exclusions
in `bin/fs.rs`. Git ignore rules do not define the sync payload.

Do not run a live home sync merely to test a change. Use temporary repo/home
fixtures or `cargo run -- sync to-home --dry-run --yes`. Keep credentials,
generated state, caches, and private handoff notes out of `content/`.

## Checks

Run commands from the repository root:

- `just test`: Rust, Python, and Node suites.
- `just test-rust`, `just test-python`, `just test-node`: focused suites.
- `just lint`: Rust formatting/Clippy, Python formatting/lint, and Markdown lint.

For sync changes, cover both directions and file selection. For integration
installers, verify unrelated live settings are preserved using a temporary home.
Docs-only edits need applicable formatting and link checks, not the full test suite.

Commits require a lowercase `type(scope): description` subject. Valid scopes are
listed in `commitlint.config.cjs`. Run hooks normally; do not bypass them.
