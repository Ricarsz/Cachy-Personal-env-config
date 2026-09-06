# fzf.zsh — 模糊查找器配置
# FZF：通用模糊查找器，支持文件、历史、进程等搜索

# ==================== 默认命令 ====================
# 使用 fd 作为文件搜索后端（比 find 快 10 倍以上）
# --type f：仅搜索文件（排除目录）
# --hidden：包含隐藏文件
# --strip-cwd-prefix：移除结果中的 ./ 前缀
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'

# Ctrl+T 快捷键使用相同的命令
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ==================== 界面配置 ====================
export FZF_DEFAULT_OPTS='
  --height=60%                          # 窗口高度
  --layout=reverse                      # 从上到下显示
  --border=rounded                      # 圆角边框
  --prompt="  "                        # 提示符图标
  --pointer="  "                       # 选中指针
  --preview-window=right:65%:wrap:border-left  # 预览窗口配置
  --color=bg:#24273a,fg:#cad3f5,fg+:#cad3f5,hl:#f5a97f,hl+:#f5a97f,bg+:#363a4f,header:#f5a97f,border:#1e2030,scrollbar:#1e2030,gutter:#24273a,pointer:#f4dbd6,marker:#f4dbd6,info:#c6a0f6,prompt:#c6a0f6,spinner:#f4dbd6,label:#8aadf4,query:#8aadf4,disabled:#5b6078
'

# ==================== 预览配置 ====================
# 使用 bat 作为文件预览器
# --color=always：保持颜色输出
# --style=plain,numbers：简洁样式 + 行号
# --line-range=:500：最多预览 500 行（避免大文件卡顿）
export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# ==================== 自定义函数 ====================
# Ctrl+F：文件选择器（不包含隐藏文件）
_fzf_file_no_hidden() {
  local cmd result
  # 从默认命令中移除 --hidden 选项
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  # 执行搜索并通过 FZF 选择
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # 将选中结果插入到光标左侧
  zle reset-prompt  # 重绘提示符
}
# 注册为 Zsh 小部件（可绑定到快捷键）
zle -N _fzf_file_no_hidden
