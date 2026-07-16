#!/bin/sh
# Called by dwm's applyscheme() after a colorscheme change.
# Argument: bash basename of the new scheme (e.g. "monokai", "tokyonight").
set -eu
SCHEME="${1:?usage: sync-colors.sh <basename>}"
SRC="$HOME/.config/suckless/scripts/colorschemes/$SCHEME.sh"
CACHE_DIR="$HOME/.cache/dwm-colorscheme"

[ -r "$SRC" ] || exit 1
mkdir -p "$CACHE_DIR"
cp "$SRC" "$CACHE_DIR/colors.sh"
printf '%s\n' "$SCHEME" > "$CACHE_DIR/current"

# Source the freshly-cached palette to read $FG, $BG, $BLUE, ... for OSC build.
# shellcheck disable=SC1091
. "$CACHE_DIR/colors.sh"

# Regenerate Dunst's square notification theme from the same palette. Keep
# terminal and status-bar recoloring functional if Dunst is unavailable.
DUNST_RENDERER=$(dirname "$0")/../dunst/render-dunstrc.sh
DUNST_CONFIG="$HOME/.config/dunst/dunstrc"
if [ -x "$DUNST_RENDERER" ] && "$DUNST_RENDERER" "$CACHE_DIR/colors.sh"; then
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl reload "$DUNST_CONFIG" >/dev/null 2>&1 || true
    fi
fi

# Build a precomputed OSC blob that any OSC-aware terminal (st, xterm, ...) will
# accept. New shells `cat` this on startup; sync writes it to live ptys below.
OSC_FILE="$CACHE_DIR/st-osc.txt"
{
    printf '\033]10;#%s\007' "$FG"
    printf '\033]11;#%s\007' "$BG"
    printf '\033]12;#%s\007' "$BLUE"
    printf '\033]4;0;#%s\007'  "$BG"
    printf '\033]4;1;#%s\007'  "$RED"
    printf '\033]4;2;#%s\007'  "$GREEN"
    printf '\033]4;3;#%s\007'  "$YELLOW"
    printf '\033]4;4;#%s\007'  "$BLUE"
    printf '\033]4;5;#%s\007'  "$MAUVE"
    printf '\033]4;6;#%s\007'  "$CYAN"
    printf '\033]4;7;#%s\007'  "$FG"
    printf '\033]4;8;#%s\007'  "$COMMENT"
    printf '\033]4;9;#%s\007'  "$RED"
    printf '\033]4;10;#%s\007' "$GREEN"
    printf '\033]4;11;#%s\007' "$YELLOW"
    printf '\033]4;12;#%s\007' "$BLUE"
    printf '\033]4;13;#%s\007' "$MAUVE"
    printf '\033]4;14;#%s\007' "$TEAL"
    printf '\033]4;15;#%s\007' "$LAVENDER"
} > "$OSC_FILE"

# Live-recolor every running st instance. Each st has a child shell whose stdin
# is /dev/pts/N; writing the OSC blob to that pts makes st render the palette
# change for that terminal (vim/tmux/less inherit the same pts).
for st_pid in $(pgrep -x st 2>/dev/null); do
    shell_pid=$(pgrep -P "$st_pid" 2>/dev/null | head -1)
    [ -n "$shell_pid" ] || continue
    pts=$(readlink "/proc/$shell_pid/fd/0" 2>/dev/null) || continue
    case "$pts" in
        /dev/pts/*)
            cat "$OSC_FILE" > "$pts" 2>/dev/null || true
            ;;
    esac
done

# Refresh every configured block on this display.
for sig in 1 2 3 4 5 6; do
    sigdwmblocks "$sig" >/dev/null 2>&1 || true
done
exit 0
