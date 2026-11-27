set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

python_paths := "home scripts tests"

# markdownlint-cli2 takes its globs on the command line, not from its config,
# so quote this to keep bash from expanding it first

markdown_paths := "**/*.md"

# oxfmt also formats JSON, YAML and Markdown, so keep it to JavaScript; synced
# configs in home/ keep their own style

js_paths := "**/*.{js,mjs,cjs}"

# shell dotfiles have no .sh extension, so they are listed here; dot_git_prompt
# is git's own git-prompt.sh, and dot_inputrc is readline config

shell_paths := "home/dot_aliases home/dot_bash_profile home/dot_bash_prompt home/dot_bashrc home/dot_exports home/dot_functions $(git ls-files 'home/dot_bin/*' 'scripts/setup/*' ':!:*.sh' ':!:*.txt' ':!:home/dot_bin/executable_sf2-to-sfz' ':!:home/dot_bin/executable_hardware') home/private_dot_ssh/modify_private_config system/fans-full"

default:
  @just --list

format-lint: format lint

format: format-python format-js format-shell format-fish format-markdown

format-python:
  black {{python_paths}}

format-js:
  npx --no -- oxfmt "{{js_paths}}"

# shfmt reads its settings from .editorconfig

format-shell:
  shfmt -w {{shell_paths}} $(git ls-files '*.sh')

format-fish:
  fish_indent -w $(git ls-files '*.fish')

format-markdown:
  npx --no -- markdownlint-cli2 --fix "{{markdown_paths}}"

lint: lint-python lint-js lint-shell lint-fish lint-markdown

lint-python:
  black --check --diff {{python_paths}}
  flake8 {{python_paths}}

lint-js:
  npx --no -- oxfmt --check "{{js_paths}}"
  npx --no -- oxlint

lint-shell:
  shfmt -d {{shell_paths}} $(git ls-files '*.sh')
  shellcheck {{shell_paths}} $(git ls-files '*.sh')

lint-fish:
  for f in $(git ls-files '*.fish'); do fish --no-execute "$f"; done
  fish_indent --check $(git ls-files '*.fish')

# checks commit messages in a range, as CI does for a push or pull request

lint-commits from="origin/main" to="HEAD":
  npx --no -- commitlint --from {{from}} --to {{to}} --verbose

lint-markdown:
  npx --no -- markdownlint-cli2 "{{markdown_paths}}"

# black and flake8 are expected on PATH; pipx keeps them out of any project venv

install-python-tools:
  pipx install black
  pipx install flake8

# pass --dry-run to preview, or --layout to also replace every panel

kde-apply *args:
  python3 scripts/install-kde.py apply {{args}}

# pass --dry-run to print the layout diff without saving

kde-capture *args:
  python3 scripts/install-kde.py capture {{args}}

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

test: test-python test-node

test-python:
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/agent_awake -p 'test_*.py'
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/kde -p 'test_*.py'
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/chezmoi -p 'test_*.py'
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/setup -p 'test_*.py'
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/bin -p 'test_*.py'
    PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/system -p 'test_*.py'

test-node:
    node --test tests/agent_awake/plugin.test.mjs
