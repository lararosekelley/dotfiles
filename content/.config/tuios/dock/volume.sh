#!/bin/sh
# tuios dock cell: default output volume from PipeWire

command -v wpctl > /dev/null 2>&1 || exit 0
reading=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2> /dev/null) || exit 0

# "Volume: 0.50" or "Volume: 0.50 [MUTED]"
percent=$(printf '%s\n' "$reading" | awk '{ printf "%d", $2 * 100 + 0.5 }')

case $reading in
  *MUTED*) icon='\363\260\226\201' ;; # md-volume-off
  *)
    if [ "$percent" -ge 60 ]; then
      icon='\363\260\225\276' # md-volume-high
    elif [ "$percent" -ge 25 ]; then
      icon='\363\260\226\200' # md-volume-medium
    else
      icon='\363\260\225\277' # md-volume-low
    fi
    ;;
esac

# shellcheck disable=SC2059 # the icon is an octal escape for printf
printf "$icon %s%%\n" "$percent"
