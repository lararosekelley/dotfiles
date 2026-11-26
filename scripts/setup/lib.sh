# shellcheck shell=bash
#
# Shared by the scripts in scripts/setup: --dry-run, logging, and cloning a repo
# only where nothing is in the way. Sourced, not run.
#
# Each script calls parse_args "$@" first and finish last. A warning means
# something was skipped and left as it was; a failure makes finish exit 1, so
# chezmoi reports it and runs the script again on the next apply.

dry_run=false
yes=false
warnings=0
failures=0

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -n | --dry-run) dry_run=true ;;
      -y | --yes) yes=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "unknown option: $arg" >&2
        exit 2
        ;;
    esac
  done
}

say() { printf '%s\n' "$*"; }

warn() {
  printf 'warning: %s\n' "$*" >&2
  warnings=$((warnings + 1))
}

# Run a command, or print it under --dry-run. A failure is counted, not fatal.
run() {
  if $dry_run; then
    say "  would run: $*"
    return 0
  fi
  "$@" && return 0
  printf 'failed: %s\n' "$*" >&2
  failures=$((failures + 1))
  return 1
}

# Ask before something that needs sudo or changes the desktop. Without a
# terminal, and without --yes, the answer is no.
confirm() {
  $yes && return 0
  $dry_run && return 0
  [ -t 0 ] || return 1
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

# fedora, arch, or unknown, from os-release (SETUP_OS_RELEASE overrides the path
# for tests)
detect_distro() {
  local file=${SETUP_OS_RELEASE:-/etc/os-release} ID="" ID_LIKE=""
  if [ ! -r "$file" ]; then
    echo unknown
    return
  fi
  # shellcheck source=/dev/null
  . "$file"
  case " $ID $ID_LIKE " in
    *" fedora "*) echo fedora ;;
    *" arch "*) echo arch ;;
    *) echo unknown ;;
  esac
}

# github.com/owner/repo, whichever of https://, git@...:, or .git it is written with
normalize_remote() {
  local url=${1%.git}
  url=${url#https://}
  url=${url#http://}
  url=${url#ssh://}
  url=${url#git@}
  url=${url/://}
  printf '%s\n' "${url,,}"
}

# Clone url into dest, unless dest already exists. An existing checkout of the
# same repo is left as it is; anything else at dest is left alone with a warning.
# Returns non-zero unless dest ends up as that checkout (or would, under
# --dry-run), so anything that goes inside it can be skipped.
clone_repo() {
  local url=$1 dest=$2 top remote
  if [ ! -e "$dest" ]; then
    run git clone --quiet "$url" "$dest" || return 1
    $dry_run || say "cloned $url into $dest"
    return 0
  fi
  top=$(git -C "$dest" rev-parse --show-toplevel 2> /dev/null)
  if [ "$top" != "$(cd "$dest" && pwd -P)" ]; then
    warn "$dest exists but is not a git checkout; left alone (expected $url)"
    return 1
  fi
  # the configured URL, not get-url, which expands insteadOf rewrites
  remote=$(git -C "$dest" config --get remote.origin.url)
  if [ "$(normalize_remote "$remote")" != "$(normalize_remote "$url")" ]; then
    warn "$dest is a checkout of ${remote:-a repo without an origin}, not $url; left alone"
    return 1
  fi
  say "present: $dest"
}

finish() {
  if [ "$failures" -gt 0 ]; then
    say "$failures step(s) failed; fix them and run this again"
    exit 1
  fi
  [ "$warnings" -gt 0 ] && say "$warnings item(s) skipped; see the warnings above"
  exit 0
}
