#!/bin/bash

options="Shutdown\nReboot\nLogout\nSuspend\nCancel"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu:")

case $chosen in
    Shutdown)
        systemctl poweroff
        ;;
    Reboot)
        systemctl reboot
        ;;
    Logout)
        bspc quit
        ;;
    Suspend)
        systemctl suspend
        ;;
    Cancel)
        exit 0
        ;;
esac
