# Formatting and linting

`just format` and `just lint` cover everything in the repo; `just format-lint`
runs both plus `cargo check`. The per-language recipes are
`format-rust`/`lint-rust` (rustfmt, clippy), `format-python`/`lint-python`
(black, flake8), and `format-markdown`/`lint-markdown` (markdownlint-cli2, whose
globs are passed on the command line rather than read from
`.markdownlint-cli2.yaml`).

`just lint` also runs as a `pre-commit` hook, so a commit fails rather than
landing unformatted. The companion `commit-msg` hook runs commitlint. Both live
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
and its Node plugin tests. Run a single language with `just test-rust`,
`just test-python`, or `just test-node`. These require Rust, Python 3, and Node;
the Python and Node suites use their standard-library test runners.

Python tests disable bytecode writes, including in their subprocesses, so imported
runtime helpers do not leave caches in the sync payload. Add any new test suite
to these recipes. The pre-commit hook runs linting; run `just test` separately
before committing behavioral changes.
