#!/bin/bash
# Bluetooth state + connected device
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "󰂲"
    exit 0
fi
conn=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
if [ "$conn" -gt 0 ]; then
    name=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{$1="";$2="";$3="";sub(/^  */,"");print}')
    echo "󰂯 ${name}"
else
    echo "󰂯"
fi