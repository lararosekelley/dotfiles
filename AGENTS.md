# Dotfiles

## Boundaries

- `home/` is the chezmoi source for the home directory: `.config` is
  `dot_config`, executables start with `executable_`, and private files with
  `private_`. `.chezmoiroot` points chezmoi at it.
- `system/` holds configuration requiring separate system-level installation.
- `scripts/` holds checkout-only installers; `docs/` holds operating/setup guides.
  `scripts/setup/` holds the setup steps `chezmoi apply` runs through the
  `run_onchange_after_*` wrappers in `home/`.
- Agent Awake, KDE installer, chezmoi source, setup script, and `~/.bin` script
  tests live under `tests/`.
- Global agent rules live in `home/dot_config/opencode/AGENTS.md`;
  `home/dot_claude/CLAUDE.md` imports them. Edit the canonical file.

## Sync behavior

chezmoi installs files from `home/` in full; it does not merge settings.
`home/.chezmoiignore` leaves out caches, and the KDE settings on machines that
answered no at `chezmoi init`. A file removed from `home/` stays installed until
it is listed in `home/.chezmoiremove`.

Do not run `chezmoi apply` merely to test a change. Use `chezmoi diff`, or a
temporary destination (`chezmoi apply --destination <dir>`) with its own
`--persistent-state`. Keep credentials, generated state, caches, and private
handoff notes out of `home/`.

## Checks

Run commands from the repository root:

- `just test`: Python and Node suites.
- `just test-python`, `just test-node`: focused suites.
- `just lint`: Python formatting/lint, JavaScript formatting/lint (oxfmt,
  oxlint), shell formatting/lint (shfmt, shellcheck), fish syntax and formatting,
  and Markdown lint.

CI runs the same lint and test recipes, plus commitlint, on pushes to `main` and
on pull requests.

For changes to what chezmoi installs, check `chezmoi managed` and `chezmoi diff`.
Setup scripts must be safe to rerun on a partly set-up machine: check before
acting, never delete or overwrite, ask before `sudo`, support `--dry-run`, and
come with a test in `tests/setup/` that runs them twice.
For integration installers, verify unrelated live settings are preserved using a temporary home.
Docs-only edits need applicable formatting and link checks, not the full test suite.

Commits require a lowercase `type(scope): description` subject. Valid scopes are
listed in `commitlint.config.cjs`. Run hooks normally; do not bypass them.
Husky takes any argument to `npx husky` as a hooks directory and repoints
`core.hooksPath` there; never run it with `--help`, `--version`, or other flags.
