#!/bin/sh
# Volume script for dwmblocks with status2d colors
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

if command -v wpctl >/dev/null 2>&1; then
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}')
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -c MUTED)
elif command -v pactl >/dev/null 2>&1; then
    VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\d+(?=%)' | head -1)
    MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -c yes)
else
    printf "^c#%s^🔇 N/A^d^" "$COMMENT"
    exit 0
fi

if [ "$MUTED" -eq 1 ] || [ -z "$VOL" ]; then
    printf "^c#%s^🔇 MUTE^d^" "$COMMENT"
elif [ "$VOL" -gt 100 ]; then
    printf "^c#%s^🔊 %s%%^d^" "$RED" "$VOL"
elif [ "$VOL" -gt 50 ]; then
    printf "^c#%s^🔊 %s%%^d^" "$MAUVE" "$VOL"
else
    printf "^c#%s^🔉 %s%%^d^" "$MAUVE" "$VOL"
fi
