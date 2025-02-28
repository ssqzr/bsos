#!/bin/fish

set -l SCRIPT_DIR (realpath (status dirname))

# wallust 配置
function fish::starship::setup
    set -l dir ""
    if set -q XDG_CONFIG_HOME
        set dir "$XDG_CONFIG_HOME"
    else
        set dir "$HOME/.config"
    end

    set -x STARSHIP_CONFIG "$dir/starship/starship.toml"
    starship init fish | source
end


fish::starship::setup
