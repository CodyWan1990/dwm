#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────
#   Suckless dwm desktop installer for Arch Linux
#   Bootstraps: pacman deps → ~/.config/suckless/scripts/* → fish/bash hooks → session entry
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

# ───────────── 2. deploy scripts/ tree ─────────────
section "Deploying scripts/ to ~/.config/suckless/scripts/"
DEST="$HOME/.config/suckless/scripts"
install -d "$DEST"
cp -r "$SRCDIR/scripts/"* "$DEST/"
find "$DEST" -type f -name '*.sh' -exec chmod +x {} +
ok "Scripts deployed to $DEST"

# ───────────── 3. shell hooks ─────────────
section "Installing shell hooks (fish + bash)"

cat > "$HOME/.config/fish/conf.d/dwm-st-colors.fish" <<'_END_'
# Auto-apply the dwm colorscheme palette to st (and any OSC-compatible terminal)
# on every interactive shell startup. Populated by ~/.config/suckless/scripts/dwm-blocks/sync-colors.sh.
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
"$HOME/.config/suckless/scripts/dwm-blocks/sync-colors.sh" monokai >>"$LOG" 2>&1 \
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
exec ~/.config/suckless/scripts/dwm/dwm-session.sh
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
Exec=$HOME/.config/suckless/scripts/dwm/dwm-session.sh
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
    # dfm is a shell-script-only project; its Makefile has only `install`
    # and `uninstall` targets (no `all`, no `clean`).  Skip the compile dance.
    if [ "$pkg" = "dfm" ]; then
        cmd='sudo make install'
    else
        cmd='make clean && make && sudo make install'
    fi
    if (cd "$SRCDIR/$pkg" && eval "$cmd") >>"$LOG" 2>&1; then
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
ok "Scripts in $HOME/.config/suckless/scripts/  Cache in $HOME/.cache/dwm-colorscheme/"
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
