#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_3e368da0="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_3e368da0%%\/app\/hyprland*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_3e368da0}" ]; then
    # 方便开发
    source_filepath="$src_dir/lib/utils/all.sh"
else
    source_filepath="$HOME/.bash_lib/utils/all.sh"
    if [ ! -e "$source_filepath" ]; then
        echo "path $source_filepath not exist"
        exit 1
    fi
fi
# shellcheck disable=SC1090
source "$source_filepath" || exit 1

declare __zoom_duration="0.5"

function hyprland::zoom::log_dir() {
    local log_dir="$HOME/.cache/hypr/log"
    echo "$log_dir"
}

function hyprland::zoom::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(hyprland::zoom::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_DEBUG" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprland::zoom::current_factor() {
    local factor
    factor=$(hyprctl getoption misc:cursor_zoom_factor -j | yq '.float')
    factor=$(string::trim "$factor")
    echo "$factor"
    return "$SHELL_TRUE"
}

function hyprland::zoom::in() {
    local factor
    factor=$(hyprland::zoom::current_factor) || return "$SHELL_FALSE"
    ldebug "current cursor factor: $factor"

    if [[ "$factor" =~ ^[0-].* ]]; then
        ldebug "current cursor($factor) is less than 1, reset to 1"
        factor="1"
    fi

    factor=$(awk "BEGIN{printf \"%.2f%%\n\",(${factor}+${__zoom_duration})}")

    ldebug "set cursor factor: $factor"
    cmd::run_cmd_with_history -- hyprctl keyword misc:cursor_zoom_factor "$factor"
    return "$SHELL_TRUE"
}

function hyprland::zoom::out() {
    local factor
    factor=$(hyprland::zoom::current_factor) || return "$SHELL_FALSE"
    ldebug "current cursor factor: $factor"

    factor=$(awk "BEGIN{printf \"%.2f%%\n\",(${factor}-${__zoom_duration})}")
    if [[ "$factor" =~ ^[0-].* ]]; then
        ldebug "computed zoom out cursor($factor) is less than 1, reset to 1"
        factor="1"
    fi

    ldebug "set cursor factor: $factor"
    cmd::run_cmd_with_history -- hyprctl keyword misc:cursor_zoom_factor "$factor"
    return "$SHELL_TRUE"
}

function hyprland::zoom::_main() {
    local command="$1"

    hyprland::zoom::set_log || return "$SHELL_FALSE"

    case "$command" in
    in)
        hyprland::zoom::in || return "$SHELL_FALSE"
        ;;
    out)
        hyprland::zoom::out || return "$SHELL_FALSE"
        ;;
    esac
    return "$SHELL_TRUE"
}

hyprland::zoom::_main "$@"
