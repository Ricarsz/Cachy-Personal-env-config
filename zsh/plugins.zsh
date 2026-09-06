# ==================== 插件管理器 ====================
# 轻量级插件管理方案（无需第三方插件管理器）
# 插件存储在 $ZDOTDIR/plugins/ 目录下

# 插件目录路径
ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"

# 插件加载函数
# 参数：$1=GitHub 用户名，$2=仓库名
# 功能：自动克隆不存在的插件，然后加载
_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  
  # 插件不存在时自动安装
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    # --depth=1：浅克隆，只获取最新提交（节省空间和时间）
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi
  
  # 加载插件（标准命名约定：仓库名.plugin.zsh）
  source "${plugin_path}/${2}.plugin.zsh"
}

# 插件更新函数
# 遍历所有已安装插件，执行 fast-forward 合并
zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    # --ff-only：仅快进合并，避免冲突
    git -C "$dir" pull --ff-only
  done
}

# ==================== 已安装插件 ====================
# 自动补全建议（基于历史记录）
_zplugin_load zsh-users zsh-autosuggestions

# 历史子串搜索（上下箭头搜索历史命令）
_zplugin_load zsh-users zsh-history-substring-search

# Vi 模式（可选的键绑定方案）
_zplugin_load jeffreytse zsh-vi-mode

# 语法高亮（命令正确性实时标色）
_zplugin_load zdharma-continuum fast-syntax-highlighting
