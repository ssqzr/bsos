#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_23248a22="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "${SCRIPT_DIR_23248a22}/base.sh"

# 运行所有程序的安装向导
function install_flow::app::do_guide() {
    linfo "start run all apps guide..."

    local top_apps=()
    # shellcheck disable=SC2034
    local cache_apps=()
    local exclude_apps=()
    local pm_app

    config::cache::top_apps::all top_apps || return "$SHELL_FALSE"

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    for pm_app in "${top_apps[@]}"; do
        manager::app::install_guide cache_apps exclude_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function install_flow::app::install() {
    local top_apps=()
    local exclude_apps=()
    local pm_app
    # shellcheck disable=SC2034
    local cache_apps=()

    linfo "start run apps install..."

    config::cache::top_apps::all top_apps || return "$SHELL_FALSE"

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    for pm_app in "${top_apps[@]}"; do
        manager::app::install cache_apps exclude_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function install_flow::app::upgrade() {
    local top_apps=()
    local exclude_apps=()
    local pm_app
    # shellcheck disable=SC2034
    local apps_d10a6218=()

    linfo "start run apps upgrade..."

    config::cache::top_apps::all top_apps || return "$SHELL_FALSE"

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    for pm_app in "${top_apps[@]}"; do
        manager::app::upgrade apps_d10a6218 exclude_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function install_flow::app::do_fixme() {
    local exclude_apps=()
    local top_apps=()
    local pm_app
    # shellcheck disable=SC2034
    local cache_apps=()

    linfo "start run all apps install fixme..."

    config::cache::top_apps::all top_apps || return "$SHELL_FALSE"

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    for pm_app in "${top_apps[@]}"; do
        manager::app::fixme cache_apps exclude_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

# 更新整个系统
# - 通过包管理器更新系统
# - 更新所有应用
function install_flow::upgrade_all() {
    # 先更新系统
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system first..."
    package_manager::upgrade_all_pm || return "$SHELL_FALSE"
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system success."

    install_flow::app::upgrade || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 安装前置操作
function install_flow::pre_install() {
    return "$SHELL_TRUE"
}

function install_flow::install() {

    # 运行安装指引
    install_flow::app::do_guide || return "$SHELL_FALSE"

    # 运行安装
    install_flow::app::install || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function install_flow::post_install() {
    return "$SHELL_TRUE"
}

function install_flow::do_fixme() {
    # 运行 app 的 fixme 钩子
    install_flow::app::do_fixme || return "$SHELL_FALSE"

    # 运行全局的 fixme 功能
    return "$SHELL_TRUE"
}

function install_flow::main_flow() {
    install_flow::upgrade_all || return "$SHELL_FALSE"
    install_flow::pre_install || return "$SHELL_FALSE"
    install_flow::install || return "$SHELL_FALSE"
    install_flow::post_install || return "$SHELL_FALSE"
    install_flow::do_fixme || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

function install_flow::upgrade_flow() {
    install_flow::upgrade_all || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

function install_flow::fixme_flow() {
    install_flow::upgrade_all || return "$SHELL_FALSE"

    install_flow::do_fixme || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}
