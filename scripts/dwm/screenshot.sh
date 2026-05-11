#!/bin/sh
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date '+%Y-%m-%d_%H-%M-%S').png"
maim -s "$FILE" && xclip -selection clipboard -t image/png < "$FILE"
