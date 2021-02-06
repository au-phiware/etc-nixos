#!/usr/bin/env bash

set -ue

size=${3-?}
unit=1
units=( "" "K" "M" "G" )
while [ $size -gt 1024 ]; do
  unit=$(( unit++ ))
  size=$(( size / 1024 ))
done

twmnc -d 8000 --ac "open $1" -t " Screen captured" -c "$2 ($size ${units[$unit]}iB)" 2>&1 > /dev/null
