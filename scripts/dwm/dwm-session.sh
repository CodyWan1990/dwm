#!/bin/sh

# Display layout. The old one-shot dual-head 1440p@120 modeset in a single legacy
# xrandr call wedged amdgpu (dcn32_program_compbuf_size REG_WAIT timeout, hard freeze
# on Navi 32). Both monitors DO support the modes — the trigger is reprogramming both
# heads at once via X's legacy RandR path. Fix: set each head sequentially, primary
# first, and let X's atomic-KMS startup bring them up before we touch anything.
# X output names under the modesetting driver may be DisplayPort-0/-1, not DP-1/DP-2 —
# run `xrandr` once inside dwm and correct these if the mode-set is a no-op.
#
# Start conservative (60Hz) for the first successful entry; bump to 120 once stable.
xrandr --output DP-1 --mode 2560x1440 --rate 60 --primary
xrandr --output DP-2 --mode 2560x1440 --rate 60 --right-of DP-1
# Once confirmed stable, raise refresh (still one head at a time, never a single dual call):
#   xrandr --output DP-1 --mode 2560x1440 --rate 120 --primary
#   xrandr --output DP-2 --mode 2560x1440 --rate 120 --right-of DP-1

xset r rate 200 35

# Disable screen blanking and DPMS (display power management).
xset s off         # Disable screensaver timeout
xset s noblank     # Don't blank the video device
xset -dpms         # Disable DPMS (Energy Star) power-down

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
dwmblocks &
clipmenud &
exec dwm
