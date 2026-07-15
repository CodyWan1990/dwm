#!/bin/sh
# Icon-aware dmenu adapter for j4-dmenu-desktop.
set -eu

dmenu_pick=${DMENU_PICK:-"$HOME/.config/suckless/scripts/dmenu/dmenu-pick.sh"}
cache_dir="$HOME/.cache/dmenu-app-icons"
cache_map="$cache_dir/icons.tsv"
cache_stamp="$cache_dir/stamp"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/dmenu-app-icons.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

items_file="$work_dir/items"
decorated_file="$work_dir/decorated"
cat > "$items_file"

data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
data_dirs=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
app_dirs="$data_home/applications"
icon_roots="$HOME/.icons $data_home/icons"

old_ifs=$IFS
IFS=:
for data_dir in $data_dirs; do
    app_dirs="$app_dirs $data_dir/applications"
    icon_roots="$icon_roots $data_dir/icons"
done
IFS=$old_ifs

resolve_icon()
{
    icon=$1
    [ -n "$icon" ] || return 1
    case "$icon" in
        /*) [ -r "$icon" ] && { printf '%s\n' "$icon"; return 0; } ;;
    esac

    case "$icon" in
        *.svg|*.png|*.xpm) stem=${icon%.*} ;;
        *) stem=$icon ;;
    esac

    for root in $icon_roots; do
        [ -d "$root" ] || continue
        for theme in Papirus-Dark Papirus breeze-dark breeze hicolor; do
            for context in apps mimetypes; do
                for size in 22x22 24x24 32x32 48x48 64x64 128x128 256x256 512x512 scalable; do
                    for extension in svg png xpm; do
                        candidate="$root/$theme/$size/$context/$stem.$extension"
                        if [ -r "$candidate" ]; then
                            printf '%s\n' "$candidate"
                            return 0
                        fi
                    done
                done
                for size in 22 24 32 48 64; do
                    for extension in svg png xpm; do
                        candidate="$root/$theme/$context/$size/$stem.$extension"
                        if [ -r "$candidate" ]; then
                            printf '%s\n' "$candidate"
                            return 0
                        fi
                    done
                done
            done
        done
    done

    for extension in svg png xpm; do
        candidate="/usr/share/pixmaps/$stem.$extension"
        if [ -r "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

cache_stale=0
[ -s "$cache_map" ] && [ -e "$cache_stamp" ] || cache_stale=1
[ "$0" -nt "$cache_stamp" ] 2>/dev/null && cache_stale=1
if [ "$cache_stale" -eq 0 ]; then
    for directory in $app_dirs $icon_roots; do
        if [ -d "$directory" ] && [ "$directory" -nt "$cache_stamp" ]; then
            cache_stale=1
            break
        fi
    done
fi

if [ "$cache_stale" -eq 1 ]; then
    mkdir -p "$cache_dir"
    new_map="$work_dir/icons.tsv"
    : > "$new_map"

    generic_icon=$(resolve_icon application-x-executable 2>/dev/null || true)
    printf '__DMENU_FALLBACK__\t%s\n' "$generic_icon" >> "$new_map"

    for app_dir in $app_dirs; do
        [ -d "$app_dir" ] || continue
        find "$app_dir" -maxdepth 1 \( -type f -o -type l \) -name '*.desktop' -print 2>/dev/null |
        while IFS= read -r desktop; do
            entry=$(awk '
                /^\[Desktop Entry\]$/ { active = 1; next }
                active && /^\[/ { exit }
                active && /^Name=/ && name == "" { name = substr($0, 6) }
                active && /^Icon=/ && icon == "" { icon = substr($0, 6) }
                active && /^(Hidden|NoDisplay)=true$/ { hidden = 1 }
                END {
                    gsub(/[\t\r\n]/, " ", name)
                    gsub(/[\t\r\n]/, " ", icon)
                    if (!hidden && name != "") printf "%s\t%s", name, icon
                }
            ' "$desktop")
            [ -n "$entry" ] || continue
            name=${entry%%	*}
            icon=${entry#*	}
            icon_path=$(resolve_icon "$icon" 2>/dev/null || true)
            [ -n "$icon_path" ] || icon_path=$generic_icon
            printf '%s\t%s\n' "$name" "$icon_path" >> "$new_map"
        done
    done

    mv "$new_map" "$cache_map"
    : > "$cache_stamp"
fi

awk -F '\t' '
    NR == FNR {
        if (!($1 in icon)) icon[$1] = $2
        next
    }
    {
        path = ($0 in icon && icon[$0] != "") ? icon[$0] : icon["__DMENU_FALLBACK__"]
        print $0 "\t" path
    }
' "$cache_map" "$items_file" > "$decorated_file"

selection=$("$dmenu_pick" -I -is 22 "$@" < "$decorated_file") || exit 1
printf '%s\n' "$selection" | cut -f1
