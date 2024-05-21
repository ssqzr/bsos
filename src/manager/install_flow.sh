#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_23248a22="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "${SCRIPT_DIR_23248a22}/base.sh"

# 运行所有程序的安装向导
function install_flow::app::do_guide() {
    linfo "start run all apps guide..."

    local top_apps=()
    local temp_str
    local _36317254_cache_apps=()

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    ldebug "top_apps=${top_apps[*]}"
    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_install_guide _36317254_cache_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function install_flow::app::do_install() {
    local top_apps=()
    local temp_str
    linfo "start run apps install..."

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    ldebug "top_apps=${top_apps[*]}"
    local pm_app
    local _6ce8e784_installed_apps=()
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_install _6ce8e784_installed_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function install_flow::app::do_fixme() {
    local top_apps=()
    local temp_str
    local _b81225cf_cache_apps=()
    linfo "start run all apps install fixme..."

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    ldebug "top_apps=${top_apps[*]}"
    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_fixme _b81225cf_cache_apps "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

# 安装前置操作
function install_flow::pre_install() {
    return "$SHELL_TRUE"
}

function install_flow::do_install() {

    # 运行安装指引
    install_flow::app::do_guide || return "$SHELL_FALSE"

    # 运行安装
    install_flow::app::do_install || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# FIXME: 验证功能没有问题
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
    # 先更新系统
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system first..."
    package_manager::upgrade_all_pm || return "$SHELL_FALSE"
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system success."

    install_flow::pre_install || return "$SHELL_FALSE"
    install_flow::do_install || return "$SHELL_FALSE"
    install_flow::post_install || return "$SHELL_FALSE"
    install_flow::do_fixme || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

function install_flow::fixme_flow() {
    # 先更新系统
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system first..."
    package_manager::upgrade_all_pm || return "$SHELL_FALSE"
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system success."

    install_flow::do_fixme || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}
