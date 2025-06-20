#!/bin/fish

set -l SCRIPT_DIR (realpath (status dirname))

# fifc 配置
function fish::fifc::setup
    set -Ux fifc_editor vim
    # Bind fzf completions to ctrl-x
    set -U fifc_keybinding \cx
end

fish::fifc::setup
