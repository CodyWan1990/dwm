#!/bin/sh
# Themed raw dmenu picker — reads stdin, writes selection to stdout.
# Used as the underlying picker for apps/clipmenu/dfm wrappers.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

exec /usr/local/bin/dmenu \
    -i -c -l 10 -h 30 -bw 2 \
    -fn "Monofur Nerd Font Propo:size=14" \
    -nb "#${BG}"        -nf "#${FG}" \
    -sb "#${SELECTION}" -sf "#${BLUE}" \
    -nhb "#${BG}"       -nhf "#${YELLOW}" \
    -shb "#${SELECTION}" -shf "#${YELLOW}" \
    -hb "#${BG}"        -hf "#${MAUVE}" \
    "$@"
