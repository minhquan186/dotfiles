#!/bin/bash

# Get Spotify status using playerctl
status=$(playerctl --player=spotify status 2>/dev/null)

if [ "$status" = "Playing" ]; then
    artist=$(playerctl --player=spotify metadata artist 2>/dev/null)
    title=$(playerctl --player=spotify metadata title 2>/dev/null)
    echo "$artist - $title"
elif [ "$status" = "Paused" ]; then
    echo "Paused"
else
    echo ""
fi
