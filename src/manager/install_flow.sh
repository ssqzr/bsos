#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_23248a22="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# 运行所有程序的安装向导
function install_flow::app::do_guide() {
    linfo "start run all apps guide..."

    local top_apps=()
    local temp_str

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    ldebug "top_apps=${top_apps[*]}"
    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_install_guide "${pm_app}" || return "$SHELL_FALSE"
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
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_install "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function install_flow::app::do_finally() {
    local top_apps=()
    local temp_str
    linfo "start run all apps install finally..."

    temp_str="$(config::cache::top_apps::get)" || return "$SHELL_FALSE"
    array::readarray top_apps < <(echo "${temp_str}")

    ldebug "top_apps=${top_apps[*]}"
    local pm_app
    for pm_app in "${top_apps[@]}"; do
        manager::app::do_finally "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

# 这些模块是在所有模块安装前需要安装的，因为其他模块的安装都需要这些模块
# 这些模块应该是没什么依赖的
# 这些模块不需要用户确认，一定要求安装的，并且没有安装指引
function install_flow::pre_install_global_dependencies() {

    local pm_app
    local pre_install_apps=()
    local temp_str

    linfo "start install global pre dependencies..."
    # 避免每次运行都安装，耗时并且没有必要
    if config::cache::has_pre_installed::get; then
        linfo "install global pre apps has installed. dont need install again."
        return "$SHELL_TRUE"
    fi

    temp_str="$(base::get_pre_install_apps)" || return "$SHELL_FALSE"
    array::readarray pre_install_apps < <(echo "${temp_str}")
    for pm_app in "${pre_install_apps[@]}"; do
        manager::app::do_install "${pm_app}" || return "$SHELL_FALSE"
    done

    config::cache::has_pre_installed::set_true || return "$SHELL_FALSE"

    linfo "install global pre dependencies success."
    return "$SHELL_TRUE"
}

# 安装前置操作
function install_flow::pre_install() {
    # 将当前用户添加到wheel组
    cmd::run_cmd_with_history sudo usermod -aG wheel "$(id -un)" || return "$SHELL_FALSE"

    # 先安装全局都需要的包
    install_flow::pre_install_global_dependencies || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function install_flow::do_install() {

    # 运行安装指引
    install_flow::app::do_guide || return "$SHELL_FALSE"

    # 运行安装
    install_flow::app::do_install || return "$SHELL_FALSE"

    println_info "start run apps finally hook..."
    println_info "---------------------------------------------"

    # 运行 finally 钩子
    install_flow::app::do_finally || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# FIXME: 验证功能没有问题
function install_flow::post_install() {
    local reverse_pre_install_apps=()
    local pre_install_apps=()
    local temp_str

    temp_str="$(base::get_pre_install_apps)" || return "$SHELL_FALSE"
    array::readarray pre_install_apps < <(echo "$temp_str")
    # 反转是因为最先安装的全局应用一般对系统的影响最大，所以处理 finally 的时候将“可能”影响最大的放到最后
    array::reverse_new reverse_pre_install_apps pre_install_apps

    local pm_app
    for pm_app in "${reverse_pre_install_apps[@]}"; do
        manager::app::do_finally "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"

}

function install_flow::main_flow() {
    # 先更新系统
    println_info "upgrade system first..."
    package_manager::upgrade "pacman" || return "$SHELL_FALSE"
    println_success "upgrade system success."

    install_flow::pre_install || return "$SHELL_FALSE"
    install_flow::do_install || return "$SHELL_FALSE"
    install_flow::post_install || return "$SHELL_FALSE"
    println_success "all success."
    println_warn "you should reboot you system."

    return "$SHELL_TRUE"
}
