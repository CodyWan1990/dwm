#!/bin/sh
# Memory script for dwmblocks with status2d colors
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')

USED_GB=$(awk "BEGIN {printf \"%.1f\", ($TOTAL - $AVAILABLE) / 1024 / 1024}")
TOTAL_GB=$(awk "BEGIN {printf \"%.0f\", $TOTAL / 1024 / 1024}")
PERCENT=$(awk "BEGIN {printf \"%.0f\", (($TOTAL - $AVAILABLE) / $TOTAL) * 100}")

# Color based on usage
if [ "$PERCENT" -lt 50 ]; then
    color="#${GREEN}"
elif [ "$PERCENT" -lt 75 ]; then
    color="#${YELLOW}"
else
    color="#${RED}"
fi

printf "^c%s^🧠 %sG/%sG^d^" "$color" "$USED_GB" "$TOTAL_GB"
