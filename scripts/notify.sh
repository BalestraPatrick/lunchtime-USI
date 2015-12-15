#! /bin/bash
# Authors: Patrick Balestra and Lara Bruseghini
# brew install terminal-notifier
SYS_PATH="/usr/local/bin/"

DIR="$( dirname "${BASH_SOURCE[0]}" )"
day=$(date '+%a')

if [[ "$day" != "Sat" && "$day" != "Sun" ]]; then
  fullMenu="$DIR/../menus/$day-full.txt"
  singleMenu="$DIR/../menus/$day-single.txt"

  $("$SYS_PATH"terminal-notifier -title 'λunchtime @ USI' -subtitle "$(head -n 1 $fullMenu)" -message "$(head -n 1 $singleMenu)" -appIcon "$DIR/λunchtime.png")
fi
