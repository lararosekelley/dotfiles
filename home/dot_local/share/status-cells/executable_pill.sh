#!/bin/sh
# Draw a status cell as a rounded tmux pill, or nothing while the cell is empty
#
# Usage: pill.sh BG FG SCRIPT

bg=$1
fg=$2
text=$(sh "$3" 2> /dev/null)
[ -n "$text" ] || exit 0

printf '#[fg=%s]\356\202\266#[bg=%s]#[fg=%s]#[bold] %s #[nobold]#[bg=default]#[fg=%s]\356\202\264\n' \
  "$bg" "$bg" "$fg" "$text" "$bg"
