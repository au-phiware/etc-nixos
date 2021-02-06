#!/usr/bin/env bash

set -ue

source "$HOME/.config/i3/scrot.env"
SND="$HOME/.config/i3/resources/shutter-long.wav"

aplay -q "$SND" & scrot -m -d 3 "${SCROT_ARGS[@]}"
