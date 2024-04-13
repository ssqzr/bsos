#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_b2e4a0ea="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

function uninstall_flow::app::do_uninstall() {
    local top_apps=()
    local temp_str
    linfo "start run apps uninstall..."

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    ldebug "top_apps=${top_apps[*]}"
    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_uninstall "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

function uninstall_flow::pre_uninstall() {
    return "$SHELL_TRUE"
}

function uninstall_flow::do_uninstall() {
    # 运行安装
    uninstall_flow::app::do_uninstall || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function uninstall_flow::post_uninstall() {
    return "$SHELL_TRUE"
}

function uninstall_flow::main_flow() {
    config::cache::uninstalled_apps::clean || return "$SHELL_FALSE"
    uninstall_flow::pre_uninstall || return "$SHELL_FALSE"
    uninstall_flow::do_uninstall || return "$SHELL_FALSE"
    uninstall_flow::post_uninstall || return "$SHELL_FALSE"
    println_success "all success."
    println_warn "you should reboot you system."

    return "$SHELL_TRUE"
}
