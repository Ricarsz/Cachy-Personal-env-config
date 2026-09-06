#!/bin/bash

# ==============================================================================
# Command Center — 系统维护命令中心
# ==============================================================================
# 功能概述：
#   1. 严格模式执行，保障代码健壮性
#   2. 动态环境探测，按需生成菜单选项
#   3. 自动检测可用工具，不显示不可用的功能
#
# 探测逻辑：
#   - BTRFS 检测：文件系统类型 + 依赖工具
#   - 维护命令探测：检测 sysup/mirror-update/clean 等命令是否存在于
#      ~/.local/bin 中
#   - Niri 更新检测：目录与执行路径共同判断
#   - 网络工具：NetworkManager 后端（iwd/wpa_supplicant）
#   - 蓝牙工具：按优先级检测可用的 TUI 工具
# ==============================================================================

# 严格模式
# -e：命令失败时立即退出
# -u：使用未定义变量时报错
# -o pipefail：管道中任一命令失败则整体失败
set -euo pipefail

# 错误处理与通知函数
report_error() {
    local error_msg="$1"
    echo "错误：$error_msg" >&2
    # 发送桌面通知（如果 notify-send 可用）
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical -a "Command Center" "命令中心异常" "$error_msg" || true
    fi
}

# 命令探测函数
# 参数：$1 = 命令名称
# 逻辑：使用 ~/.local/bin 下的独立脚本
get_exec_cmd() {
    local target="$1"
    if [[ -x "$HOME/.local/bin/$target" ]]; then
        echo "$HOME/.local/bin/$target"
    else
        echo ""
    fi
}

# ==================== 基础依赖检测 ====================
# Ghostty：GPU 加速终端模拟器
if ! command -v ghostty >/dev/null 2>&1; then
    report_error "未找到 ghostty 终端，请先安装。"
    exit 1
fi

# ==================== 选项变量声明 ====================
# 满足 set -u 要求，所有变量必须预先声明
OPT_SAVE="快速存档 (quicksave)"
OPT_LOAD="快速读档 (quickload)"
OPT_MIRROR=""
CMD_MIRROR=""
OPT_SYSUP=""
CMD_SYSUP=""
OPT_CLEAN=""
CMD_CLEAN=""
OPT_DEEP_CLEAN=""
OPT_NETWORK=""
NET_TOOL=""
OPT_BLUETOOTH=""
BT_TOOL=""

# 动态选项数组
OPTIONS_ARR=()

# ==================== BTRFS 快照功能 ====================
# 检测条件：根分区是 BTRFS + snapper + btrfs-assistant 已安装
BTRFS_MODE=false
if [[ "$(stat -f -c %T /)" == "btrfs" ]] && \
   command -v snapper >/dev/null 2>&1 && \
   command -v btrfs-assistant >/dev/null 2>&1; then
    BTRFS_MODE=true
    OPTIONS_ARR+=("$OPT_SAVE")
    OPTIONS_ARR+=("$OPT_LOAD")
fi

# ==================== 系统维护命令 ====================
# 镜像源更新
CMD_MIRROR=$(get_exec_cmd "mirror-update")
if [[ -n "$CMD_MIRROR" ]]; then
    OPT_MIRROR="更新镜像源 (mirror-update)"
    OPTIONS_ARR+=("$OPT_MIRROR")
fi

# 系统更新
CMD_SYSUP=$(get_exec_cmd "sysup")
if [[ -n "$CMD_SYSUP" ]]; then
    OPT_SYSUP="更新系统 (sysup)"
    OPTIONS_ARR+=("$OPT_SYSUP")
fi

# 系统清理
CMD_CLEAN=$(get_exec_cmd "clean")
if [[ -n "$CMD_CLEAN" ]]; then
    OPT_CLEAN="系统清理 (clean)"
    OPTIONS_ARR+=("$OPT_CLEAN")
    
    # 深度清理：需要 BTRFS 支持
    if [[ "$BTRFS_MODE" == true ]]; then
        OPT_DEEP_CLEAN="深度系统清理 (clean all)"
        OPTIONS_ARR+=("$OPT_DEEP_CLEAN")
    fi
fi

# ==================== 网络工具 ====================
# 检测 NetworkManager 后端
# iwd 后端 -> impala（TUI）
# wpa_supplicant 后端 -> nmtui
if systemctl is-active --quiet NetworkManager; then
    if NetworkManager --print-config 2>/dev/null | grep -iq 'wifi\.backend.*iwd' || systemctl is-active --quiet iwd; then
        NET_TOOL="impala"
    else
        NET_TOOL="nmtui"
    fi
    OPT_NETWORK="联网工具 ($NET_TOOL)"
    OPTIONS_ARR+=("$OPT_NETWORK")
fi

# ==================== 蓝牙工具 ====================
# 按优先级检测可用的蓝牙 TUI 工具
if [[ -d /sys/class/bluetooth ]] && [[ -n "$(ls -A /sys/class/bluetooth 2>/dev/null || true)" ]]; then
    if command -v bluetuith >/dev/null 2>&1; then
        BT_TOOL="bluetuith"
    elif command -v bluetui >/dev/null 2>&1; then
        BT_TOOL="bluetui"
    elif command -v blueman-manager >/dev/null 2>&1; then
        BT_TOOL="blueman-manager"
    elif command -v blueberry >/dev/null 2>&1; then
        BT_TOOL="blueberry"
    else
        BT_TOOL="bluetoothctl"  # 回退到命令行工具
    fi
    OPT_BLUETOOTH="蓝牙工具 ($BT_TOOL)"
    OPTIONS_ARR+=("$OPT_BLUETOOTH")
fi

# ==================== 其他工具 ====================
OPT_CLIPBOARD="剪贴板历史"
OPTIONS_ARR+=("$OPT_CLIPBOARD")

OPT_SCREENSHOT="截图"
OPTIONS_ARR+=("$OPT_SCREENSHOT")

# ==================== 菜单显示 ====================
# 无可用选项时退出
if [[ ${#OPTIONS_ARR[@]} -eq 0 ]]; then
    report_error "未探测到任何可用的维护指令。"
    exit 1
fi

# 使用 Fuzzel 显示菜单
SELECTED=$(printf "%s\n" "${OPTIONS_ARR[@]}" | fuzzel --dmenu || true)

# 用户取消选择
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# ==================== 命令执行 ====================
# 所有命令使用探测所得的 CMD_ 变量，实现逻辑解耦
case "$SELECTED" in
    "$OPT_SAVE")
        quicksave &
        ;;
    "$OPT_LOAD")
        quickload &
        ;;
    "$OPT_MIRROR")
        ghostty --class=command-center -e bash -c "$CMD_MIRROR; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "$OPT_SYSUP")
        ghostty --class=command-center -e bash -c "$CMD_SYSUP; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "$OPT_CLEAN")
        ghostty --class=command-center -e bash -c "$CMD_CLEAN; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "$OPT_DEEP_CLEAN")
        # $CMD_CLEAN all 适配独立脚本
        ghostty --class=command-center -e bash -c "$CMD_CLEAN all; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "$OPT_NETWORK")
        if [[ -n "$NET_TOOL" ]]; then
            ghostty --class=command-center -e bash -c "$NET_TOOL"
        fi
        ;;
    "$OPT_BLUETOOTH")
        if [[ -n "$BT_TOOL" ]]; then
            ghostty --class=command-center -e bash -c "$BT_TOOL"
        fi
        ;;
    "$OPT_CLIPBOARD")
        ghostty --class=cliphist-tui -e cliphist-tui
        ;;
    "$OPT_SCREENSHOT")
        niri msg action screenshot --show-pointer false
        ;;
    *)
        report_error "未知的选项: $SELECTED"
        exit 1
        ;;
esac
