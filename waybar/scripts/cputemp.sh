#!/bin/bash
# CPU 温度 (动态探测 k10temp hwmon, 编号跨启动可能变化)
for h in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$h/name" 2>/dev/null)" = "k10temp" ]; then
        t=$(cat "$h/temp1_input" 2>/dev/null)
        if [ -n "$t" ]; then
            echo "󰙨 $((t / 1000))°C"
            exit 0
        fi
    fi
done
echo "󰙨 --"
