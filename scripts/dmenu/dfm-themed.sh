#!/bin/sh
# Run DFM with our themed dmenu as its picker.
# DFM internally invokes `dmenu`; we shadow it with a tmpdir wrapper that
# delegates to dmenu-pick.sh. Other dmenu use elsewhere is untouched.
SHIM="$(mktemp -d -t dmenu-shim.XXXXXX)"
trap 'rm -rf "$SHIM"' EXIT INT TERM

cat > "$SHIM/dmenu" <<EOF
#!/bin/sh
exec "$HOME/.config/suckless/scripts/dmenu/dmenu-pick.sh" "\$@"
EOF
chmod +x "$SHIM/dmenu"

PATH="$SHIM:$PATH" exec dfm "$@"
