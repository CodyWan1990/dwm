#!/bin/sh
# Memory script for dwmblocks with status2d colors
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

set -- $(awk '
    $1 == "MemTotal:" { total = $2 }
    $1 == "MemAvailable:" { available = $2 }
    END {
        if (total > 0)
            printf "%.1f %.0f %.0f\n", (total - available) / 1048576,
                   total / 1048576, ((total - available) / total) * 100
    }
' /proc/meminfo)
[ "$#" -eq 3 ] || exit 0
used_gb=$1
total_gb=$2
percent=$3

# Color based on usage
if [ "$percent" -lt 50 ]; then
    color="#${CYAN}"
elif [ "$percent" -lt 75 ]; then
    color="#${YELLOW}"
else
    color="#${RED}"
fi

printf "^c%s^🧠 %sG/%sG^d^" "$color" "$used_gb" "$total_gb"
