#!/bin/fish

set -l SCRIPT_DIR (realpath (status dirname))

# wallust 配置
function fish::wallust::setup
    set -l dir ""
    if set -q XDG_CACHE_HOME
        set -l dir "$XDG_CACHE_HOME"
    else
        set -l dir "$HOME/.cache"
    end

    if test -e "$dir/wallust/sequences"
        # 使用指定的壁纸生成的主题颜色
        # 查看以下代码了解会设置终端的哪些颜色
        # https://codeberg.org/explosion-mental/wallust/src/branch/master/src/sequences.rs
        cat "$dir/wallust/sequences"
    end

    # 使用随机的主题颜色
    alias wallust-random "wallust theme -q -u -T random"
    wallust-random
end

if status --is-interactive
    fish::wallust::setup
end
