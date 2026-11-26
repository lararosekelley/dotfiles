#!/bin/sh
# Run a status cell at most once per SECONDS, printing its last output in
# between, for status lines that re-run commands on every refresh.
#
# Usage: cached.sh SECONDS SCRIPT

ttl=$1
script=$2
dir="${XDG_RUNTIME_DIR:-/tmp}/status-cells"
cache="$dir/$(basename "$script").out"

mkdir -p "$dir" 2> /dev/null

if [ -f "$cache" ]; then
  age=$(($(date +%s) - $(stat -c %Y "$cache")))
  if [ "$age" -lt "$ttl" ]; then
    cat "$cache"
    exit 0
  fi
fi

if sh "$script" > "$cache.tmp" 2> /dev/null && [ -s "$cache.tmp" ]; then
  mv "$cache.tmp" "$cache"
else
  # A failed or empty run (offline, say) keeps the last result, and is tried
  # again in a minute rather than after the full SECONDS.
  rm -f "$cache.tmp"
  [ -f "$cache" ] || : > "$cache"
  retry=$(($(date +%s) - ttl + 60))
  touch -d "@$retry" "$cache"
fi
cat "$cache" 2> /dev/null
