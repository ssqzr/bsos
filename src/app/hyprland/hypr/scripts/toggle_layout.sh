#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_cb208024="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_cb208024%%\/app\/hyprland*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_cb208024}" ]; then
    # 方便开发
    source_filepath="$src_dir/lib/utils/all.sh"
else
    source_filepath="/usr/share/bsos/bash/utils/all.sh"
    if [ ! -e "$source_filepath" ]; then
        echo "path $source_filepath not exist"
        exit 1
    fi
fi
# shellcheck disable=SC1090
source "$source_filepath" || exit 1

function hyprland::toggle_layout::log_dir() {
    local log_dir="$HOME/.cache/hypr/log"
    echo "$log_dir"
}

function hyprland::toggle_layout::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(hyprland::toggle_layout::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_DEBUG" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprland::toggle_layout::current_layout() {
    local layout
    layout=$(hyprctl getoption general:layout -j | yq '.str')
    layout=$(string::trim "$layout")
    echo "$layout"
    return "$SHELL_TRUE"
}

function hyprland::toggle_layout::toggle() {
    local layout
    local toggle_layout
    layout=$(hyprland::toggle_layout::current_layout) || return "$SHELL_FALSE"
    ldebug "current layout: $layout"

    case "$layout" in
    master)
        toggle_layout="dwindle"
        ;;
    dwindle)
        toggle_layout="master"
        ;;
    *)
        lerror "unknown layout: $layout"
        return "$SHELL_FALSE"
        ;;
    esac

    ldebug "set layout to $toggle_layout"
    cmd::run_cmd_with_history -- hyprctl keyword general:layout "$toggle_layout" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function hyprland::toggle_layout::_main() {
    hyprland::toggle_layout::set_log || return "$SHELL_FALSE"
    hyprland::toggle_layout::toggle || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

hyprland::toggle_layout::_main "$@"
