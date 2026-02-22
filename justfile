set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  @just --list

build:
  cargo build

format-lint: format lint check

format:
  cargo fmt

lint:
  cargo fmt --check
  cargo clippy --all-targets

check:
  cargo check

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
