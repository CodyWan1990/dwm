#!/bin/sh
CHOICE=$(printf "Shutdown\nReboot\nLogout" | rofi -dmenu -p "Power")

case "$CHOICE" in
    Shutdown) shutdown -h now ;;
    Reboot)   reboot ;;
    Logout)   pkill dwm ;;
esac
