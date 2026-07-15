#!/bin/sh
# Mouse actions for the Dunst notification block.
set -u

dmenu_pick="$HOME/.config/suckless/scripts/dmenu/dmenu-pick.sh"

refresh() {
    sigdwmblocks 6 >/dev/null 2>&1 || true
}

show_history() {
    history_file=$(mktemp "${TMPDIR:-/tmp}/dwm-notifications-history.XXXXXX") || return 1
    entries_file=$(mktemp "${TMPDIR:-/tmp}/dwm-notifications-entries.XXXXXX") || {
        rm -f "$history_file"
        return 1
    }
    ids_file=$(mktemp "${TMPDIR:-/tmp}/dwm-notifications-ids.XXXXXX") || {
        rm -f "$history_file" "$entries_file"
        return 1
    }

    if ! dunstctl history > "$history_file" 2>/dev/null; then
        rm -f "$history_file" "$entries_file" "$ids_file"
        return 1
    fi

    if ! jq -r '
        .data[0][]? |
        [
            (.id.data | tostring),
            ((.appname.data // "Unknown") | tostring | gsub("[\\t\\r\\n]"; " ")),
            ((.summary.data // .body.data // "(no summary)") | tostring | gsub("[\\t\\r\\n]"; " "))
        ] | @tsv
    ' "$history_file" | awk -F '\t' -v ids="$ids_file" '
        {
            print $1 >> ids
            printf "%d. %s — %s\n", NR, $2, $3
        }
    ' > "$entries_file"; then
        rm -f "$history_file" "$entries_file" "$ids_file"
        return 1
    fi

    if [ ! -s "$entries_file" ]; then
        rm -f "$history_file" "$entries_file" "$ids_file"
        return 0
    fi

    choice=$("$dmenu_pick" -p 'Notifications:' < "$entries_file") || choice=
    index=${choice%%.*}
    case "$index" in
        *[!0-9]*|'') id= ;;
        *) id=$(sed -n "${index}p" "$ids_file") ;;
    esac
    case "$id" in
        *[!0-9]*|'') ;;
        *) dunstctl history-pop "$id" >/dev/null 2>&1 || true ;;
    esac

    rm -f "$history_file" "$entries_file" "$ids_file"
}

case "${1:-}" in
    1)
        show_history
        ;;
    2)
        dunstctl set-paused toggle >/dev/null 2>&1 || true
        ;;
    3)
        choice=$(printf '%s\n' 'Cancel' 'Clear' | \
            "$dmenu_pick" -p 'Clear notification history?') || choice=
        [ "$choice" = Clear ] && dunstctl history-clear >/dev/null 2>&1 || true
        ;;
    *)
        exit 0
        ;;
esac

refresh
