# Formatting and linting

`just format` and `just lint` cover everything in the repo; `just format-lint`
runs both plus `cargo check`. The per-language recipes are
`format-rust`/`lint-rust` (rustfmt, clippy), `format-python`/`lint-python`
(black, flake8), `format-js`/`lint-js` (oxfmt, oxlint), `format-shell`/`lint-shell`
(shfmt, shellcheck), and `format-markdown`/`lint-markdown` (markdownlint-cli2, whose
globs are passed on the command line rather than read from
`.markdownlint-cli2.yaml`).

oxfmt is limited to JavaScript files, since it would otherwise also reformat the
JSON, YAML and Markdown configs synced from `content/`; its settings are in
`.oxfmtrc.json`. shfmt and shellcheck cover `*.sh` files and the shell dotfiles
listed in the `justfile`. shfmt reads its settings from `.editorconfig`, and
shellcheck from `.shellcheckrc`. `content/.git_prompt` is
git's own `git-prompt.sh` and is left as upstream wrote it.

`just lint` also runs as a `pre-commit` hook, so a commit fails rather than
landing unformatted. GitHub Actions (`.github/workflows/checks.yml`) runs the
lint and test recipes on pushes to `main` and on pull requests, and runs
commitlint over the pushed or proposed commits. `just lint-commits` does the
same locally, from `origin/main` to `HEAD` by default. The companion `commit-msg` hook runs commitlint. Both live
in `.husky/` and are installed by `npm install` (via the `prepare` script).

Python targets include `content/`, `scripts/`, and `tests/`. [black](https://black.readthedocs.io) owns formatting and
[flake8](https://flake8.pycqa.org) catches the rest; their settings live in
`pyproject.toml` and `.flake8`, with flake8's line length matched to black's 88.
Install the tools once with:

```bash
just install-python-tools
```

## Tests

`just test` runs all suites: Rust unit/integration tests, Agent Awake Python tests,
and the Node tests for the Agent Awake plugin and the IG Plus extension. Run a single language with `just test-rust`,
`just test-python`, or `just test-node`. These require Rust, Python 3, and Node;
the Python and Node suites use their standard-library test runners.

Python tests disable bytecode writes, including in their subprocesses, so imported
runtime helpers do not leave caches in the sync payload. Add any new test suite
to these recipes. The pre-commit hook runs linting; run `just test` separately
before committing behavioral changes.
