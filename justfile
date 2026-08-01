set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# python lives in content/ (the herdr default-session plugin)

python_paths := "content"

default:
  @just --list

build:
  cargo build

format-lint: format lint check

format: format-rust format-python

format-rust:
  cargo fmt

format-python:
  black {{python_paths}}

lint: lint-rust lint-python

lint-rust:
  cargo fmt --check
  cargo clippy --all-targets

lint-python:
  black --check --diff {{python_paths}}
  flake8 {{python_paths}}

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

sync-to-home:
  cargo run -- sync to-home

sync-to-home-symlink:
  cargo run -- sync to-home --symlink

sync-to-repo:
  cargo run -- sync to-repo

test:
  cargo test
