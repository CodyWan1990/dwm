#!/bin/sh
TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
USED=$(awk "BEGIN {printf \"%.1f\", ($TOTAL - $AVAIL) / 1048576}")
TOTG=$(awk "BEGIN {printf \"%.0f\", $TOTAL / 1048576}")
printf "\x0bRAM\x0c %sG/%sG" "$USED" "$TOTG"
