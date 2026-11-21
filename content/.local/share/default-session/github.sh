#!/usr/bin/env bash
#
# Open gh-dash on the repo in the current directory. Launched inside a checkout,
# its smart filtering scopes every section to that repo; see
# ~/.config/gh-dash/config.yml for the sections and the gh-enhance keybinding.

set -uo pipefail

if ! command -v gh &> /dev/null; then
  echo "fatal: gh must be installed"
  exit 1
fi

if ! gh extension list 2> /dev/null | grep -q 'dlvhdr/gh-dash'; then
  echo "fatal: gh-dash must be installed: gh extension install dlvhdr/gh-dash"
  exit 1
fi

if [[ -z "$(git config --get remote.origin.url 2> /dev/null)" ]]; then
  echo "fatal: no origin remote, so there is no repo to show"
  exit 1
fi

exec gh dash
