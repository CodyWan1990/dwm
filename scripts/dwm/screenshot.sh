#!/bin/sh
set -eu

screenshots_dir="$HOME/Pictures/Screenshots"
dmenu_pick="$HOME/.config/suckless/scripts/dmenu/dmenu-pick.sh"
tmp_file=$(mktemp "${TMPDIR:-/tmp}/dwm-screenshot.XXXXXX.png")

cleanup() {
    rm -f "$tmp_file"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

# A cancelled region selection is not an error worth notifying about.
maim -s "$tmp_file" || exit 0

action=$(printf '%s\n' 'Copy' 'Save' 'Copy & Save' | \
    "$dmenu_pick" -p 'Screenshot:') || exit 0

copy_screenshot() {
    xclip -selection clipboard -t image/png < "$tmp_file"
}

resolve_save_path() {
    name=$(printf '' | "$dmenu_pick" -p 'Filename:') || return 1
    name=$(printf '%s' "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$name" ] || name=$(date '+%B-%d-%Y-%I-%M-%S-%p')

    # This prompt accepts a filename, not a path. Turn separators into dashes so
    # input cannot escape the screenshots directory.
    name=$(printf '%s' "$name" | tr '/\\' '--')
    case "$name" in
        *.png) ;;
        *) name="${name}.png" ;;
    esac

    mkdir -p "$screenshots_dir"
    save_path="$screenshots_dir/$name"
    if [ -e "$save_path" ]; then
        stem=${name%.png}
        suffix=2
        while [ -e "$screenshots_dir/${stem}-${suffix}.png" ]; do
            suffix=$((suffix + 1))
        done
        name="${stem}-${suffix}.png"
        save_path="$screenshots_dir/$name"
    fi
}

case "$action" in
    Copy)
        if copy_screenshot; then
            notify-send 'Screenshot' 'Copied to clipboard'
        else
            notify-send -u critical 'Screenshot' 'Failed to copy to clipboard'
            exit 1
        fi
        ;;
    Save)
        resolve_save_path || exit 0
        if cp "$tmp_file" "$save_path"; then
            notify-send 'Screenshot' "Saved as $name"
        else
            notify-send -u critical 'Screenshot' 'Failed to save screenshot'
            exit 1
        fi
        ;;
    'Copy & Save')
        resolve_save_path || exit 0
        if copy_screenshot && cp "$tmp_file" "$save_path"; then
            notify-send 'Screenshot' "Copied & saved as $name"
        else
            notify-send -u critical 'Screenshot' 'Failed to copy and save screenshot'
            exit 1
        fi
        ;;
    *)
        exit 0
        ;;
esac
