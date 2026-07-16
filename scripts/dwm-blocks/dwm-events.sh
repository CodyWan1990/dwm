#!/bin/sh
# Event subscriptions for blocks that should update immediately.
set -u

signal_block() {
    sigdwmblocks "$1" >/dev/null 2>&1 || true
}

audio_events() (
    tmpdir=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/dwmblocks-audio.XXXXXX") || exit 1
    fifo=$tmpdir/events
    mkfifo "$fifo" || exit 1
    pactl subscribe > "$fifo" 2>/dev/null &
    subscriber=$!
    trap 'kill "$subscriber" 2>/dev/null || true; rm -rf "$tmpdir"' EXIT INT TERM HUP
    while IFS= read -r event; do
        case "$event" in
            *" on sink "*|*" on server "*|*" on card "*) signal_block 3 ;;
        esac
    done < "$fifo"
)

notification_events() (
    tmpdir=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/dwmblocks-dunst.XXXXXX") || exit 1
    fifo=$tmpdir/events
    mkfifo "$fifo" || exit 1
    dbus-monitor --session \
        "type='method_call',interface='org.freedesktop.Notifications'" \
        "type='signal',interface='org.freedesktop.Notifications'" \
        > "$fifo" 2>/dev/null &
    subscriber=$!
    trap 'kill "$subscriber" 2>/dev/null || true; rm -rf "$tmpdir"' EXIT INT TERM HUP
    while IFS= read -r event; do
        case "$event" in
            *interface=org.freedesktop.Notifications*member=*) signal_block 6 ;;
        esac
    done < "$fifo"
)

pids=
if command -v pactl >/dev/null 2>&1; then
    audio_events &
    pids="$pids $!"
fi
if command -v dbus-monitor >/dev/null 2>&1; then
    notification_events &
    pids="$pids $!"
fi

[ -n "$pids" ] || exit 0
trap 'for pid in $pids; do kill "$pid" 2>/dev/null || true; done; wait' EXIT INT TERM HUP
for pid in $pids; do
    wait "$pid" || true
done
