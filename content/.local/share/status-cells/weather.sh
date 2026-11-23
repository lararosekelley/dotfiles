#!/bin/sh
# Status cell: current conditions and temperature from wttr.in, located by
# IP. Prints nothing when offline.

report=$(curl -fsS -m 5 'https://wttr.in/?format=%x+%t' 2> /dev/null) || exit 0
symbol=${report%% *}
temp=${report#* }

# wttr.in's plain-text symbols to Nerd Font weather icons
case $symbol in
  *!*) icon='\363\260\226\223' ;;            # thunder
  x | x/ | '*/*') icon='\363\260\231\277' ;; # sleet
  *'*'*) icon='\363\260\226\230' ;;          # snow
  */* | .) icon='\363\260\226\227' ;;        # rain
  =) icon='\363\260\226\221' ;;              # fog
  o) icon='\363\260\226\231' ;;              # sunny
  m) icon='\363\260\226\225' ;;              # partly cloudy
  *) icon='\363\260\226\220' ;;              # cloudy
esac

# shellcheck disable=SC2059 # the icon is an octal escape for printf
printf "$icon %s\n" "${temp#+}"
