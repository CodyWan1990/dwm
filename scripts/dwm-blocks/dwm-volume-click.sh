#!/bin/sh
echo "$(date +%T) button=$1" >> /tmp/dwm-volume.log
# Volume click handler for dwmblocks

case "$1" in
    1) # Left click - toggle mute
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    2) # Middle click - open mixer
        pavucontrol &
        ;;
    3) # Right click - open pavucontrol
        pavucontrol &
        ;;
    4) # Scroll up - volume up
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    5) # Scroll down - volume down
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
esac

# Signal dwmblocks to update volume block
sigdwmblocks 3
