#!/bin/sh
# Status cell: the track cliamp is playing, or nothing while it is not.
# Long names drop the artist, then get cut, so the bar keeps its other cells.

command -v cliamp > /dev/null 2>&1 || exit 0

cliamp status --json 2> /dev/null | jq -r --argjson max "${NOW_PLAYING_MAX:-24}" '
  def fit: if length > $max then .[:$max - 1] + "…" else . end;
  def present: select(. != null and . != "");

  select(.state == "playing" and .track != null)
  | .track
  | ([.artist, .title] | map(present) | join(" - ")) as $full
  | (if (.stream_title // "") != "" then .stream_title
     elif ($full | length) <= $max then $full
     else (.title // $full)
     end)
  | present
  | "󰝚 " + fit
'
