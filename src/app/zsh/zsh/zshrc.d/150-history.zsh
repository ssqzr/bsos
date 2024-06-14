# 设置 history
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#index-HISTFILE
# 查看 history.zsh 对 HIST_STAMPS 的用处，执行 history 命令时会打印执行命令的时间
HIST_STAMPS="%Y-%m-%d %k:%M:%S"
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/lib/history.zsh"