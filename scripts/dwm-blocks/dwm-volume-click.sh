#!/bin/sh
# Volume click handler for dwmblocks

case "${1:-}" in
    1) # Left click - toggle mute
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-mute @DEFAULT_SINK@ toggle
        fi
        ;;
    2) # Middle click - open mixer
        command -v pavucontrol >/dev/null 2>&1 && pavucontrol &
        ;;
    3) # Right click - open pavucontrol
        command -v pavucontrol >/dev/null 2>&1 && pavucontrol &
        ;;
    4) # Scroll up - volume up
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ +5%
        fi
        ;;
    5) # Scroll down - volume down
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ -5%
        fi
        ;;
esac

# Signal dwmblocks to update volume block
sigdwmblocks 3 >/dev/null 2>&1 || true
