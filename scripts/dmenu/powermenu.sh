#!/bin/sh
# Themed dwm power menu — Logout / Reboot / Shutdown.
# Bound to Ctrl+Alt+Delete in dwm config.

choice=$(printf 'Cancel\nLogout\nReboot\nShutdown\n' | \
    "$HOME/.config/suckless/scripts/dmenu/dmenu-pick.sh" -p 'Power:')

case "$choice" in
    Logout)
        # Tell dwm to quit. Its cleanup() unmanages every client (sending
        # WM_DELETE_WINDOW so apps close gracefully). dwm-session.sh's
        # `exec dwm` then returns, SDDM tears down X, and any leftover
        # session-scoped daemons are reaped with the X server.
        pkill -TERM dwm
        # Belt-and-suspenders: if dwm doesn't exit within ~3 s (a stuck
        # client refusing WM_DELETE can wedge cleanup), force it.
        ( sleep 3; pgrep -x dwm >/dev/null && pkill -KILL dwm ) &
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    *)
        # Cancel / empty selection / Esc: no-op
        exit 0
        ;;
esac
