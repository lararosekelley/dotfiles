set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

python_paths := "content scripts tests"

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

# times an interactive shell sourcing the installed ~/.bashrc, then breaks one
# traced startup down by file and line (self time, so a `source` line excludes
# the file it loads)

profile runs="10":
  #!/usr/bin/env bash
  set -euo pipefail
  total=0
  for _ in $(seq {{runs}}); do
    start=$EPOCHREALTIME
    bash -i -c exit </dev/null >/dev/null 2>&1
    total=$(echo "$total + $EPOCHREALTIME - $start" | bc)
  done
  printf 'mean startup over %d runs: %.0f ms\n\n' {{runs}} "$(echo "$total * 1000 / {{runs}}" | bc -l)"
  trace=$(mktemp)
  trap 'rm -f "$trace"' EXIT
  bash --norc --noprofile -i -c '
    exec {fd}>"$1"
    BASH_XTRACEFD=$fd
    PS4="+ \${EPOCHREALTIME} \${BASH_SOURCE[0]:-}:\${LINENO} "
    set -x
    source ~/.bashrc
    set +x
  ' _ "$trace" </dev/null >/dev/null 2>&1
  awk -v home="$HOME" '
    $2 ~ /^[0-9]+\.[0-9]+$/ {
      t = $2
      if (prev != "") { d = t - pt; line[prev] += d; file[pf] += d }
      split($3, a, ":"); pf = a[1]; sub("^" home, "~", pf)
      prev = pf ":" a[2]; pt = t
      if (!(prev in cmd)) { c = $0; sub(/^[^ ]+ [^ ]+ [^ ]+ /, "", c); cmd[prev] = substr(c, 1, 60) }
      if (start == "") start = t
    }
    END {
      printf "traced startup: %.0f ms\n\nby file:\n", (pt - start) * 1000
      for (f in file) printf "%8.1f ms  %s\n", file[f] * 1000, f | "sort -rn | head -10"
      close("sort -rn | head -10")
      printf "\nslowest lines:\n"
      for (l in line) printf "%8.1f ms  %-40s %s\n", line[l] * 1000, l, cmd[l] | "sort -rn | head -15"
    }
  ' "$trace"

test: test-rust test-python test-node

test-rust:
    cargo test

test-python:
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/agent_awake -p 'test_*.py'

test-node:
    node --test tests/agent_awake/plugin.test.mjs
