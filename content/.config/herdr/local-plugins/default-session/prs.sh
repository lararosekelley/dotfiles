#!/usr/bin/env bash
#
# Open ghzinga on something useful for the repo in the current directory.
#
# ghzinga picks a restore session from anchors it saved earlier — herdr pane ids
# score "strong" while cwd and git remote only score "weak" — so a bare launch
# happily reopens another repo's PR. Naming the session after the repo pins it
# instead, and an explicit resource gives it a sensible cold start:
#
#   1. the PR for the branch that is checked out
#   2. failing that, the most recently updated open PR
#   3. failing that, whatever was last watched in this repo

set -uo pipefail

if ! command -v ghzinga &> /dev/null; then
  echo "fatal: ghzinga must be installed"
  exit 1
fi

remote="$(git config --get remote.origin.url 2> /dev/null)"

if [[ -z "$remote" ]]; then
  echo "fatal: no origin remote, so there is no repo to watch"
  exit 1
fi

# git@host:owner/repo.git and https://host/owner/repo both reduce to owner/repo
slug="$(sed -E 's#^(git@|ssh://git@|https://)##; s#^[^:/]+[:/]##; s#\.git$##' <<< "$remote")"
session="${slug//\//-}"

number=""

if command -v gh &> /dev/null; then
  number="$(gh pr view --json number --jq .number 2> /dev/null)"

  if [[ -z "$number" ]]; then
    number="$(gh pr list --limit 1 --json number --jq '.[0].number' 2> /dev/null)"
  fi
fi

if [[ -n "$number" ]]; then
  echo "watching $slug#$number"
  exec ghzinga --session "$session" "$number"
fi

echo "no open pull requests in $slug; restoring the last thing watched here"
exec ghzinga --session "$session"
