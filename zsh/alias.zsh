# ==================== 文件列表命令 ====================
# Eza：现代 ls 替代品，支持图标、Git 状态、树形视图
alias ls='eza --icons'           # 基础列表（带图标）
alias ll='eza -lh --icons --git' # 详细列表（权限、大小、Git 状态）
alias la='eza -lah --icons --git' # 包含隐藏文件的详细列表
alias tree='eza --tree --icons'  # 树形视图

# 复用 ls 的补全函数（避免为 eza 单独定义）
compdef eza=ls

# ==================== 文件查看 ====================
# Bat：带语法高亮和行号的 cat 替代品
alias cat='bat'

# ==================== 系统信息 ====================
alias ff='fastfetch'             # 系统信息展示
alias free='free -h'             # 内存使用（人类可读格式）

# ==================== 核心工具 ====================
# Ripgrep：高速 grep 替代品
alias grep='rg --color=auto'
alias diff='diff --color=auto'   # 带颜色的差异比较
alias df='df -h'                 # 磁盘使用（人类可读格式）

# ==================== 目录导航 ====================
# cd -：跳转到上一个目录
# -- 防止 - 被解析为选项标志
alias -- -='cd -'

# LF 文件管理器集成
# 退出时自动 cd 到最后浏览的目录
lf() {
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

# ==================== 编辑器 ====================
# Neovim 作为默认编辑器
alias vim='nvim'

# ==================== CPU 性能调节 ====================
# cpupower：CPU 频率管理工具
# -u：设置最大频率（封顶 = 软 TDP）
# 注意：TDP 硬件写入被固件拒绝，只能调节软件上限
alias perf-full='sudo cpupower frequency-set -u 5137904 >/dev/null && echo "⚡ 满血 5.14GHz"'
alias perf-bal='sudo cpupower frequency-set -u 4300000 >/dev/null && echo "⚖ 均衡 4.3GHz"'
alias perf-quiet='sudo cpupower frequency-set -u 3200000 >/dev/null && echo "🌙 安静 3.2GHz"'
alias perf-status='echo "当前: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)Hz / 上限: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)Hz"'

# ==================== GPU 监控 ====================
# nvidia-smi：NVIDIA GPU 状态监控
alias ns='nvidia-smi'   # RTX 4060 状态

# nvtop：GPU 使用率 TUI 监控（支持多 GPU）
alias nv='nvtop'        # 780M + 4060

# ==================== Git 工具 ====================
# 简化 Git 日志查看
# PAGER="less -F -X"：单屏时直接退出，退出时不清屏
alias glog='PAGER="less -F -X" git log'
# 图形化显示所有分支的提交历史
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'

# Dotfiles 管理（bare Git 仓库）
# 将 $HOME 作为工作树，独立管理配置文件
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# ==================== 视频工具 ====================
# MPV 摄像头预览（低延迟）
# av://v4l2:/dev/video4：V4L2 视频设备
# --profile=low-latency：低延迟配置
# --untimed：不按时间戳播放（实时预览）
alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'
