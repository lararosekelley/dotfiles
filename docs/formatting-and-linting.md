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

Python here means the scripts under `content/`. [black](https://black.readthedocs.io) owns formatting and
[flake8](https://flake8.pycqa.org) catches the rest; their settings live in
`pyproject.toml` and `.flake8`, with flake8's line length matched to black's 88.
Install the tools once with:

```bash
just install-python-tools
```
