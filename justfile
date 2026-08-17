set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# python lives in content/ (the herdr default-session plugin)

python_paths := "content"

# markdownlint-cli2 takes its globs on the command line, not from its config,
# so quote this to keep bash from expanding it first

markdown_paths := "**/*.md"

default:
  @just --list

build:
  cargo build

format-lint: format lint check

format: format-rust format-python format-markdown

format-rust:
  cargo fmt

format-python:
  black {{python_paths}}

format-markdown:
  npx --no -- markdownlint-cli2 --fix "{{markdown_paths}}"

lint: lint-rust lint-python lint-markdown

lint-rust:
  cargo fmt --check
  cargo clippy --all-targets

lint-python:
  black --check --diff {{python_paths}}
  flake8 {{python_paths}}

lint-markdown:
  npx --no -- markdownlint-cli2 "{{markdown_paths}}"

check:
  cargo check

# black and flake8 are expected on PATH; pipx keeps them out of any project venv

install-python-tools:
  pipx install black
  pipx install flake8

run *args:
  cargo run -- {{args}}

status:
  cargo run -- status

# same as status, plus a unified diff of every file whose contents differ

diff:
  cargo run -- status --diff

diff-to-repo:
  cargo run -- status --direction to-repo --diff

sync-to-home:
  cargo run -- sync to-home

sync-to-home-symlink:
  cargo run -- sync to-home --symlink

sync-to-repo:
  cargo run -- sync to-repo

# --yes is needed for a non-interactive preview, otherwise each file prompts

sync-to-home-dry-run:
  cargo run -- sync to-home --dry-run --yes

sync-to-repo-dry-run:
  cargo run -- sync to-repo --dry-run --yes

test:
  cargo test
