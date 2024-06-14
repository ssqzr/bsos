# 配置自动补全
autoload -U compinit promptinit
compinit
promptinit

# 设置 walters 主题的默认命令行提示符
#prompt walters

# 方向键控制的自动补全
zstyle ':completion:*' menu select
# 命令行别名的自动补全
setopt completealiases
# 消除历史记录中的重复条目
# 体验下来并不好，不能知道最近执行的命令
# setopt HIST_IGNORE_DUPS

# 刷新自动补全
zstyle ':completion:*' rehash true


# https://unix.stackexchange.com/questions/557486/allowing-comments-in-interactive-zsh-commands
# 允许在交互模式中使用注释
# `echo "abc" # 这是注释` 将输出 abc
# 否则会报错
setopt INTERACTIVE_COMMENTS