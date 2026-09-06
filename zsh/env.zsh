# env.zsh — 用户环境变量配置
# 由 .zshenv 全局加载，所有 shell 会话生效
# 包括非交互式 shell（如脚本、Git 子进程等）

# ==================== 编辑器配置 ====================
# Zed 编辑器（图形环境优先）
# --wait：阻塞等待编辑完成（Git commit 等场景必需）
# 回退：TTY/无图形环境使用 nano
if [[ -n "$WAYLAND_DISPLAY$DISPLAY" ]] && command -v zeditor >/dev/null 2>&1; then
    export EDITOR="zeditor --wait"
    export VISUAL="$EDITOR"
else
    export EDITOR="nano"
    export VISUAL="$EDITOR"
fi

# ==================== 分页器配置 ====================
# Less：功能强大的分页器
export PAGER="less"
# -R：支持 ANSI 颜色转义码（保持语法高亮）
export LESS="-R"
# -：禁用 less 历史文件（隐私考虑）
export LESSHISTFILE="-"

# ==================== FZF 配置 ====================
# FZF：模糊查找器默认选项
# --height=40%：窗口占终端高度的 40%
# --layout=reverse：从上到下显示结果（更符合直觉）
# --border：显示边框
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"

# ==================== Node.js 说明 ====================
# Node.js 统一由 FNM（Fast Node Manager）管理
# 详见 .zshrc 中的 fnm env 配置
# paru 作为依赖带入的系统 Node.js 仅作兜底，无需在此配置
