#! /bin/bash
# Authors: Patrick Balestra and Lara Bruseghini
# Project: λunchtime @ USI (ProgFund1 Semester Project)
# #
# To run this script, pdfgrep dependencies are required:
#     - Install brew from http://brew.sh
#     - $ brew install pdfgrep
# #

# 'brew install pdfgrep'
SYS_PATH="/usr/local/bin/"
menuURL="http://www.usi.ch/usi-menu_mensa-12417.pdf"
menuPDF="$8output/menu.pdf"

# EXTRACT rectangles of text under each day's string
  # args = $1-5: days' Xs, $6 days' Y1, $7 days' Y2
  args=( "$@" ) # Array of all the script args
  yDay=$6
  heightDay=`expr $7 - $6`
  widthDay=20 #approx - let's keep this simple
  days=("mon" "tue" "wed" "thu" "fri")

  for i in {0..4}
  do
    if $("$SYS_PATH"pdftotext -layout -x ${args[$i]} -y $yDay -H $heightDay -W $widthDay $menuPDF "$8output/${days[$i]}.txt");
    then
      echo "${days[$i]}.txt extracted successfully."
    else
      # Should never happened
       exit 1
    fi
  done
 wait $!
echo "finished"
exit 0
