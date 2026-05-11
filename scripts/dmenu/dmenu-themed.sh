#!/bin/sh
# Themed dmenu_run — colors from the dwm colorscheme cache.
# Invoked by dwm's dmenucmd on Mod+Shift+Space.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

exec dmenu_run \
    -i \
    -c \
    -l 10 \
    -h 30 \
    -bw 2 \
    -fn "Monofur Nerd Font Propo:size=14" \
    -nb "#${BG}"        \
    -nf "#${FG}"        \
    -sb "#${SELECTION}" \
    -sf "#${BLUE}"      \
    -nhb "#${BG}"       \
    -nhf "#${YELLOW}"   \
    -shb "#${SELECTION}" \
    -shf "#${YELLOW}"   \
    -hb "#${BG}"        \
    -hf "#${MAUVE}"     \
    "$@"
