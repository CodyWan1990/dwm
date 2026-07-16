#!/bin/sh
# Only a left click opens the power menu.
[ "${1:-}" = 1 ] || exit 0
exec "$HOME/.config/suckless/scripts/dmenu/powermenu.sh"
