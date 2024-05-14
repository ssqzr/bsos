#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_b2e4a0ea="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "${SCRIPT_DIR_b2e4a0ea}/base.sh"

function uninstall_flow::app::do_uninstall() {
    local top_apps=()
    local temp_str
    linfo "start run apps uninstall..."

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")
    ldebug "top_apps=${top_apps[*]}"

    # 因为优先安装的APP在最前面，所以这里reverse一下
    array::reverse top_apps
    ldebug "top_apps reverse=${top_apps[*]}"

    local pm_app
    local _532b27d8_uninstall_apps=()
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_uninstall _532b27d8_uninstall_apps "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

function uninstall_flow::app::do_unfixme() {
    local top_apps=()
    local temp_str
    local _691b5ab9_cache_apps=()
    linfo "start run apps unfixme..."

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")
    ldebug "top_apps=${top_apps[*]}"

    # 因为优先安装的APP在最前面，所以这里reverse一下
    array::reverse top_apps
    ldebug "top_apps reverse=${top_apps[*]}"

    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_unfixme _691b5ab9_cache_apps "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

function uninstall_flow::pre_uninstall() {
    return "$SHELL_TRUE"
}

function uninstall_flow::do_uninstall() {
    # 运行卸载
    uninstall_flow::app::do_uninstall || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function uninstall_flow::post_uninstall() {
    local lib_dir
    lib_dir=$(base::bash_lib_dir) || return "$SHELL_FALSE"
    cmd::run_cmd_with_history rm -rf "${lib_dir}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function uninstall_flow::do_unfixme() {
    uninstall_flow::app::do_unfixme || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function uninstall_flow::main_flow() {
    uninstall_flow::do_unfixme || return "$SHELL_FALSE"
    uninstall_flow::pre_uninstall || return "$SHELL_FALSE"
    uninstall_flow::do_uninstall || return "$SHELL_FALSE"
    uninstall_flow::post_uninstall || return "$SHELL_FALSE"
    println_success "all success."
    println_warn "you should reboot you system."

    return "$SHELL_TRUE"
}

function uninstall_flow::unfixme_flow() {
    # 先更新系统
    println_info "upgrade system first..."
    package_manager::upgrade "default" || return "$SHELL_FALSE"
    println_success "upgrade system success."

    uninstall_flow::do_unfixme || return "$SHELL_FALSE"

    println_warn "you should reboot you system."

    return "$SHELL_TRUE"
}
