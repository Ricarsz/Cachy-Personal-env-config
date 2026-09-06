# Zsh 配置文件
#
# 功能模块：
#   插件管理：fast-syntax-highlighting, zsh-autosuggestions,
#             zsh-history-substring-search, zsh-vi-mode
#   提示符：  starship
#   导航工具：zoxide, fzf, fd
#   CLI 工具：eza, bat, nvim, ripgrep
#   Node.js：fnm (Fast Node Manager)

# ==================== 历史记录配置 ====================
# 历史记录文件路径（遵循 XDG 规范）
HISTFILE="$XDG_STATE_HOME/zsh/history"

# 内存中保留的历史记录数量
HISTSIZE=100000

# 保存到文件的历史记录数量
SAVEHIST=100000

# 历史记录选项
setopt APPEND_HISTORY      # 追加模式（而非覆盖）
setopt SHARE_HISTORY       # 多终端共享历史
setopt HIST_IGNORE_DUPS    # 忽略连续重复命令
setopt HIST_IGNORE_SPACE   # 忽略以空格开头的命令（敏感命令）
setopt HIST_EXPIRE_DUPS_FIRST  # 优先淘汰重复命令
setopt HIST_FIND_NO_DUPS   # 搜索时不显示重复项

# ==================== Shell 行为配置 ====================
setopt AUTOCD              # 输入目录名直接 cd
setopt NOBEEP              # 禁用蜂鸣提示音
setopt NUMERIC_GLOB_SORT   # 数字排序：file10 在 file9 之后

# ==================== 智能导航和文件管理器 ====================
# LF 文件管理器图标配置
if [[ -f ~/.config/lf/icons ]]; then
  LF_ICONS=$(cat ~/.config/lf/icons | tr '\n' ':')
  export LF_ICONS
fi

# Zoxide：智能目录跳转
# 基于访问频率的目录历史，支持 z <关键词> 快速跳转
eval "$(zoxide init zsh)"

# FNM：Fast Node Manager
# --use-on-cd：进入包含 .nvmrc/.node-version 的目录时自动切换 Node 版本
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# ==================== 自动补全系统 ====================
# 加载补全系统（-U：延迟加载，-z：zsh 风格）
autoload -Uz compinit

# 初始化补全，使用缓存文件加速启动
# -d：指定缓存文件路径（避免重复计算）
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# 启用交互式补全菜单（方向键选择）
zstyle ':completion:*' menu select

# 大小写不敏感匹配
# "doc" 可以匹配 "Documents"、"DOCS" 等
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ==================== 模糊查找器（FZF）====================
# 自动检测 FZF 安装位置并加载
# 支持多种包管理器和手动安装

# macOS / Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

# macOS / Homebrew (Intel)
if [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# Arch Linux
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# Ubuntu/Debian
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# 手动 Git 克隆安装
if [[ -f "$HOME/.fzf/shell/key-bindings.zsh ]]; then
  source "$HOME/.fzf/shell/key-bindings.zsh"
  source "$HOME/.fzf/shell/completion.zsh"
fi

# ==================== 模块化配置文件 ====================
# 将配置拆分为独立文件，便于管理和复用

# FZF 配置（快捷键、外观、行为）
source "$ZDOTDIR/fzf.zsh"

# 命令别名
source "$ZDOTDIR/alias.zsh"

# 自定义快捷键绑定
source "$ZDOTDIR/bindings.zsh"

# 插件和插件管理器配置
source "$ZDOTDIR/plugins.zsh"

# 提示符/主题配置
source "$ZDOTDIR/prompt.zsh"

# ==================== 用户自定义配置 ====================
# 本地配置文件（不纳入版本控制）
# 用于存放机器特定的配置（如 PATH、环境变量等）
if [[ -f "$ZDOTDIR/local.zsh" ]]; then
  source "$ZDOTDIR/local.zsh"
fi
