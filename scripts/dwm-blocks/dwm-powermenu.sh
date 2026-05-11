#!/bin/sh
# Power menu icon for dwmblocks
# Just displays a static power icon - clicking calls the actual menu
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

printf "^c#%s^⚡^d^" "$RED"
