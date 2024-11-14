#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_b2e4a0ea="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "${SCRIPT_DIR_b2e4a0ea}/base.sh"

function uninstall_flow::app::uninstall() {
    local top_apps=()
    local exclude_apps=()
    local pm_app
    local cache_apps=()
    local temp_str

    linfo "start run apps uninstall..."

    temp_str="$(config::cache::top_apps::all)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    # 因为优先安装的APP在最前面，所以这里reverse一下
    array::reverse top_apps
    ldebug "top_apps reverse=${top_apps[*]}"

    for pm_app in "${top_apps[@]}"; do
        manager::app::uninstall cache_apps exclude_apps "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

function uninstall_flow::app::do_unfixme() {
    local top_apps=()
    local exclude_apps=()
    local temp_str
    local cache_apps=()
    linfo "start run apps unfixme..."

    temp_str="$(config::cache::top_apps::all)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    # 因为优先安装的APP在最前面，所以这里reverse一下
    array::reverse top_apps
    ldebug "top_apps reverse=${top_apps[*]}"

    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::unfixme cache_apps exclude_apps "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

function uninstall_flow::pre_uninstall() {
    return "$SHELL_TRUE"
}

function uninstall_flow::uninstall() {
    # 运行卸载
    uninstall_flow::app::uninstall || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function uninstall_flow::post_uninstall() {
    return "$SHELL_TRUE"
}

function uninstall_flow::do_unfixme() {
    uninstall_flow::app::do_unfixme || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function uninstall_flow::main_flow() {
    uninstall_flow::do_unfixme || return "$SHELL_FALSE"
    uninstall_flow::pre_uninstall || return "$SHELL_FALSE"
    uninstall_flow::uninstall || return "$SHELL_FALSE"
    uninstall_flow::post_uninstall || return "$SHELL_FALSE"
    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

function uninstall_flow::unfixme_flow() {
    uninstall_flow::do_unfixme || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}
