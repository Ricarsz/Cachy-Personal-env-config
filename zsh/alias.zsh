# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat
alias cat='bat'

alias ff='fastfetch'
alias free='free -h'

# =========================================================
# Core utilities
# =========================================================

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory

lf() { # zsh follow lf navigation
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

# =========================================================
# Editor
# =========================================================

alias vim='nvim'

# =========================================================
# 性能调整 (频率封顶 = 软 TDP; TDP 硬件写入被固件拒, 详见 docu)
# =========================================================

alias perf-full='sudo cpupower frequency-set -u 5137904 >/dev/null && echo "⚡ 满血 5.14GHz"'
alias perf-bal='sudo cpupower frequency-set -u 4300000 >/dev/null && echo "⚖ 均衡 4.3GHz"'
alias perf-quiet='sudo cpupower frequency-set -u 3200000 >/dev/null && echo "🌙 安静 3.2GHz"'
alias perf-status='echo "当前: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)Hz / 上限: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)Hz"'

# =========================================================
# GPU
# =========================================================

alias ns='nvidia-smi'   # RTX 4060 状态
alias nv='nvtop'        # GPU 监控 TUI (780M + 4060)

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# =========================================================
# Video
# =========================================================

alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'
