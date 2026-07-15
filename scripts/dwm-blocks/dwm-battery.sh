#!/bin/sh
# Battery status for dwmblocks. Desktops without a battery produce no output.
# shellcheck disable=SC1090,SC1091
colors_cache="$HOME/.cache/dwm-colorscheme/colors.sh"
colors_fallback="$HOME/.config/suckless/scripts/colorschemes/monokai.sh"
if [ -r "$colors_cache" ]; then
    . "$colors_cache"
else
    . "$colors_fallback"
fi

power_supply_dir=${POWER_SUPPLY_DIR:-/sys/class/power_supply}
battery_dir=

for candidate in "$power_supply_dir"/*; do
    [ -d "$candidate" ] || continue
    [ -r "$candidate/type" ] || continue
    type=$(sed -n '1p' "$candidate/type")
    if [ "$type" = Battery ]; then
        battery_dir=$candidate
        break
    fi
done

[ -n "$battery_dir" ] || exit 0
[ -r "$battery_dir/capacity" ] || exit 0

capacity=$(sed -n '1p' "$battery_dir/capacity")
case "$capacity" in
    *[!0-9]*|'') exit 0 ;;
esac
[ "$capacity" -le 100 ] || capacity=100

if [ -r "$battery_dir/status" ]; then
    status=$(sed -n '1p' "$battery_dir/status")
else
    status=Unknown
fi

case "$status" in
    Charging)
        icon=🔌
        color=$GREEN
        ;;
    Full)
        icon=🔋
        color=$GREEN
        ;;
    Discharging)
        if [ "$capacity" -le 15 ]; then
            icon=🪫
            color=$RED
        elif [ "$capacity" -le 30 ]; then
            icon=🔋
            color=$YELLOW
        else
            icon=🔋
            color=$GREEN
        fi
        ;;
    *)
        icon=🔋
        color=$COMMENT
        ;;
esac

printf "^c#%s^%s %s%%^d^" "$color" "$icon" "$capacity"
