#!/bin/sh
# Status cell: this machine's LAN address on the default route, or nothing
# while offline

address=$(ip -4 route get 1.1.1.1 2> /dev/null \
  | awk '{ for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit } }')
[ -n "$address" ] || exit 0

printf '\363\260\226\237 %s\n' "$address" # md-web
