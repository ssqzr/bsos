#!/bin/bash

# 详情见：../README.adoc#resume-network-problem

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_b8383e8c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_b8383e8c%%\/app\/power_management*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_b8383e8c}" ]; then
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

function sleep_hook::network::self_filepath() {
    echo "${BASH_SOURCE[0]}"
}

function sleep_hook::network::log_dir() {
    local log_dir="/var/log/bsos/power_management/log"
    echo "$log_dir"
}

function sleep_hook::network::log_filepath() {
    local log_filepath
    local log_filename

    log_filename="$(sleep_hook::network::self_filepath)"
    log_filename="${log_filename##*/}"
    log_filepath="$(sleep_hook::network::log_dir)/${log_filename}.log"
    echo "$log_filepath"
}

function sleep_hook::network::set_log() {
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(sleep_hook::network::log_filepath)" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_INFO" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function sleep_hook::network::restart_network() {
    linfo "start restart network"

    ldebug "restart systemd-networkd.service unit"
    systemctl::restart systemd-networkd.service || return "$SHELL_FALSE"

    linfo "restart network success"
    return "$SHELL_TRUE"
}

function sleep_hook::network::hibernate::post() {
    linfo "hibernate post start"

    sleep_hook::network::restart_network || return "$SHELL_FALSE"

    linfo "hibernate post success"
    return "$SHELL_TRUE"
}

function sleep_hook::network::suspend_then_hibernate::post() {
    linfo "suspend-then-hibernate post start"

    linfo "env SYSTEMD_SLEEP_ACTION=${SYSTEMD_SLEEP_ACTION}"

    # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hooks_in_/usr/lib/systemd/system-sleep
    if [ "${SYSTEMD_SLEEP_ACTION}" != "hibernate" ]; then
        # 只处理休眠，挂起暂时没发现问题
        linfo "env SYSTEMD_SLEEP_ACTION=${SYSTEMD_SLEEP_ACTION}, suspend-then-hibernate post skip, not hibernate"
        return "$SHELL_TRUE"
    fi
    sleep_hook::network::restart_network || return "$SHELL_FALSE"

    linfo "suspend-then-hibernate post success"
    return "$SHELL_TRUE"
}

function sleep_hook::network::main() {
    local moment="$1"
    shift
    local action="$1"
    shift

    sleep_hook::network::set_log || return "$SHELL_FALSE"

    # 记录信息到 journalctl 日志，留下蛛丝马迹方便溯源。
    echo "hook moment=$moment, action=$action, check $(sleep_hook::network::self_filepath) log file($(sleep_hook::network::log_filepath))"

    linfo "hook moment=$moment, action=$action"

    case $moment/$action in
    post/hibernate)
        sleep_hook::network::hibernate::post || return "$SHELL_FALSE"
        ;;
    post/suspend-then-hibernate)
        sleep_hook::network::suspend_then_hibernate::post || return "$SHELL_FALSE"
        ;;
    pre/* | post/*) ;;
    *)
        lerror "unknown moment=$moment, action=$action"
        return "$SHELL_FALSE"
        ;;
    esac

    linfo "hook moment=$moment, action=$action success."

    return "$SHELL_TRUE"
}

sleep_hook::network::main "$@"
