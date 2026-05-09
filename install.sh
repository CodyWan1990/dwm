#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────
#   Suckless dwm desktop installer for Arch Linux
#   Bootstraps: pacman deps → ~/scripts/* → fish/bash hooks → session entry
#               → builds & installs dmenu, st, dwm, dwmblocks, dfm,
#                 clipmenu, FT-Labs-picom from this directory.
#
#   Usage:    cd ~/Projects/Suckless && ./install.sh
#   Re-run:   safe; idempotent.
# ─────────────────────────────────────────────────────────────────────────
set -eu

# ───────────── helpers ─────────────
if [ -t 1 ]; then
    C_BLUE='\033[1;34m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
    C_RED='\033[1;31m';  C_MAGENTA='\033[1;35m'; C_DIM='\033[2m'; C_OFF='\033[0m'
else
    C_BLUE=; C_GREEN=; C_YELLOW=; C_RED=; C_MAGENTA=; C_DIM=; C_OFF=
fi

section() { printf '\n%b═══ %s ═══%b\n' "$C_MAGENTA" "$*" "$C_OFF"; }
info()    { printf '  %b➜%b %s\n' "$C_BLUE"   "$C_OFF" "$*"; }
ok()      { printf '  %b✓%b %s\n' "$C_GREEN"  "$C_OFF" "$*"; }
warn()    { printf '  %b!%b %s\n' "$C_YELLOW" "$C_OFF" "$*"; }
err()     { printf '  %b✗%b %s\n' "$C_RED"    "$C_OFF" "$*" >&2; }

LOG=/tmp/suckless-install.log
: > "$LOG"

# ───────────── 0. preflight ─────────────
section "Preflight"
[ -f /etc/arch-release ] || { err "This installer is for Arch Linux."; exit 1; }
[ "$(id -u)" -ne 0 ]    || { err "Run as your normal user, not root (it'll sudo when needed)."; exit 1; }
command -v sudo >/dev/null   || { err "sudo is required."; exit 1; }
SRCDIR="$(cd "$(dirname "$0")" && pwd)"
ok "Source dir: $SRCDIR"
ok "User: $USER  Home: $HOME"
ok "Build log: $LOG"

# ───────────── 1. pacman dependencies ─────────────
section "Installing pacman packages"
PKGS="
base-devel git make meson ninja pkgconf cmake
libx11 libxinerama libxft libxrender libxres libxext libxcomposite
libxdamage libxfixes libxrandr libxxf86vm libxcb xcb-util
xcb-util-renderutil xcb-util-image xorgproto libdrm
freetype2 fontconfig pixman mesa pcre2 libev libconfig dbus uthash
spdlog fmt
xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot
xorg-xprop xorg-xkill
xdotool xclip xdg-utils
sxhkd polkit-gnome feh dunst
curl jq pacman-contrib lm_sensors libpulse wireplumber
j4-dmenu-desktop perl
fish
"
info "Updating package databases & installing dependencies"
if sudo pacman -S --needed --noconfirm $PKGS >>"$LOG" 2>&1; then
    ok "All pacman packages present"
else
    err "pacman install failed — see $LOG"; exit 1
fi

# ───────────── 2. ~/scripts/ tree ─────────────
section "Generating ~/scripts/* and theming files"
mkdir -p "$HOME/scripts/dmenu" \
         "$HOME/scripts/dwm-blocks" \
         "$HOME/scripts/dwm" \
         "$HOME/scripts/theming/colorschemes" \
         "$HOME/.cache/dwm-colorscheme" \
         "$HOME/.config/fish/conf.d"

# ── dmenu wrappers ──
cat > "$HOME/scripts/dmenu/dmenu-themed.sh" <<'_END_'
#!/bin/sh
# Themed dmenu_run — colors from the dwm colorscheme cache.
# Invoked by dwm's dmenucmd on Mod+Alt+Space.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"

exec dmenu_run \
    -i -c -l 10 -h 30 -bw 2 \
    -fn "Monofur Nerd Font Propo:size=14" \
    -nb "#${BG}"        -nf "#${FG}" \
    -sb "#${SELECTION}" -sf "#${BLUE}" \
    -nhb "#${BG}"       -nhf "#${YELLOW}" \
    -shb "#${SELECTION}" -shf "#${YELLOW}" \
    -hb "#${BG}"        -hf "#${MAUVE}" \
    "$@"
_END_

cat > "$HOME/scripts/dmenu/dmenu-pick.sh" <<'_END_'
#!/bin/sh
# Themed raw dmenu picker — reads stdin, writes selection to stdout.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"

exec /usr/local/bin/dmenu \
    -i -c -l 10 -h 30 -bw 2 \
    -fn "Monofur Nerd Font Propo:size=14" \
    -nb "#${BG}"        -nf "#${FG}" \
    -sb "#${SELECTION}" -sf "#${BLUE}" \
    -nhb "#${BG}"       -nhf "#${YELLOW}" \
    -shb "#${SELECTION}" -shf "#${YELLOW}" \
    -hb "#${BG}"        -hf "#${MAUVE}" \
    "$@"
_END_

cat > "$HOME/scripts/dmenu/dmenu-apps.sh" <<'_END_'
#!/bin/sh
# Apps-only launcher (.desktop entries, including flatpaks via XDG_DATA_DIRS).
# Uses j4-dmenu-desktop as the scanner and our themed dmenu as the picker.
exec j4-dmenu-desktop \
    --dmenu="$HOME/scripts/dmenu/dmenu-pick.sh -p 'Apps:'" \
    --no-generic \
    --usage-log="$HOME/.cache/j4-dmenu-history" \
    "$@"
_END_

cat > "$HOME/scripts/dmenu/clipmenu-themed.sh" <<'_END_'
#!/bin/sh
# Clipboard history picker via clipmenu, themed.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"

exec clipmenu \
    -i -c -l 10 -h 30 -bw 2 \
    -fn "Monofur Nerd Font Propo:size=14" \
    -nb "#${BG}"        -nf "#${FG}" \
    -sb "#${SELECTION}" -sf "#${BLUE}" \
    -nhb "#${BG}"       -nhf "#${YELLOW}" \
    -shb "#${SELECTION}" -shf "#${YELLOW}" \
    -p "Clipboard:" \
    "$@"
_END_

# Different outer terminator: dfm-themed.sh contains a literal `EOF` heredoc.
cat > "$HOME/scripts/dmenu/dfm-themed.sh" <<'_DFM_END_'
#!/bin/sh
# Run DFM with our themed dmenu as its picker via a PATH shim.
SHIM="$(mktemp -d -t dmenu-shim.XXXXXX)"
trap 'rm -rf "$SHIM"' EXIT INT TERM

cat > "$SHIM/dmenu" <<EOF
#!/bin/sh
exec "$HOME/scripts/dmenu/dmenu-pick.sh" "\$@"
EOF
chmod +x "$SHIM/dmenu"

PATH="$SHIM:$PATH" exec dfm "$@"
_DFM_END_

cat > "$HOME/scripts/dmenu/powermenu.sh" <<'_END_'
#!/bin/sh
# Themed dwm power menu — Logout / Reboot / Shutdown.
# Bound to Ctrl+Alt+Delete in dwm config.

choice=$(printf 'Cancel\nLogout\nReboot\nShutdown\n' | \
    "$HOME/scripts/dmenu/dmenu-pick.sh" -p 'Power:')

case "$choice" in
    Logout)
        # Tell dwm to quit; cleanup() unmanages every client (WM_DELETE_WINDOW),
        # dwm-session.sh's `exec dwm` returns, SDDM tears down X.
        pkill -TERM dwm
        ( sleep 3; pgrep -x dwm >/dev/null && pkill -KILL dwm ) &
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
_END_

ok "Wrote 6 dmenu wrappers"

# ── dwm-blocks status scripts ──
cat > "$HOME/scripts/dwm-blocks/sync-colors.sh" <<'_END_'
#!/bin/sh
# Called by dwm's applyscheme() after a colorscheme change.
# Argument: bash basename of the new scheme (e.g. "monokai", "tokyonight").
set -eu
SCHEME="${1:?usage: sync-colors.sh <basename>}"
SRC="$HOME/scripts/theming/colorschemes/$SCHEME.sh"
CACHE_DIR="$HOME/.cache/dwm-colorscheme"

[ -r "$SRC" ] || exit 1
mkdir -p "$CACHE_DIR"
cp "$SRC" "$CACHE_DIR/colors.sh"
printf '%s\n' "$SCHEME" > "$CACHE_DIR/current"

# shellcheck disable=SC1091
. "$CACHE_DIR/colors.sh"

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

# Live-recolor every running st instance via OSC bytes.
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

# Refresh every dwmblocks block.
for sig in 1 2 3 4 5 6 7 8 9; do
    pkill -RTMIN+"$sig" dwmblocks 2>/dev/null || true
done
exit 0
_END_

cat > "$HOME/scripts/dwm-blocks/dwm-clock.sh" <<'_END_'
#!/bin/sh
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"

DAY=$(date '+%A')
DATE=$(date '+%B %e, %Y')
TIME=$(date '+%I:%M %p')

printf "^c#%s^📅 %s  %s^d^  ^c#%s^🕐 %s^d^" \
    "$BLUE" "$DAY" "$DATE" "$YELLOW" "$TIME"
_END_

cat > "$HOME/scripts/dwm-blocks/dwm-memory.sh" <<'_END_'
#!/bin/sh
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"

TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
USED_GB=$(awk "BEGIN {printf \"%.1f\", ($TOTAL - $AVAILABLE) / 1024 / 1024}")
TOTAL_GB=$(awk "BEGIN {printf \"%.0f\", $TOTAL / 1024 / 1024}")
PERCENT=$(awk "BEGIN {printf \"%.0f\", (($TOTAL - $AVAILABLE) / $TOTAL) * 100}")

if [ "$PERCENT" -lt 50 ]; then color="#${GREEN}"
elif [ "$PERCENT" -lt 75 ]; then color="#${YELLOW}"
else color="#${RED}"; fi

printf "^c%s^🧠 %sG/%sG^d^" "$color" "$USED_GB" "$TOTAL_GB"
_END_

cat > "$HOME/scripts/dwm-blocks/dwm-volume.sh" <<'_END_'
#!/bin/sh
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"

if command -v wpctl >/dev/null 2>&1; then
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}')
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -c MUTED)
elif command -v pactl >/dev/null 2>&1; then
    VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\d+(?=%)' | head -1)
    MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -c yes)
else
    printf "^c#%s^🔇 N/A^d^" "$COMMENT"; exit 0
fi

if [ "$MUTED" -eq 1 ] || [ -z "$VOL" ]; then
    printf "^c#%s^🔇 MUTE^d^" "$COMMENT"
elif [ "$VOL" -gt 100 ]; then
    printf "^c#%s^🔊 %s%%^d^" "$RED" "$VOL"
elif [ "$VOL" -gt 50 ]; then
    printf "^c#%s^🔊 %s%%^d^" "$MAUVE" "$VOL"
else
    printf "^c#%s^🔉 %s%%^d^" "$BLUE" "$VOL"
fi
_END_

cat > "$HOME/scripts/dwm-blocks/dwm-powermenu.sh" <<'_END_'
#!/bin/sh
# Static power icon for the bar — clicking fires the powermenu wrapper.
# shellcheck disable=SC1090,SC1091
. "$HOME/.cache/dwm-colorscheme/colors.sh" 2>/dev/null \
  || . "$HOME/scripts/theming/colorschemes/monokai.sh"
printf "^c#%s^⚡^d^" "$RED"
_END_

# ── click handlers ──
cat > "$HOME/scripts/dwm-blocks/dwm-volume-click.sh" <<'_END_'
#!/bin/sh
# Volume click handler.  $1 = button (1=L 2=M 3=R 4=scrollUp 5=scrollDown)
case "$1" in
    1) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    2|3) pavucontrol & ;;
    4) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    5) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
esac
command -v sigdwmblocks >/dev/null 2>&1 && sigdwmblocks 3
_END_

ok "Wrote sync-colors + 4 block scripts (memory/volume/clock/powermenu) + 1 click handler (volume)"

# ── 11 colorscheme palette files ──
cat > "$HOME/scripts/theming/colorschemes/monokai.sh" <<'_END_'
SCHEME_NAME="Monokai Pro"
BG="2d2a2e"
FG="fcfcfa"
COMMENT="727072"
SELECTION="403e41"
RED="ff6188"
ORANGE="fc9867"
YELLOW="ffd866"
GREEN="a9dc76"
CYAN="78dce8"
BLUE="78dce8"
MAUVE="ab9df2"
TEAL="78dce8"
MAROON="ff6188"
LAVENDER="ab9df2"
BG_ALPHA="ee"
ACTIVE_BORDER="ab9df2ff"
INACTIVE_BORDER="403e41ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/gruvbox.sh" <<'_END_'
SCHEME_NAME="Gruvbox"
BG="282828"
FG="ebdbb2"
COMMENT="928374"
SELECTION="3c3836"
RED="fb4934"
ORANGE="fe8019"
YELLOW="fabd2f"
GREEN="b8bb26"
CYAN="8ec07c"
BLUE="83a598"
MAUVE="d3869b"
TEAL="689d6a"
MAROON="cc241d"
LAVENDER="b16286"
BG_ALPHA="ee"
ACTIVE_BORDER="83a598ff"
INACTIVE_BORDER="3c3836ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/catppuccin-mocha.sh" <<'_END_'
SCHEME_NAME="Catppuccin Mocha"
BG="1e1e2e"
FG="cdd6f4"
COMMENT="6c7086"
SELECTION="313244"
RED="f38ba8"
ORANGE="fab387"
YELLOW="f9e2af"
GREEN="a6e3a1"
CYAN="89dceb"
BLUE="89b4fa"
MAUVE="cba6f7"
TEAL="94e2d5"
MAROON="eba0ac"
LAVENDER="b4befe"
BG_ALPHA="ee"
ACTIVE_BORDER="89b4faff"
INACTIVE_BORDER="313244ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/dracula.sh" <<'_END_'
SCHEME_NAME="Dracula"
BG="282a36"
FG="f8f8f2"
COMMENT="6272a4"
SELECTION="44475a"
RED="ff5555"
ORANGE="ffb86c"
YELLOW="f1fa8c"
GREEN="50fa7b"
CYAN="8be9fd"
BLUE="bd93f9"
MAUVE="bd93f9"
TEAL="8be9fd"
MAROON="ff5555"
LAVENDER="ff79c6"
BG_ALPHA="ee"
ACTIVE_BORDER="bd93f9ff"
INACTIVE_BORDER="44475aff"
_END_

cat > "$HOME/scripts/theming/colorschemes/nord.sh" <<'_END_'
SCHEME_NAME="Nord"
BG="2e3440"
FG="eceff4"
COMMENT="4c566a"
SELECTION="3b4252"
RED="bf616a"
ORANGE="d08770"
YELLOW="ebcb8b"
GREEN="a3be8c"
CYAN="88c0d0"
BLUE="81a1c1"
MAUVE="b48ead"
TEAL="8fbcbb"
MAROON="bf616a"
LAVENDER="b48ead"
BG_ALPHA="ee"
ACTIVE_BORDER="81a1c1ff"
INACTIVE_BORDER="3b4252ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/tokyonight.sh" <<'_END_'
SCHEME_NAME="Tokyo Night"
BG="1a1b26"
FG="c0caf5"
COMMENT="565f89"
SELECTION="292e42"
RED="f7768e"
ORANGE="ff9e64"
YELLOW="e0af68"
GREEN="9ece6a"
CYAN="73daca"
BLUE="7aa2f7"
MAUVE="bb9af7"
TEAL="2ac3de"
MAROON="db4b4b"
LAVENDER="c0caf5"
BG_ALPHA="ee"
ACTIVE_BORDER="7aa2f7ff"
INACTIVE_BORDER="292e42ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/rose-pine.sh" <<'_END_'
SCHEME_NAME="Rose Pine"
BG="191724"
FG="e0def4"
COMMENT="6e6a86"
SELECTION="26233a"
RED="eb6f92"
ORANGE="ebbcba"
YELLOW="f6c177"
GREEN="9ccfd8"
CYAN="9ccfd8"
BLUE="31748f"
MAUVE="c4a7e7"
TEAL="31748f"
MAROON="eb6f92"
LAVENDER="c4a7e7"
BG_ALPHA="ee"
ACTIVE_BORDER="c4a7e7ff"
INACTIVE_BORDER="26233aff"
_END_

cat > "$HOME/scripts/theming/colorschemes/kanagawa.sh" <<'_END_'
SCHEME_NAME="Kanagawa"
BG="1f1f28"
FG="dcd7ba"
COMMENT="727169"
SELECTION="2a2a37"
RED="c34043"
ORANGE="ffa066"
YELLOW="e6c384"
GREEN="98bb6c"
CYAN="7aa89f"
BLUE="7e9cd8"
MAUVE="957fb8"
TEAL="6a9589"
MAROON="c34043"
LAVENDER="9cabca"
BG_ALPHA="ee"
ACTIVE_BORDER="7e9cd8ff"
INACTIVE_BORDER="2a2a37ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/onedark.sh" <<'_END_'
SCHEME_NAME="One Dark"
BG="282c34"
FG="abb2bf"
COMMENT="5c6370"
SELECTION="3e4452"
RED="e06c75"
ORANGE="d19a66"
YELLOW="e5c07b"
GREEN="98c379"
CYAN="56b6c2"
BLUE="61afef"
MAUVE="c678dd"
TEAL="56b6c2"
MAROON="be5046"
LAVENDER="c678dd"
BG_ALPHA="ee"
ACTIVE_BORDER="61afefff"
INACTIVE_BORDER="3e4452ff"
_END_

cat > "$HOME/scripts/theming/colorschemes/everforest.sh" <<'_END_'
SCHEME_NAME="Everforest"
BG="2d353b"
FG="d3c6aa"
COMMENT="859289"
SELECTION="3d484d"
RED="e67e80"
ORANGE="e69875"
YELLOW="dbbc7f"
GREEN="a7c080"
CYAN="83c092"
BLUE="7fbbb3"
MAUVE="d699b6"
TEAL="83c092"
MAROON="e67e80"
LAVENDER="d699b6"
BG_ALPHA="ee"
ACTIVE_BORDER="7fbbb3ff"
INACTIVE_BORDER="3d484dff"
_END_

cat > "$HOME/scripts/theming/colorschemes/solarized-dark.sh" <<'_END_'
SCHEME_NAME="Solarized Dark"
BG="002b36"
FG="839496"
COMMENT="586e75"
SELECTION="073642"
RED="dc322f"
ORANGE="cb4b16"
YELLOW="b58900"
GREEN="859900"
CYAN="2aa198"
BLUE="268bd2"
MAUVE="d33682"
TEAL="2aa198"
MAROON="dc322f"
LAVENDER="6c71c4"
BG_ALPHA="ee"
ACTIVE_BORDER="268bd2ff"
INACTIVE_BORDER="073642ff"
_END_

ok "Wrote 11 colorscheme palettes"

# ── dwm session launcher (no xrandr — user adds per-machine if needed) ──
cat > "$HOME/scripts/dwm/dwm-session.sh" <<'_END_'
#!/bin/sh
# dwm session launcher — invoked by SDDM/.xinitrc.
# Add `xrandr` lines below for your specific monitor layout if needed.

xset r rate 200 35                      # Faster key repeat

# Disable screen blanking and DPMS (display power management).
xset s off                              # No screensaver timeout
xset s noblank                          # No video blank
xset -dpms                              # No DPMS power-down

# Background daemons.
sxhkd &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
picom &
# Wallpaper: prefer feh (default), fall back to nitrogen if you switch.
[ -f "$HOME/.config/wallpaper" ] && feh --bg-fill "$HOME/.config/wallpaper" 2>/dev/null &
dwmblocks &
clipmenud &

exec dwm
_END_

ok "Wrote dwm-session.sh (no xrandr — add per-machine if needed)"

chmod +x "$HOME/scripts/dmenu/"*.sh \
         "$HOME/scripts/dwm-blocks/"*.sh \
         "$HOME/scripts/dwm/"*.sh

# ───────────── 3. shell hooks ─────────────
section "Installing shell hooks (fish + bash)"

cat > "$HOME/.config/fish/conf.d/dwm-st-colors.fish" <<'_END_'
# Auto-apply the dwm colorscheme palette to st (and any OSC-compatible terminal)
# on every interactive shell startup. Populated by ~/scripts/dwm-blocks/sync-colors.sh.
if status is-interactive
    set -l osc "$HOME/.cache/dwm-colorscheme/st-osc.txt"
    if test -r "$osc"
        cat "$osc"
    end
end
_END_
ok "Wrote fish conf.d hook"

# Bash hook: append-if-missing using a marker comment grep.
BASHRC="$HOME/.bashrc"
[ -e "$BASHRC" ] || touch "$BASHRC"
if ! grep -q "dwm colorscheme: auto-apply OSC palette" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'_END_'

# --- dwm colorscheme: auto-apply OSC palette on interactive bash startup ---
if [[ $- == *i* ]] && [[ -r "$HOME/.cache/dwm-colorscheme/st-osc.txt" ]]; then
    cat "$HOME/.cache/dwm-colorscheme/st-osc.txt"
fi
_END_
    ok "Appended bash hook to ~/.bashrc"
else
    ok "Bash hook already present in ~/.bashrc"
fi

# ───────────── 3b. picom config ─────────────
section "Installing FT-Labs-picom config"
mkdir -p "$HOME/.config/picom"
if [ -e "$HOME/.config/picom/picom.conf" ]; then
    ok "picom.conf already exists — left untouched (delete it and re-run to refresh)"
else
    cat > "$HOME/.config/picom/picom.conf" <<'_END_'
#################################
#             Shadows           #
#################################

shadow-radius = 7;

# The opacity of shadows. (0.0 - 1.0, defaults to 0.75)
# shadow-opacity = .75

# The left offset for shadows, in pixels. (defaults to -15)
# shadow-offset-x = -15
shadow-offset-x = -7;

# The top offset for shadows, in pixels. (defaults to -15)
# shadow-offset-y = -15
shadow-offset-y = -7;

# Specify a list of conditions of windows that should have no shadow.
shadow-exclude = [
  "name = 'Notification'",
  "class_g ?= 'Notify-osd'",
  "_GTK_FRAME_EXTENTS@:c"
];

#################################
#           Fading              #
#################################

fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;

#################################
#   Transparency / Opacity      #
#################################

inactive-opacity = 1
frame-opacity = 1.0
inactive-opacity-override = false;

# Per-class opacity rules.  Add classes as needed.
opacity-rule = [ "98:class_g = 'kitty'"];

#################################
#           Corners             #
#################################

corner-radius = 0

rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];


#################################
#     Background-Blurring       #
#################################

blur-kern = "3x3box";

blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "_GTK_FRAME_EXTENTS@:c"
];

#################################
#          Animations           #
#################################

# Enables window animations (FT Labs picom only)
animations = true;

# Animation settings for window movement/resizing
animation-stiffness = 125;        # How "springy" the animation is (lower = more spring)
animation-window-mass = 1.2;      # Window mass (higher = slower movement)
animation-dampening = 25;         # How quickly animation settles (higher = faster settle)
animation-clamping = true;        # Clamp animations (kills bouncy overshoot)

# Animation presets:
# "none", "fly-in", "zoom", "slide-up", "slide-down", "slide-left", "slide-right"
animation-for-open-window = "zoom";
animation-for-unmap-window = "zoom";

animation-exclude = [
  "class_g = 'slop'",
];

#################################
#       General Settings        #
#################################

# `xrender`, `glx`, `egl` or `xr_glx_hybrid`.  glx for animation perf.
backend = "glx";

dithered-present = false;
vsync = true;

mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
use-damage = true;

log-level = "warn";

wintypes:
{
  tooltip = { fade = true; shadow = true; opacity = 0.95; focus = true; full-shadow = false; };
  dock = { shadow = false; clip-shadow-above = true; }
  dnd = { shadow = false; }
  popup_menu = { opacity = 0.95; }
  dropdown_menu = { opacity = 0.95; }
};
_END_
    ok "Wrote ~/.config/picom/picom.conf (FT-Labs-picom flavor with animations)"
fi

# ───────────── 4. seed colorscheme cache ─────────────
section "Seeding default colorscheme (Monokai Pro)"
"$HOME/scripts/dwm-blocks/sync-colors.sh" monokai >>"$LOG" 2>&1 \
    && ok "Cache populated at ~/.cache/dwm-colorscheme/" \
    || warn "sync-colors.sh failed (run it manually after dwm is built)"

# ───────────── 5. session entry — interactive prompt ─────────────
section "Session entry point"
printf '\nWhere should dwm be launched from?\n'
printf '  1) ~/.xinitrc                          (for `startx`, no display manager)\n'
printf '  2) /usr/share/xsessions/dwm.desktop    (for SDDM / GDM / lightdm) [default]\n\n'
printf 'choice [2]: '
read CHOICE || CHOICE=2
CHOICE="${CHOICE:-2}"

case "$CHOICE" in
    1)
        cat > "$HOME/.xinitrc" <<'_END_'
#!/bin/sh
exec ~/scripts/dwm/dwm-session.sh
_END_
        chmod +x "$HOME/.xinitrc"
        ok "Wrote ~/.xinitrc — start dwm with: startx"
        ;;
    2)
        sudo tee /usr/share/xsessions/dwm.desktop >/dev/null <<_END_
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager (suckless)
Exec=$HOME/scripts/dwm/dwm-session.sh
Type=XSession
_END_
        ok "Wrote /usr/share/xsessions/dwm.desktop — pick 'dwm' at SDDM"
        ;;
    *)
        err "Invalid choice '$CHOICE'."; exit 1
        ;;
esac

# ───────────── 6. build & install ─────────────
section "Building suckless tools"

# Keep sudo authenticated across all the builds — long meson/ninja runs can
# outlast sudo's default timeout, and stdout/stderr being redirected to the
# log means a re-prompt would silently hang.
info "Refreshing sudo (you may be prompted)"
sudo -v
( while true; do sudo -nv 2>/dev/null; sleep 60; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT INT TERM

# Substitute the __USER_HOME__ placeholder (and any stale /home/codywan literals
# from upstream) with the current user's $HOME in every config*.h file in the
# given directory. Idempotent: runs every build, no-ops once placeholders are
# resolved.  Uses if/then/fi rather than `[ -f ] &&` so a missing file in a
# package without config.h (e.g. dfm) doesn't trip `set -e` and silently kill
# the installer.
substitute_paths() {
    for f in "$1"/config.def.h "$1"/config.h; do
        if [ -f "$f" ]; then
            sed -i \
                -e "s|__USER_HOME__|$HOME|g" \
                -e "s|/home/codywan|$HOME|g" \
                "$f"
        fi
    done
    return 0
}

build_make() {
    pkg="$1"
    info "Building $pkg"
    substitute_paths "$SRCDIR/$pkg"
    if (cd "$SRCDIR/$pkg" && make clean && make && sudo make install) >>"$LOG" 2>&1; then
        ok "$pkg installed"
    else
        err "$pkg build failed — log tail:"
        tail -25 "$LOG" | sed 's/^/      /'
        exit 1
    fi
}

build_meson() {
    pkg="$1"
    info "Building $pkg (meson)"
    # Nuke the build dir every run.  --reconfigure has bitten us when a
    # previous attempt left a partial build/, and the rebuild cost is small.
    if (
        cd "$SRCDIR/$pkg"
        rm -rf build
        meson setup --buildtype=release build
        ninja -C build
        sudo ninja -C build install
    ) >>"$LOG" 2>&1; then
        ok "$pkg installed"
    else
        err "$pkg build failed — log tail:"
        tail -25 "$LOG" | sed 's/^/      /'
        exit 1
    fi
}

# Detect package directories present in SRCDIR (allows missing/renamed dirs).
for d in dmenu-5.4 st-0.9.3 dwm-6.8 dwmblocks dfm clipmenu; do
    if [ -d "$SRCDIR/$d" ]; then
        build_make "$d"
    else
        warn "$d/ not found in $SRCDIR — skipped"
    fi
done

if [ -d "$SRCDIR/FT-Labs-picom" ]; then
    build_meson "FT-Labs-picom"
else
    warn "FT-Labs-picom/ not found — using whatever picom is in pacman (or none)"
fi

# ───────────── 7. summary ─────────────
section "Done"
ok "Installed binaries to /usr/local/bin/"
ok "Scripts in $HOME/scripts/  Cache in $HOME/.cache/dwm-colorscheme/"
[ "$CHOICE" = 1 ] && info "Run 'startx' to enter the dwm session." \
                  || info "Log out and pick 'dwm' at SDDM."

# Font check
if ! fc-list 2>/dev/null | grep -qi monofur; then
    warn "Monofur Nerd Font not found.  Install via AUR for the configured font;"
    warn "  fallback to monospace will render but lose icons.  e.g.:"
    warn "    yay -S ttf-monofur-nerd-font"
fi

# DPMS already-disabled hint for current session
if command -v xset >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    info "Tip: xset s off; xset s noblank; xset -dpms  to apply blanking-off live."
fi

printf '\n%bAll done.%b  Full build log: %s\n' "$C_GREEN" "$C_OFF" "$LOG"
