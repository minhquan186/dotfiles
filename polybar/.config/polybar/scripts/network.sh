#!/bin/bash

wifi_interface="wlo1"
eth_interface="eno2"

# Check WiFi
if ip link show "$wifi_interface" 2>/dev/null | grep -q "state UP"; then
    essid=$(iwgetid -r "$wifi_interface" 2>/dev/null)
    if [ -n "$essid" ]; then
        echo "%{F#a6e3a1}WIFI%{F-} $essid"
        exit 0
    fi
fi

# Check Ethernet
if ip link show "$eth_interface" 2>/dev/null | grep -q "state UP"; then
    echo "%{F#a6e3a1}ETH%{F-} Connected"
    exit 0
fi

# Down
echo "%{F#f38ba8}NET%{F-} Down"
