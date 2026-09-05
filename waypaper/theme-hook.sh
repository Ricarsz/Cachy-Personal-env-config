#!/usr/bin/env bash
# ============================================================================
# theme-hook.sh — 动态主题事务性更新脚本
# ============================================================================
# 工作流:
#   waypaper 选择壁纸 ($wallpaper)
#     -> 本脚本调用 matugen 从壁纸生成 Material You 配色到 staging/
#     -> 验证 staging 产物完整性
#     -> 把当前正在使用的 5 个颜色文件备份到 last-good/
#     -> 原子移动(mv) staging 产物到真实配置路径
#     -> 重载各组件 (niri / waybar / mako / fuzzel无需重载 / ghostty见下)
#   任何一步失败:
#     -> 自动从 last-good/ 恢复所有颜色文件并重载, 桌面回到上一个可用主题
#
# 手动恢复: theme-hook.sh --restore
# 手动换色: theme-hook.sh /path/to/wallpaper.png
#
# 状态目录: ~/.local/state/dynamic-theme/
#   staging/          matugen 生成候选区
#   last-good/        最近一次验证通过的配色快照
#   current-wallpaper 当前生效的壁纸路径
#   ghostty-usrs2-ok  标记: 实测本机 ghostty 支持 SIGUSR2 热重载时创建
#
# 详见 ~/docu/desktop/dynamic-theme.md
# ============================================================================
set -uo pipefail

ST="$HOME/.local/state/dynamic-theme"
STAGING="$ST/staging"
LASTGOOD="$ST/last-good"
CFG="$HOME/.config/matugen/config.toml"
TERMINAL_NOTIFY="${TERMINAL_NOTIFY:-1}"

# 颜色文件: staging 文件名 -> 真实目标路径 (顺序一一对应)
STAGED_FILES=(waybar-colors.css fuzzel-colors.ini mako-colors.conf ghostty-colors niri-colors.kdl)
LIVE_FILES=(
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/fuzzel/colors.ini"
    "$HOME/.config/mako/colors.conf"
    "$HOME/.config/ghostty/colors"
    "$HOME/.config/niri/colors.kdl"
)
# 每个文件的验证标记 (生成内容完整性检查)
MARKERS=('@define-color background' '^background=' '^background-color=' '^palette = 0=' 'focus-ring')

notify() {
    if [[ "$TERMINAL_NOTIFY" == "1" ]] && command -v notify-send >/dev/null; then
        notify-send -a "Dynamic Theme" "$1" "$2" 2>/dev/null
    fi
    echo "[theme-hook] $1: $2"
}

reload_all() {
    niri msg action load-config-file >/dev/null 2>&1 || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    makoctl reload >/dev/null 2>&1 || true
    # ghostty: 仅当实测支持 SIGUSR2 热重载后才启用 (存在标记文件)
    if [[ -f "$ST/ghostty-usrs2-ok" ]]; then
        pkill -SIGUSR2 ghostty 2>/dev/null || true
    fi
}

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

# ---------------------------------------------------------------- restore 模式
if [[ "${1:-}" == "--restore" ]]; then
    if restore_last_good; then
        notify "主题已恢复" "已恢复到最近一次可用主题 (last-good)"
        exit 0
    else
        notify "恢复失败" "last-good 快照不存在或恢复出错"
        exit 1
    fi
fi

# ---------------------------------------------------------------- 主流程
WP="${1:-}"
if [[ -z "$WP" ]]; then
    echo "用法: theme-hook.sh <壁纸路径> | --restore" >&2
    exit 2
fi
# waypaper 传来的路径可能带转义空格 (反斜杠), 若原样不存在则尝试反转义
if [[ ! -f "$WP" ]]; then
    WP="$(printf '%b' "${WP//\\/}")"
fi
WP="$(readlink -f "$WP")"

# ─── 壁纸文件不存在 → 静默回退 (记录 → 壁纸库第一张) ───
# 场景: 用户删了 waypaper 里记录的壁纸; 开机恢复失败时不弹告警
if [[ ! -f "$WP" ]]; then
    for cand in "$(cat "$ST/current-wallpaper" 2>/dev/null)" "$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)"; do
        [[ -n "$cand" && -f "$cand" ]] && { WP="$(readlink -f "$cand")"; echo "[theme-hook] 原壁纸已删除, 回退到: $(basename "$WP")"; break; }
    done
fi
[[ -f "$WP" ]] || { notify "主题更新失败" "壁纸库为空, 无可回退壁纸"; exit 3; }

# ─── 壁纸未变化 → 静默跳过 (开机 --restore 场景: 无闪刷) ───
# 仅补 overview 守护壁纸 (它开机时是空的), 不做取色/不重载任何应用
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

mkdir -p "$STAGING" "$LASTGOOD"

echo "[theme-hook] 1/5 生成候选主题: $WP"
# 深色模式固定 dark (本桌面为深色主题); 每次都清理 staging 避免残留
rm -f "$STAGING"/*
if ! matugen image "$WP" --config "$CFG" --mode dark --prefer saturation --quiet; then
    notify "主题更新失败" "matugen 取色失败, 保留原主题"
    exit 4
fi

echo "[theme-hook] 2/5 验证候选主题"
for i in "${!STAGED_FILES[@]}"; do
    f="$STAGING/${STAGED_FILES[$i]}"
    if [[ ! -s "$f" ]] || ! grep -qE "${MARKERS[$i]}" "$f"; then
        notify "主题更新失败" "候选文件不完整: ${STAGED_FILES[$i]}, 保留原主题"
        exit 5
    fi
done

echo "[theme-hook] 3/5 备份当前主题到 last-good"
for i in "${!LIVE_FILES[@]}"; do
    if [[ -f "${LIVE_FILES[$i]}" ]]; then
        cp -f "${LIVE_FILES[$i]}" "$LASTGOOD/${STAGED_FILES[$i]}"
    fi
done

echo "[theme-hook] 4/5 原子应用新主题"
for i in "${!LIVE_FILES[@]}"; do
    if ! mv -f "$STAGING/${STAGED_FILES[$i]}" "${LIVE_FILES[$i]}"; then
        notify "主题应用失败" "写入 ${LIVE_FILES[$i]} 失败, 正在回滚"
        restore_last_good
        exit 6
    fi
done

echo "[theme-hook] 5/5 重载桌面组件"
reload_all

# overview 总览背景壁纸: 同步设置到第二个 awww 守护 (namespace=overview)
if pgrep -f "awww-daemon -n overview" >/dev/null 2>&1; then
    awww img -n overview "$WP" >/dev/null 2>&1 || true
fi

printf '%s\n' "$WP" > "$ST/current-wallpaper"
printf '%s\n' "$(date +%s)" > "$ST/last-applied"
# 用户要求: 主题更新成功时不弹通知 (静默); 失败路径仍会 notify
echo "[theme-hook] 完成 ✓"
