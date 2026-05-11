#!/bin/sh
# Clipboard history picker via clipmenu, with theme colors.
# clipmenu passes any extra args straight through to the configured launcher
# (default: dmenu).
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

exec clipmenu \
    -i -c -l 10 -h 30 -bw 2 \
    -fn "Monofur Nerd Font Propo:size=14" \
    -nb "#${BG}"        -nf "#${FG}" \
    -sb "#${SELECTION}" -sf "#${BLUE}" \
    -nhb "#${BG}"       -nhf "#${YELLOW}" \
    -shb "#${SELECTION}" -shf "#${YELLOW}" \
    -p "Clipboard:" \
    "$@"
