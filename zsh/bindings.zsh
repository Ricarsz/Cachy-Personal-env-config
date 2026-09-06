# ==================== 快捷键配置 ====================

# Vi 模式光标形状
# 插入模式：竖线光标（I-beam）
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
# 普通模式：块状光标
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
# 可视模式：块状光标
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# 禁用命令模式行高亮（减少视觉干扰）
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode 初始化时会重置所有快捷键
# 必须通过 zvm_after_init 钩子注册自定义绑定
zvm_after_init() {
  # Ctrl+右箭头：向前跳转一个单词
  # ^[[1;5C 是终端转义码（CSI 序列）
  bindkey '^[[1;5C' forward-word

  # Ctrl+左箭头：向后跳转一个单词
  bindkey '^[[1;5D' backward-word

  # Ctrl+F：FZF 文件选择器（不包含隐藏文件）
  bindkey '^F' _fzf_file_no_hidden

  # Ctrl+\：切换自动建议（录屏时很有用）
  bindkey '^\' autosuggest-toggle

  # 上/下箭头：历史子串搜索
  # ^[[A/^[[B 是箭头键的终端转义码
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}
