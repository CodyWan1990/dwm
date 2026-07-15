#!/bin/sh
# Apps-only launcher (.desktop entries, including flatpaks via XDG_DATA_DIRS).
# Uses j4-dmenu-desktop as the scanner/executor and decorates its labels with
# themed application icons before passing them to our dmenu picker.
# (We previously used i3-dmenu-desktop, which spawns apps via i3-msg and
# silently fails on dwm — j4 forks/execs the chosen app directly.)
exec j4-dmenu-desktop \
    --dmenu="$HOME/.config/suckless/scripts/dmenu/dmenu-app-icons.sh -p 'Apps:'" \
    --no-generic \
    --usage-log="$HOME/.cache/j4-dmenu-history" \
    "$@"
