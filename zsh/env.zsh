# env.zsh — 用户环境变量 (由 .zshenv 全局加载, 所有 shell 会话生效)
# 2026-09-05 定制

# ---------- 编辑器: Zed (zeditor) ----------
# --wait: git commit 等阻塞等待编辑完成
# TTY/无图形环境回退 nano
if [[ -n "$WAYLAND_DISPLAY$DISPLAY" ]] && command -v zeditor >/dev/null 2>&1; then
    export EDITOR="zeditor --wait"
    export VISUAL="$EDITOR"
else
    export EDITOR="nano"
    export VISUAL="$EDITOR"
fi

# ---------- 分页器 ----------
export PAGER="less"
export LESS="-R"
export LESSHISTFILE="-"

# ---------- fzf ----------
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"

# ---------- Node.js 说明 ----------
# Node.js 统一由 fnm 管理 (见 .zshrc 的 fnm env);
# paru 作为依赖带入的系统 node 仅作兜底, 无需在此配置
