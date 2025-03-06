#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_e3c488b7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
is_develop_mode=false
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_e3c488b7%%\/app\/cavasik*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_e3c488b7}" ]; then
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

function cavasik::log_dir() {
    local log_dir="$HOME/.cache/cavasik/log"
    echo "$log_dir"
}

function cavasik::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(cavasik::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_INFO" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function cavasik::run() {
    local count=0
    local plugins=()

    linfo "waiting 10s for hyprland to load plugins"
    sleep 10

    # 确保 hyprland 已经加载完插件
    # 因为 hyprwinwrap 插件可能没安装，所以不能一直循环检查插件是否存在
    while math::lt "$count" 30; do
        if hyprland::hyprctl::self::caller "is_can_connect"; then
            linfo "hyprctl can connect hyprland, count=$count"
            break
        fi
        count=$((count + 1))
        lwarn "hyprctl can not connect hyprland, count=$count, waiting 1s..."
        sleep 1
    done

    if math::ge "$count" 30; then
        lerror "hyprctl tried $count times but still can't connect hyprland"
        return "$SHELL_FALSE"
    fi

    hyprland::hyprctl::instance::plugin::list plugins || return "$SHELL_FALSE"

    if array::is_not_contain plugins "hyprwinwrap"; then
        lerror "hyprwinwrap plugin not loaded, not run cavasik"
        return "$SHELL_FALSE"
    fi

    linfo "hyprwinwrap plugin loaded, start run cavasik"

    flatpak run io.github.TheWisker.Cavasik || return "$SHELL_FALSE"
}

function cavasik::main() {
    cavasik::set_log || return "$SHELL_FALSE"

    cavasik::run || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

cavasik::main "$@"
