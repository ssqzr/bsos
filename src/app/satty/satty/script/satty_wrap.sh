#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_7e0c77d4="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
is_develop_mode=false
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_7e0c77d4%%\/app\/satty*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_7e0c77d4}" ]; then
    # 方便开发
    is_develop_mode=true
fi
if $is_develop_mode; then
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

function satty::log_dir() {
    local log_dir="$HOME/.cache/satty/log"
    echo "$log_dir"
}

function satty::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(satty::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_INFO" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function satty::hyprland::focused_monitor() {
    local monitors
    monitors=$(hyprland::hyprctl::instance::monitors) || return "${SHELL_FALSE}"
    echo "${monitors}" | yq '.[] | select(.focused == "true")' || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function satty::grim::get_geometry() {
    local focused_monitor
    local x
    local y
    local width
    local height
    local transform
    local temp

    focused_monitor=$(satty::hyprland::focused_monitor) || return "${SHELL_FALSE}"
    x=$(echo "$focused_monitor" | yq '.x') || return "${SHELL_FALSE}"
    y=$(echo "$focused_monitor" | yq '.y') || return "${SHELL_FALSE}"
    width=$(echo "$focused_monitor" | yq '.width') || return "${SHELL_FALSE}"
    height=$(echo "$focused_monitor" | yq '.height') || return "${SHELL_FALSE}"
    transform=$(echo "$focused_monitor" | yq '.transform') || return "${SHELL_FALSE}"

    linfo "focused monitor x=${x}, y=${y}, width=${width}, height=${height}, transform=${transform}"

    case "$transform" in
    1 | 3 | 5 | 7)
        # 旋转90度，宽高互换
        temp=$width
        width=$height
        height=$temp
        ;;
    *) ;;
    esac

    echo "${x},${y} ${width}x${height}"
    return "${SHELL_TRUE}"
}

function satty::screenshot_dir() {
    local screenshot_dir
    screenshot_dir=$(xdg-user-dir PICTURES) || return "${SHELL_FALSE}"
    if string::is_empty "$screenshot_dir"; then
        screenshot_dir="$HOME/Pictures"
    fi
    echo "$screenshot_dir"
    return "${SHELL_TRUE}"
}

function satty::screenshot_filepath() {
    local dir
    dir=$(satty::screenshot_dir) || return "${SHELL_FALSE}"
    echo "${dir}/satty-$(date '+%Y-%m-%d-%H:%M:%S').png"
    return "${SHELL_TRUE}"
}

function satty::screenshot() {
    local geometry
    local screenshot_filepath

    geometry=$(satty::grim::get_geometry) || return "${SHELL_FALSE}"
    screenshot_filepath=$(satty::screenshot_filepath) || return "${SHELL_FALSE}"

    linfo "geometry=${geometry}, screenshot_filepath=${screenshot_filepath}"

    grim -g "$geometry" - | satty --filename - --fullscreen --output-filename "${screenshot_filepath}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function satty::main() {
    satty::set_log || return "$SHELL_FALSE"

    satty::screenshot || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

satty::main "$@"
