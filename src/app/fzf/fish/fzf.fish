#!/bin/fish

set -l SCRIPT_DIR (realpath (status dirname))

# fzf 配置
function fish::fzf::setup
    set -l dir ""
    if set -q XDG_CONFIG_HOME
        set -l dir "$XDG_CONFIG_HOME"
    else
        set -l dir "$HOME/.config"
    end
    set -U FZF_DEFAULT_OPTS_FILE "$dir/fzf/fzfrc"
    # Set up fzf key bindings and fuzzy completion
    fzf --fish | source
end

fish::fzf::setup
