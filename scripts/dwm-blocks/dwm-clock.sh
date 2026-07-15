#!/bin/sh
# Clock script for dwmblocks with status2d colors
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

DAY=$(date '+%A')
DATE=$(date '+%B %e, %Y')
TIME=$(date '+%I:%M %p')

printf "^c#%s^📅 %s  %s^d^  ^c#%s^🕐 %s^d^" \
    "$BLUE" "$DAY" "$DATE" \
    "$BLUE" "$TIME"
