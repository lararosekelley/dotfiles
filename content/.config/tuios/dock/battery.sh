#!/bin/sh
# tuios dock cell: battery charge, or nothing on a machine without a battery

for battery in /sys/class/power_supply/BAT*; do
  [ -r "$battery/capacity" ] || continue
  level=$(cat "$battery/capacity")
  status=$(cat "$battery/status" 2> /dev/null)

  if [ "$status" = Charging ]; then
    icon='\363\260\202\204' # md-battery-charging
  elif [ "$level" -ge 90 ]; then
    icon='\363\260\201\271' # md-battery
  elif [ "$level" -ge 60 ]; then
    icon='\363\260\201\277' # md-battery-70
  elif [ "$level" -ge 30 ]; then
    icon='\363\260\201\274' # md-battery-40
  else
    icon='\363\260\201\272' # md-battery-10
  fi

  # shellcheck disable=SC2059 # the icon is an octal escape for printf
  printf "$icon %s%%\n" "$level"
  exit 0
done
