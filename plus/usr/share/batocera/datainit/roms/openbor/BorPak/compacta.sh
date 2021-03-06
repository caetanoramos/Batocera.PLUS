#!/bin/sh
# Name: packer
# Author: Plombo
# Frontend for borpak that emulates Senile Team's "packer" utility.
# Put this file in the same directory as the borpak executable.

#NUMPARAMS=2
#DIR=`dirname "$0"`

#if [ $# -eq "$NUMPARAMS" ]
#then
#  "$DIR/borpak" -b -d "$2" "$1"
#  #borpak -b -d "$2" "$1"
#else
#  echo "Usage: packer <packname> <dirname>"
#fi  

#exit 0

DIR=`dirname "$0"`
"$DIR/borpak" -b -d "data" "data.pak"
exit 0