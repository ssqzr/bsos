#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_23248a22="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "${SCRIPT_DIR_23248a22}/../lib/utils/all.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR_23248a22}/base.sh"

function manager::flow::apps::do_command() {
    local command="$1"
    shift
    local is_reverse="${1:-false}"
    shift

    local top_apps=()
    # shellcheck disable=SC2034
    local cache_apps=()
    local exclude_apps=()
    local pm_app

    linfo "all apps do command(${command}) start..."

    config::cache::top_apps::all top_apps || return "$SHELL_FALSE"

    config::cache::exclude_apps::all exclude_apps || return "$SHELL_FALSE"

    ldebug "top_apps=${top_apps[*]}"
    ldebug "exclude_apps=${exclude_apps[*]}"

    # 卸载等操作，需要逆向操作
    if string::is_true "${is_reverse}"; then
        array::reverse top_apps
        ldebug "top_apps reverse=${top_apps[*]}"
    fi

    for pm_app in "${top_apps[@]}"; do
        manager::app::do_command cache_apps exclude_apps "${command}" "${pm_app}" "${is_reverse}" || return "$SHELL_FALSE"
    done

    linfo "all apps do command(${command}) end."

    return "$SHELL_TRUE"
}

# 更新整个系统
# - 通过包管理器更新系统
# - 更新所有应用
function manager::flow::upgrade_system() {
    local exit_code=0
    # 先更新系统
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system first..."
    tui::components::spinner::main --title="upgrade system..." exit_code package_manager::upgrade_all_pm || return "$SHELL_FALSE"
    if [ $exit_code -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system failed."
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "upgrade system success."

    return "$SHELL_TRUE"
}

############################## 升级流程 ##############################

function manager::flow::upgrade::main() {
    manager::flow::upgrade_system || return "$SHELL_FALSE"
    manager::flow::apps::do_command "upgrade" || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

############################## 安装流程 ##############################

# 安装流程的前置操作
function manager::flow::install::pre_install() {
    return "$SHELL_TRUE"
}

# 安装流程的安装操作
function manager::flow::install::install() {

    # 运行安装指引
    manager::flow::apps::do_command "install_guide" || return "$SHELL_FALSE"

    tui::confirm "Install Wizard completed. Next Step?"
    if [ "$?" -ne "$SHELL_TRUE" ]; then
        lwarn "install wizard completed, user canceled continue."
        return "$SHELL_FALSE"
    fi

    # 运行安装
    manager::flow::apps::do_command "pre_install" || return "$SHELL_FALSE"
    manager::flow::apps::do_command "install" || return "$SHELL_FALSE"
    manager::flow::apps::do_command "post_install" || return "$SHELL_FALSE"

    # 运行 app 的 fixme 钩子
    manager::flow::apps::do_command "fixme" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 安装流程的后置操作
function manager::flow::install::post_install() {
    return "$SHELL_TRUE"
}

function manager::flow::install::main() {
    manager::flow::upgrade_system || return "$SHELL_FALSE"
    manager::flow::install::pre_install || return "$SHELL_FALSE"
    manager::flow::install::install || return "$SHELL_FALSE"
    manager::flow::install::post_install || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

############################## 卸载流程 ##############################

function manager::flow::uninstall::pre_uninstall() {
    return "$SHELL_TRUE"
}

function manager::flow::uninstall::uninstall() {
    # 运行卸载
    manager::flow::apps::do_command "pre_uninstall" "true" || return "$SHELL_FALSE"
    manager::flow::apps::do_command "uninstall" "true" || return "$SHELL_FALSE"
    manager::flow::apps::do_command "post_uninstall" "true" || return "$SHELL_FALSE"

    manager::flow::apps::do_command "unfixme" "true" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flow::uninstall::post_uninstall() {
    return "$SHELL_TRUE"
}

function manager::flow::uninstall::main() {
    manager::flow::uninstall::pre_uninstall || return "$SHELL_FALSE"
    manager::flow::uninstall::uninstall || return "$SHELL_FALSE"
    manager::flow::uninstall::post_uninstall || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

############################## fixme 流程 ##############################

function manager::flow::fixme::main() {
    manager::flow::upgrade_system || return "$SHELL_FALSE"

    manager::flow::apps::do_command "fixme" || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}

############################## unfixme 流程 ##############################

function manager::flow::unfixme::main() {
    manager::flow::apps::do_command "unfixme" "true" || return "$SHELL_FALSE"

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "you should reboot you system."

    return "$SHELL_TRUE"
}
