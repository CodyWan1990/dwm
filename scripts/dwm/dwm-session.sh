#!/bin/sh

# Dual-head 1440p@120. Set each head sequentially (primary first) — never a single
# dual-head call. The past hard-freeze was the login-manager DRM-master collision
# (plasmalogin's Wayland greeter still holding the GPU when Xorg started), not this
# modeset; launch dwm via startx from a clean TTY, not through plasmalogin.
xrandr --output DP-1 --mode 2560x1440 --rate 120 --primary
xrandr --output DP-2 --mode 2560x1440 --rate 120 --right-of DP-1

xset r rate 200 35

# Disable screen blanking and DPMS (display power management).
xset s off         # Disable screensaver timeout
xset s noblank     # Don't blank the video device
xset -dpms         # Disable DPMS (Energy Star) power-down

export QT_QPA_PLATFORMTHEME=kde

sxhkd &
# polkit agent path differs by distro (Arch vs Debian) — start the first that exists.
for p in /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
         /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
         /usr/libexec/polkit-gnome-authentication-agent-1 \
         /usr/libexec/polkit-mate-authentication-agent-1; do
    [ -x "$p" ] && { "$p" & break; }
done
picom &
nitrogen --restore &
dunst &
dwmblocks &
clipmenud &
exec dwm
