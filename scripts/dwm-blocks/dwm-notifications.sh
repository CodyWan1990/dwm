#!/bin/sh
# Dunst notification count and do-not-disturb state for dwmblocks.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

paused=$(dunstctl is-paused 2>/dev/null) || {
    printf "^c#%s^🔔^d^" "$COMMENT"
    exit 0
}

history=$(dunstctl count history 2>/dev/null) || history=0
displayed=$(dunstctl count displayed 2>/dev/null) || displayed=0
waiting=$(dunstctl count waiting 2>/dev/null) || waiting=0

case "$history" in *[!0-9]*|'') history=0 ;; esac
case "$displayed" in *[!0-9]*|'') displayed=0 ;; esac
case "$waiting" in *[!0-9]*|'') waiting=0 ;; esac

count=$((history + displayed + waiting))
if [ "$count" -gt 0 ]; then
    label=" $count"
else
    label=
fi

if [ "$paused" = true ]; then
    printf "^c#%s^🔕%s^d^" "$COMMENT" "$label"
else
    printf "^c#%s^🔔%s^d^" "$YELLOW" "$label"
fi
