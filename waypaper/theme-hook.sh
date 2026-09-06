#!/usr/bin/env bash

# ==============================================================================
# theme-hook.sh — 动态主题事务性更新脚本
# ==============================================================================
#
# 工作流：
#   waypaper 选择壁纸 ($wallpaper)
#     -> matugen 从壁纸生成 Material You 配色到 staging/
#     -> 验证 staging 产物完整性
#     -> 备份当前颜色文件到 last-good/
#     -> 原子移动 (mv) staging 产物到真实配置路径
#     -> 重载各组件（niri / waybar / mako / fuzzel 无需重载 / ghostty 见下）
#
# 失败处理：
#   任何一步失败 -> 自动从 last-good/ 恢复并重载，桌面回到上一个可用主题
#
# 使用方法：
#   theme-hook.sh <壁纸路径>    # 应用新主题
#   theme-hook.sh --restore     # 手动恢复上次主题
#
# 状态目录：~/.local/state/dynamic-theme/
#   staging/          matugen 生成候选区
#   last-good/        最近一次验证通过的配色快照
#   current-wallpaper 当前生效的壁纸路径
#   ghostty-usrs2-ok  标记：实测 ghostty 支持 SIGUSR2 热重载时创建
# ==============================================================================

# 严格模式（-e 已移除，由手动错误处理替代）
set -uo pipefail

# 状态目录路径
ST="$HOME/.local/state/dynamic-theme"
STAGING="$ST/staging"        # matugen 输出候选区
LASTGOOD="$ST/last-good"    # 最后一次成功的配色快照
CFG="$HOME/.config/matugen/config.toml"
TERMINAL_NOTIFY="${TERMINAL_NOTIFY:-1}"  # 是否发送桌面通知

# ==================== 颜色文件映射 ====================
# staging 文件名 -> 真实目标路径（顺序一一对应）
STAGED_FILES=(waybar-colors.css fuzzel-colors.ini mako-colors.conf ghostty-colors niri-colors.kdl)
LIVE_FILES=(
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/fuzzel/colors.ini"
    "$HOME/.config/mako/colors.conf"
    "$HOME/.config/ghostty/colors"
    "$HOME/.config/niri/colors.kdl"
)

# 每个文件的验证标记（检查生成内容完整性）
# 用于 grep 匹配，确保文件包含预期内容
MARKERS=('@define-color background' '^background=' '^background-color=' '^palette = 0=' 'focus-ring')

# ==================== 工具函数 ====================

# 通知函数（桌面通知 + 终端输出）
notify() {
    if [[ "$TERMINAL_NOTIFY" == "1" ]] && command -v notify-send >/dev/null; then
        notify-send -a "Dynamic Theme" "$1" "$2" 2>/dev/null
    fi
    echo "[theme-hook] $1: $2"
}

# 重载所有桌面组件
reload_all() {
    # Niri：重新加载配置文件
    niri msg action load-config-file >/dev/null 2>&1 || true
    # Waybar：SIGUSR2 触发热重载
    pkill -SIGUSR2 waybar 2>/dev/null || true
    # Mako：重新加载配置
    makoctl reload >/dev/null 2>&1 || true
    # Ghostty：仅当实测支持 SIGUSR2 时才发送（避免重启终端）
    if [[ -f "$ST/ghostty-usrs2-ok" ]]; then
        pkill -SIGUSR2 ghostty 2>/dev/null || true
    fi
}

# 恢复上次成功的主题
restore_last_good() {
    local ok=1
    for i in "${!LIVE_FILES[@]}"; do
        if [[ -f "$LASTGOOD/${STAGED_FILES[$i]}" ]]; then
            cp -f "$LASTGOOD/${STAGED_FILES[$i]}" "${LIVE_FILES[$i]}" || ok=0
        fi
    done
    if [[ $ok == 1 ]]; then
        reload_all
        return 0
    fi
    return 1
}

# ==================== 恢复模式 ====================
if [[ "${1:-}" == "--restore" ]]; then
    if restore_last_good; then
        notify "主题已恢复" "已恢复到最近一次可用主题 (last-good)"
        exit 0
    else
        notify "恢复失败" "last-good 快照不存在或恢复出错"
        exit 1
    fi
fi

# ==================== 主流程 ====================

# 获取壁纸路径
WP="${1:-}"
if [[ -z "$WP" ]]; then
    echo "用法: theme-hook.sh <壁纸路径> | --restore" >&2
    exit 2
fi

# waypaper 传来的路径可能带转义空格（反斜杠），尝试反转义
if [[ ! -f "$WP" ]]; then
    WP="$(printf '%b' "${WP//\\/}")"
fi
WP="$(readlink -f "$WP")"

# 壁纸不存在时的回退逻辑
# 场景：用户删除了 waypaper 记录的壁纸；开机恢复失败时不弹告警
if [[ ! -f "$WP" ]]; then
    # 回退优先级：1. 上次壁纸 2. 壁纸库第一张
    for cand in "$(cat "$ST/current-wallpaper" 2>/dev/null)" "$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)"; do
        [[ -n "$cand" && -f "$cand" ]] && { WP="$(readlink -f "$cand")"; echo "[theme-hook] 原壁纸已删除, 回退到: $(basename "$WP")"; break; }
    done
fi
[[ -f "$WP" ]] || { notify "主题更新失败" "壁纸库为空, 无可回退壁纸"; exit 3; }

# 壁纸未变化时跳过（开机 --restore 场景：无闪刷）
# 仅补 overview 守护壁纸（它开机时是空的），不做取色/不重载
if [[ -f "$ST/current-wallpaper" ]] && [[ "$(cat "$ST/current-wallpaper" 2>/dev/null)" == "$WP" ]]; then
    ok=1
    for f in "${LIVE_FILES[@]}"; do [[ -s "$f" ]] || ok=0; done
    if [[ $ok == 1 ]]; then
        echo "[theme-hook] 壁纸未变化, 跳过主题更新"
        pgrep -f "awww-daemon -n overview" >/dev/null 2>&1 && awww img -n overview "$WP" >/dev/null 2>&1 || true
        exit 0
    fi
    echo "[theme-hook] 颜色文件缺失, 自愈重建"
fi

# 创建必要目录
mkdir -p "$STAGING" "$LASTGOOD"

# ==================== 步骤 1/5：生成候选主题 ====================
echo "[theme-hook] 1/5 生成候选主题: $WP"
# 清理 staging 避免残留文件
rm -f "$STAGING"/*
# matugen：从壁纸提取 Material You 配色
# --mode dark：深色模式
# --prefer saturation：优先饱和度
if ! matugen image "$WP" --config "$CFG" --mode dark --prefer saturation --quiet; then
    notify "主题更新失败" "matugen 取色失败, 保留原主题"
    exit 4
fi

# ==================== 步骤 2/5：验证候选主题 ====================
echo "[theme-hook] 2/5 验证候选主题"
for i in "${!STAGED_FILES[@]}"; do
    f="$STAGING/${STAGED_FILES[$i]}"
    # 检查文件非空且包含预期标记
    if [[ ! -s "$f" ]] || ! grep -qE "${MARKERS[$i]}" "$f"; then
        notify "主题更新失败" "候选文件不完整: ${STAGED_FILES[$i]}, 保留原主题"
        exit 5
    fi
done

# ==================== 步骤 3/5：备份当前主题 ====================
echo "[theme-hook] 3/5 备份当前主题到 last-good"
for i in "${!LIVE_FILES[@]}"; do
    if [[ -f "${LIVE_FILES[$i]}" ]]; then
        cp -f "${LIVE_FILES[$i]}" "$LASTGOOD/${STAGED_FILES[$i]}"
    fi
done

# ==================== 步骤 4/5：原子应用新主题 ====================
echo "[theme-hook] 4/5 原子应用新主题"
for i in "${!LIVE_FILES[@]}"; do
    # mv 是原子操作（同一文件系统下）
    if ! mv -f "$STAGING/${STAGED_FILES[$i]}" "${LIVE_FILES[$i]}"; then
        notify "主题应用失败" "写入 ${LIVE_FILES[$i]} 失败, 正在回滚"
        restore_last_good
        exit 6
    fi
done

# ==================== 步骤 5/5：重载桌面组件 ====================
echo "[theme-hook] 5/5 重载桌面组件"
reload_all

# 同步 overview 背景壁纸（第二个 awww 守护进程）
if pgrep -f "awww-daemon -n overview" >/dev/null 2>&1; then
    awww img -n overview "$WP" >/dev/null 2>&1 || true
fi

# 记录当前壁纸路径和应用时间
printf '%s\n' "$WP" > "$ST/current-wallpaper"
printf '%s\n' "$(date +%s)" > "$ST/last-applied"

# 主题更新成功时静默（用户要求），失败路径仍会 notify
echo "[theme-hook] 完成 ✓"
