#!/bin/sh
# Volume script for dwmblocks with status2d colors
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/.config/suckless/scripts/colorschemes/monokai.sh"

if command -v wpctl >/dev/null 2>&1; then
    state=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || state=
    volume=$(printf '%s\n' "$state" | awk '{print int($2 * 100)}')
    case "$state" in *MUTED*) muted=1 ;; *) muted=0 ;; esac
elif command -v pactl >/dev/null 2>&1; then
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null |
        awk 'match($0, /[0-9]+%/) { value = substr($0, RSTART, RLENGTH - 1); print value; exit }')
    case $(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null) in
        *yes) muted=1 ;;
        *) muted=0 ;;
    esac
else
    printf "^c#%s^🔇 N/A^d^" "$COMMENT"
    exit 0
fi

case "$volume" in *[!0-9]*|'') volume= ;; esac
if [ "$muted" -eq 1 ] || [ -z "$volume" ]; then
    printf "^c#%s^🔇 MUTE^d^" "$COMMENT"
elif [ "$volume" -gt 100 ]; then
    printf "^c#%s^🔊 %s%%^d^" "$RED" "$volume"
elif [ "$volume" -gt 50 ]; then
    printf "^c#%s^🔊 %s%%^d^" "$MAUVE" "$volume"
else
    printf "^c#%s^🔉 %s%%^d^" "$MAUVE" "$volume"
fi
