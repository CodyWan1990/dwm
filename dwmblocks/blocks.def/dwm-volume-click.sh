#!/bin/sh
case "$1" in
    1) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    4) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    5) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
esac
sigdwmblocks 3
