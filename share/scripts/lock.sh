#!/usr/bin/env bash

set -ue

shield="$1"
screen=$(mktemp -p /tmp lockscreen-XXXX)
trap "rm '$screen'*" EXIT

scrot -a -o -z -t 20 "$screen".png
identify -ping "$screen".png | (
	IFS="x " read _ _ w h _
	convert -sample "${w}x${h}" -modulate 100,70 "$screen"-thumb.png "$screen".png
	xrandr | grep -w connected | while IFS="x+" read w h x y; do
		w=${w##* }
		y=${y%% *}
		convert "$screen".png "$shield" -geometry "+$(( x + w / 2 - 150 ))+$(( y + h / 2 - 150 ))" -composite "$screen".png
	done
)
i3lock -i "$screen".png
sleep 1
