#! /bin/bash
# Authors: Patrick Balestra and Lara Bruseghini
# Project: λunchtime @ USI (ProgFund1 Semester Project)
# This script downloads the menu PDF file and converts it to TXT format.
# #
# To run this script, pdfgrep dependencies are required:
#     - Install brew from http://brew.sh
#     - $ brew install pdfgrep
# #

# NB: paths relative to parser.rkt (as it runs this script)
SYS_PATH="/usr/local/bin/"
menuURL="http://www.usi.ch/usi-menu_mensa-12417.pdf"
menuPDF="$1output/menu.pdf"
menuTXT="$1output/menu.txt"
output="$1output"
menus="$1menus"
ex_menu1="$1ex_menus/menu1.pdf"
ex_menu2="$1ex_menus/menu2.pdf"
ex_menu3="$1ex_menus/menu3.pdf"

# Start with empty output directory by cleaning it if it exists
if [ -d $output ]; then
  $(rm -rf $output)
fi
# Create empty output directory
$(mkdir $output)

# Start with empty menus directory by cleaning it if it exists
if [ -d $menus ]; then
  $(rm -rf $menus)
fi
# Create empty menus directory
$(mkdir $menus)

# DOWNLOAD the PDF file by following redirects and writing the output to a local file
  if $(curl -L -s -o $menuPDF $menuURL);
    then
      echo "File Downloaded successfully."
    else
      # No internet connection or an error occured while downloading the PDF menu.
      exit 1
  fi

  # Wait until the download is completed
  wait $!

  # Start the pdf parsing with the pdfgrep tool and create a txt file
  if $("$SYS_PATH"pdftotext -layout $menuPDF $menuTXT);
    then
      echo "Menu text extracted successfully."
    else
      # An error occured during the parsing
      exit 1
  fi
  wait $!
# If everything went well, exit!
exit 0
