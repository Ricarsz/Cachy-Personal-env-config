# prompt.zsh — 提示符配置
# 使用 Starship 跨 shell 提示符框架

# 禁用 Python 虚拟环境的默认提示符
# Starship 会自行显示虚拟环境状态，避免重复
export VIRTUAL_ENV_DISABLE_PROMPT=1

# 函数嵌套深度限制
# 防止递归函数导致栈溢出（默认值可能过低）
FUNCNEST=100

# 初始化 Starship 提示符
# Starship 会注入 precmd/preexec 钩子来动态更新提示符
eval "$(starship init zsh)"
