#!/usr/bin/env bash

set -ue

source "$HOME/.config/i3/scrot.env"
SND="$HOME/.config/i3/resources/shutter-short.wav"

aplay -q "$SND" & scrot -m "${SCROT_ARGS[@]}"
