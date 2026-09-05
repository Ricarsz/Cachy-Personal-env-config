#!/bin/bash
# CPU frequency display
freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | sort -n | tail -1)
if [ -z "$freq" ]; then freq=$(awk '{printf "%d", $2}' /proc/cpuinfo 2>/dev/null); fi
ghz=$(awk "BEGIN{printf \"%.1f\", ${freq:-0}/1000000}")
echo "󰓅 ${ghz}GHz"