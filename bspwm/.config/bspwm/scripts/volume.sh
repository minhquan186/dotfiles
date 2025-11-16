#!/bin/bash

max_volume=100

# Get current volume first
current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1)

case "$1" in
    up)
        # Only increase if under max
        if [ "$current_volume" -lt "$max_volume" ]; then
            pactl set-sink-volume @DEFAULT_SINK@ +1%
            # Double-check we didn't go over
            new_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1)
            if [ "$new_volume" -gt "$max_volume" ]; then
                pactl set-sink-volume @DEFAULT_SINK@ "${max_volume}%"
            fi
        fi
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -1%
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
esac
