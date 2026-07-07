#!/bin/sh

xrandr --output DP-1 --mode 2560x1440 --rate 120 --primary --output DP-2 --mode 2560x1440 --rate 120 --right-of DP-1

xset r rate 200 35

# Disable screen blanking and DPMS (display power management).
xset s off         # Disable screensaver timeout
xset s noblank     # Don't blank the video device
xset -dpms         # Disable DPMS (Energy Star) power-down

sxhkd &
# polkit agent path differs by distro (Arch vs Debian) — start the first that exists.
for p in /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
         /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
         /usr/libexec/polkit-gnome-authentication-agent-1; do
    [ -x "$p" ] && { "$p" & break; }
done
picom &
nitrogen --restore &
dwmblocks &
clipmenud &
exec dwm
