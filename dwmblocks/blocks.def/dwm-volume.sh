#!/bin/sh
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
MUTED=$(echo "$VOL" | grep -c MUTED)
PCT=$(echo "$VOL" | awk '{print int($2*100)}')

if [ "$MUTED" -eq 1 ]; then
    printf "\x0bVOL\x0c MUTE"
else
    printf "\x0bVOL\x0c %s%%" "$PCT"
fi
