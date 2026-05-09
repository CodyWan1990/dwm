#!/bin/sh
BAT=$(ls /sys/class/power_supply/ | grep -m1 "^BAT")
[ -z "$BAT" ] && exit 0
CAPACITY=$(cat /sys/class/power_supply/$BAT/capacity)
STATUS=$(cat /sys/class/power_supply/$BAT/status)

if [ "$STATUS" = "Charging" ]; then
    printf "\x0bBAT\x0c %s%% +" "$CAPACITY"
elif [ "$STATUS" = "Full" ]; then
    printf "\x0bBAT\x0c FULL"
else
    printf "\x0bBAT\x0c %s%%" "$CAPACITY"
fi
