#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b2e4a0ea="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# 使用包管理器直接卸载
function uninstall_flow::app::_uninstall_self_use_pm() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    package=$(manager::app::parse_app_name "$pm_app")

    linfo "start direct uninstall app(${package}) with ${package_manager}"
    println_info "$pm_app: start uninstall app(${package}) with ${package_manager}"

    manager::uninstall "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "uninstall app(${package}) with ${package_manager} failed"
        println_error "$pm_app: uninstall app(${package}) with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    linfo "$pm_app uninstall app(${package}) with ${package_manager} success"
    println_success "$pm_app: uninstall app(${package}) with ${package_manager} success"

    return "$SHELL_TRUE"
}

# 不处理依赖的卸载，依赖的可能也被其他人依赖
function uninstall_flow::app::_uninstall_self_custom_without_dependencies() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local package_manager
    local app_name

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    app_name=$(manager::app::parse_app_name "$pm_app")

    linfo "start uninstall app(${pm_app})..."
    println_info "${pm_app}: start uninstall app(${pm_app})..."

    if [ "$package_manager" != "custom" ]; then
        package_manager::uninstall "$package_manager" "$app_name" || return "$SHELL_FALSE"
    else
        if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
            lerror "app(${pm_app}) directory is not exist."
            return "$SHELL_FALSE"
        fi

        manager::app::run_custom_manager "$pm_app" "uninstall"
        if [ $? -ne "${SHELL_TRUE}" ]; then
            lerror "uninstall app(${pm_app}) failed"
            return "$SHELL_FALSE"
        fi
    fi

    linfo "uninstall app(${pm_app}) success."
    return "${SHELL_TRUE}"
}

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

    uninstall_flow::pre_uninstall || return "$SHELL_FALSE"
    uninstall_flow::do_uninstall || return "$SHELL_FALSE"
    uninstall_flow::post_uninstall || return "$SHELL_FALSE"
    println_success "all success."
    println_warn "you should reboot you system."

    return "$SHELL_TRUE"
}
