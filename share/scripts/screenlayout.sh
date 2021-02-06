#!/usr/bin/env bash

set -u

#xrandr --setprovideroutputsource 1 0

connected=$(printf "%s." $(xrandr | grep -w connected | sort | cut -f 1 -d \ ))

[ -x ~/.screenlayout/"$connected"sh ] && ~/.screenlayout/"$connected"sh
