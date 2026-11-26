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

sh "$script" > "$cache.tmp" 2> /dev/null && mv "$cache.tmp" "$cache"
cat "$cache" 2> /dev/null
