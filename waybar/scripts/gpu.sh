#!/bin/bash
# GPU 状态: 默认显示 AMD 780M (核显) 用量+温度
# tooltip 额外显示 RTX 4060 状态 (按需 offload, 不常驻)
# 输出 JSON 供 waybar custom/gpu (return-type: json) 使用

amd_busy=""
amd_temp=""

# 动态定位 amdgpu 卡号 (card0/1/2 跨启动可能变化)
for c in /sys/class/drm/card[0-9]; do
    [ "$(cat "$c/device/vendor" 2>/dev/null)" = "0x1002" ] || continue
    amd_busy=$(cat "$c/device/gpu_busy_percent" 2>/dev/null)
    t=$(cat "$c"/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
    [ -n "$t" ] && amd_temp=$((t / 1000))
    break
done

# 独显信息 (仅 tooltip); cardwire integrated 屏蔽时显示"已屏蔽"
nv_tip=""
if command -v nvidia-smi >/dev/null 2>&1; then
    nv=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null)
    if echo "$nv" | grep -qE '^[0-9]+, *[0-9]+, *[0-9]+'; then
        nv_tip=$(echo "$nv" | awk -F', ' '{printf "RTX 4060: %s%% %s°C %sMB", $1, $2, $3}')
    else
        nv_tip="RTX 4060: 已屏蔽 (cardwire integrated)"
    fi
fi

if [ -z "$amd_busy" ]; then
    printf '{"text":"%s","tooltip":"%s"}\n' "󰢮 --" "AMD GPU 不可用"
    exit 0
fi

text="󰢮 ${amd_busy}% ${amd_temp}°C"
tip="AMD 780M: ${amd_busy}% ${amd_temp}°C"
[ -n "$nv_tip" ] && tip="$tip\\n$nv_tip"
printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tip"
