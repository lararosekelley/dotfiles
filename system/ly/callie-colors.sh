#!/bin/sh
# Ly's start_cmd (see config.ini): load Callie's colors into the console's 16
# color slots before Ly draws. The kernel console can't show 24-bit color, so
# Ly runs in 16-color mode and its colors name these slots. Each bright slot
# repeats its normal one, so bold text keeps its color, except bright white,
# which bold text (and so the big clock) uses.
#
# slot  color   Ly's name   used for
# 0     1C1220  TB_BLACK    background
# 1     E66E6D  TB_RED      errors
# 2     3D2C42  TB_GREEN    plum, in the animation
# 3     E5AAC1  TB_YELLOW   light pink
# 4     F08FB8  TB_BLUE     pink, in the animation
# 5     9A8797  TB_MAGENTA  mauve
# 6     82CDCD  TB_CYAN     teal
# 7     E0D3DF  TB_WHITE    text
# 15    F6EEF5  TB_WHITE    bold text, such as the big clock

slot=0
for color in 1C1220 E66E6D 3D2C42 E5AAC1 F08FB8 9A8797 82CDCD E0D3DF; do
  printf '\033]P%x%s\033]P%x%s' "$slot" "$color" "$((slot + 8))" "$color"
  slot=$((slot + 1))
done
printf '\033]PfF6EEF5'
clear
