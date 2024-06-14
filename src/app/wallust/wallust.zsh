# wallust 的配置
if [ -e "${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences" ]; then
    # 使用指定的壁纸生成的主题颜色
    # 查看以下代码了解会设置终端的哪些颜色
    # https://codeberg.org/explosion-mental/wallust/src/branch/master/src/sequences.rs
    cat "${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"
else
    # 使用随机的主题颜色
    wallust theme -q -u random
fi
if [ -e "${XDG_CACHE_HOME:-$HOME/.cache}/colors/zsh.zsh" ]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/colors/zsh.zsh"
fi
