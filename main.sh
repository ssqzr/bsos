#!/bin/bash

set -o pipefail

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_8dac019e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/config/config.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/package_manager/manager.sh"

# NOTE: 在处理所有安装流程前需要安装的app，是单独的安装流程。一般是本脚本功能需要的app
# sudo 是为了用户安全
# gum 是安装脚本为了更好的终端交互需要安装的，它可以直接使用pacman安装
# go_yq 是配置管理需要的，安装脚本也需要读写配置
# base 是为了基本的编译需要的
# git 是为了安装pamac需要的，后面 git 还会以custom的方式再安装一遍，因为有一些配置需要配置
# pamac 为了安装其他应用
__pre_install_apps=("custom:sudo" "pacman:lsof" "pacman:gum" "pacman:go-yq" "pacman:base-devel")
__pre_install_apps+=("pacman:git" "custom:yay" "custom:pamac")

# 简单的单例，防止重复运行
function main::_lock() {
    local lock_file="/tmp/arch_os_install.lock"
    exec 99>"$lock_file"
    flock -n 99
    if [ $? -ne "$SHELL_TRUE" ]; then
        println_info "already running, exit."
        return "${SHELL_FALSE}"
    fi
    echo "$$" >&99
    # shellcheck disable=SC2064
    trap "rm -f ${lock_file}" INT TERM EXIT

    return "$SHELL_TRUE"
}

# 导出全局的变量
function main::_export_env() {
    export LC_ALL="C"
    export SRC_ROOT_DIR="${SCRIPT_DIR_8dac019e}"
    export BUILD_ROOT_DIR="/var/tmp/arch_os_install/build"
}

function main::app::parse_package_manager() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local package_manager=${pm_app%:*}
    echo "$package_manager"
}

function main::app::parse_app_name() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local app_name=${pm_app#*:}
    echo "$app_name"
}

function main::app::is_custom() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local package_manager
    package_manager=$(main::app::parse_package_manager "$pm_app")
    if [ "$package_manager" == "custom" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function main::app::directory() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if ! main::app::is_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(main::app::parse_app_name "$pm_app")
    echo "${SRC_ROOT_DIR}/app/${app_name}"
}

function main::app::run_script() {
    local pm_app="$1"
    local sub_command="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$sub_command" ]; then
        lerror "sub_command is empty"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(main::app::parse_app_name "$pm_app")

    if ! main::app::is_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom, sub_command=${sub_command}"
        return "$SHELL_FALSE"
    fi

    local install_path="${SRC_ROOT_DIR}/app/${app_name}/install.sh"

    if [ ! -e "${install_path}" ]; then
        lerror "app(${pm_app}) install.sh not found, install_path=${install_path}"
        return "${SHELL_FALSE}"
    fi

    "$install_path" "${sub_command}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 使用包管理器直接安装
function main::app::_install_self_use_pm() {
    local pm_app="$1"
    local print_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(main::app::parse_package_manager "$pm_app")
    package=$(main::app::parse_app_name "$pm_app")

    linfo "${pm_app}: direct installing app with ${package_manager}"
    println_info "${print_indent}${pm_app}: direct installing app with ${package_manager}"

    package_manager::install "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "${pm_app}: direct install app with ${package_manager} failed"
        println_error "${print_indent}${pm_app}: direct install app with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    linfo "${pm_app}: direct install app with ${package_manager} success"
    println_info "${print_indent}${pm_app}: direct install app with ${package_manager} success"

    return "$SHELL_TRUE"
}

# 使用包管理器直接卸载
function main::app::_uninstall_self_use_pm() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(main::app::parse_package_manager "$pm_app")
    package=$(main::app::parse_app_name "$pm_app")

    linfo "start direct uninstall app(${package}) with ${package_manager}"
    manager::uninstall "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "uninstall app(${package}) with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

function main::app::_do_install_custom() {
    local pm_app="$1"
    local print_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(main::app::directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 安装所有 dependencies
    linfo "start install app(${pm_app}) dependencies..."
    println_info "${print_indent}${pm_app}: install dependencies..."

    local dependencies
    array::readarray dependencies < <(main::app::run_script "${pm_app}" "dependencies")

    for item in "${dependencies[@]}"; do
        main::app::do_install "${item}" "  ${print_indent}" || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) all dependencies install success..."
    println_info "${print_indent}${pm_app}: all dependencies install success..."

    # 安装自己
    linfo "start install app(${pm_app}) ..."
    println_info "${print_indent}${pm_app}: installing self... "
    main::app::run_script "${pm_app}" "install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror "install app(${pm_app}) failed"
        println_error "${print_indent}${pm_app}: install failed."
        return "$SHELL_FALSE"
    fi

    # 安装所有 features
    linfo "start install app(${pm_app}) features..."
    println_info "${print_indent}${pm_app}: install features..."
    local features
    array::readarray features < <(main::app::run_script "${pm_app}" "features")

    for item in "${features[@]}"; do
        main::app::do_install "${item}" "  ${print_indent}" || return "$SHELL_FALSE"
    done
    linfo "app(${pm_app}) all features install success..."
    println_info "${print_indent}${pm_app}: all features install success..."
    return "$SHELL_TRUE"
}

# 运行安装向导
function main::app::do_install_guide() {
    local pm_app="$1"
    local level_indent="$2"
    local item

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if ! main::app::is_custom "${pm_app}"; then
        linfo "app(${pm_app}) is not custom, skip install guide"
        println_info "${level_indent}${pm_app}: is not custom, skip install guide"
        return "$SHELL_TRUE"
    fi

    linfo "app(${pm_app}) install guide..."
    println_info "${level_indent}${pm_app}: install guide..."

    # 获取它的依赖
    linfo "app(${pm_app}) dependencies install guide..."
    println_info "${level_indent}${pm_app}: dependencies install guide..."
    local dependencies
    array::readarray dependencies < <(main::app::run_script "${pm_app}" "dependencies")

    for item in "${dependencies[@]}"; do
        main::app::do_install_guide "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    # 获取它的feature
    linfo "app(${pm_app}) features install guide..."
    println_info "${level_indent}${pm_app}: features install guide..."
    local features
    array::readarray features < <(main::app::run_script "${pm_app}" "features")
    for item in "${features[@]}"; do
        main::app::do_install_guide "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) self install guide..."
    println_info "${level_indent}${pm_app}: self install guide..."
    if config::app::is_configed::get "$pm_app"; then
        # 说明已经配置过了
        linfo "app(${pm_app}) has configed, not need to config again"
        println_info "${level_indent}${pm_app}: self has configed, not need to config again"
        return "$SHELL_TRUE"
    fi
    main::app::run_script "${pm_app}" "install_guide" || return "$SHELL_FALSE"
    config::app::is_configed::set_true "$pm_app" || return "$SHELL_FALSE"

    linfo "app(${pm_app}) install guide done"
    println_info "${level_indent}${pm_app}: install guide done"

    return "${SHELL_TRUE}"
}

# 运行安装向导
function main::app::do_finally() {
    local pm_app="$1"
    local level_indent="$2"
    local item

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if ! main::app::is_custom "${pm_app}"; then
        linfo "app(${pm_app}) is not custom, skip run finally"
        println_info "${level_indent}${pm_app}: is not custom, skip run finally"
        return "$SHELL_TRUE"
    fi

    linfo "app(${pm_app}) run finally..."
    println_info "${level_indent}${pm_app}: run finally..."

    # 获取它的依赖
    linfo "app(${pm_app}) dependencies run finally..."
    println_info "${level_indent}${pm_app}: dependencies run finally..."
    local dependencies
    array::readarray dependencies < <(main::app::run_script "${pm_app}" "dependencies")

    for item in "${dependencies[@]}"; do
        main::app::do_finally "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    # 获取它的feature
    linfo "app(${pm_app}) features run finally..."
    println_info "${level_indent}${pm_app}: features run finally..."
    local features
    array::readarray features < <(main::app::run_script "${pm_app}" "features")
    for item in "${features[@]}"; do
        main::app::do_finally "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) self run finally..."
    println_info "${level_indent}${pm_app}: self run finally..."
    main::app::run_script "${pm_app}" "finally" || return "$SHELL_FALSE"

    linfo "app(${pm_app}) run finally done"
    println_info "${level_indent}${pm_app}: run finally done"

    return "${SHELL_TRUE}"
}

# 安装一个APP，附带其他的操作
function main::app::do_install() {
    local pm_app="$1"
    local print_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    println_info "${print_indent}${pm_app}: install..."
    linfo "start install app(${pm_app})..."

    if ! main::app::is_custom "$pm_app"; then
        main::app::_install_self_use_pm "$pm_app" "$print_indent" || return "$SHELL_FALSE"
    else
        main::app::_do_install_custom "$pm_app" "$print_indent" || return "$SHELL_FALSE"
    fi

    if ! config::global::pre_install_apps::is_contain "${pm_app}"; then
        # pre_install_apps 里的APP
        # 只需要安装不需要记载下来，卸载的时候不会卸载
        # 因为卸载后会导致程序运行异常
        # 例如卸载 go-yq 后脚本就读写不了配置文件了
        config::global::installed_apps::rpush "${pm_app}" || return "$SHELL_FALSE"
    fi

    linfo "install app(${pm_app}) success."
    println_info "${print_indent}${pm_app}: install success."
    return "${SHELL_TRUE}"
}

# 不处理依赖的卸载，依赖的可能也被其他人依赖
function main::app::uninstall_self() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local package_manager
    local app_name

    package_manager=$(main::app::parse_package_manager "$pm_app")
    app_name=$(main::app::parse_app_name "$pm_app")

    linfo "start uninstall app(${pm_app})..."

    if [ "$package_manager" != "custom" ]; then
        package_manager::uninstall "$package_manager" "$app_name" || return "$SHELL_FALSE"
    else
        if [ ! -e "$(main::app::directory "${pm_app}")" ]; then
            lerror "app(${pm_app}) directory is not exist."
            return "$SHELL_FALSE"
        fi

        main::app::run_script "$pm_app" "uninstall"
        if [ $? -ne "${SHELL_TRUE}" ]; then
            lerror "uninstall app(${pm_app}) failed"
            return "$SHELL_FALSE"
        fi
    fi

    linfo "uninstall app(${pm_app}) success."
    return "${SHELL_TRUE}"
}

function main::app::is_no_loop_dependencies() {
    local pm_app="$1"
    local link_path="$2"

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty, params=$*"
        return "$SHELL_FALSE"
    fi

    if ! main::app::is_custom "$pm_app"; then
        # 如果不是自定义的包，那么不需要检查循环依赖
        return "$SHELL_TRUE"
    fi

    echo "$link_path" | grep -wq "$pm_app"
    if [ $? -eq "${SHELL_TRUE}" ]; then
        println_error "app($pm_app) has loop dependencies. dependencies link path: ${link_path} $pm_app"
        lerror "app($pm_app) has loop dependencies. dependencies link path: ${link_path} $pm_app"
        return "$SHELL_FALSE"
    fi

    link_path="$link_path $pm_app"

    local dependencies=()

    local temp
    array::readarray temp < <(main::app::run_script "${pm_app}" "dependencies")
    dependencies+=("${temp[@]}")

    temp=()
    array::readarray temp < <(main::app::run_script "${pm_app}" "features")
    dependencies+=("${temp[@]}")

    local item
    for item in "${dependencies[@]}"; do
        main::app::is_no_loop_dependencies "${item}" "${link_path}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

# 检查循环依赖
function main::global::check_loop_dependencies() {

    linfo "start check all app loop dependencies..."

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        main::app::is_no_loop_dependencies "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

# 这些模块是在所有模块安装前需要安装的，因为其他模块的安装都需要这些模块
# 这些模块应该是没什么依赖的
# 这些模块不需要用户确认，一定要求安装的，并且没有安装指引
function main::global::pre_install_dependencies() {

    linfo "start install global pre dependencies..."
    # 避免每次运行都安装，耗时并且没有必要
    if config::global::has_pre_installed::get; then
        linfo "global pre install apps has installed. dont need install again."
        return "$SHELL_TRUE"
    fi

    local pm_app
    for pm_app in "${__pre_install_apps[@]}"; do
        main::app::do_install "${pm_app}" || return "$SHELL_FALSE"
    done

    config::global::has_pre_installed::set_true || return "$SHELL_FALSE"

    linfo "install global pre dependencies success."
    return "$SHELL_TRUE"
}

# 安装前置操作
function main::global::pre_install() {
    # 将当前用户添加到wheel组
    cmd::run_cmd_with_history sudo usermod -aG wheel "$(id -un)" || return "$SHELL_FALSE"

    # 先安装全局都需要的包
    main::global::pre_install_dependencies || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 运行所有程序的安装向导
function main::global::apps_guide() {
    linfo "start run all apps guide..."

    local top_install_apps=()
    # FIXME: config::global::top_install_apps::get 失败是不会导致readarray命令失败的
    # array::readarray top_install_apps < <(config::global::top_install_apps::get || return "$SHELL_FALSE")
    # array::readarray top_install_apps < <(config::global::top_install_apps::get) || return "$SHELL_FALSE"
    # 上面两种方式都解决不了
    # NOTE: 由于 config::global::top_install_apps::get 输出的是多行，目的是防止单个元素包含空格的问题
    # 所以下面的方式不行，下面的方式适用空格分割的元素
    # top_install_apps=("$(config::global::top_install_apps::get)")
    array::readarray top_install_apps < <(config::global::top_install_apps::get)

    ldebug "top_install_apps=${top_install_apps[*]}"
    local pm_app
    for pm_app in "${top_install_apps[@]}"; do
        main::app::do_install_guide "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function main::global::apps_install() {
    local top_install_apps=()
    linfo "start run all apps install..."

    array::readarray top_install_apps < <(config::global::top_install_apps::get)

    ldebug "top_install_apps=${top_install_apps[*]}"
    local pm_app
    for pm_app in "${top_install_apps[@]}"; do
        main::app::do_install "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function main::global::apps_finally() {
    local top_install_apps=()
    linfo "start run all apps install finally..."

    array::readarray top_install_apps < <(config::global::top_install_apps::get)

    ldebug "top_install_apps=${top_install_apps[*]}"
    local pm_app
    for pm_app in "${top_install_apps[@]}"; do
        main::app::do_finally "${pm_app}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function main::global::_recursion_generate_pre_install_list() {
    local pm_app="$1"
    if ! main::app::is_custom "${pm_app}"; then
        config::global::pre_install_apps::rpush_unique "${pm_app}"
        return "$SHELL_TRUE"
    fi

    # 获取它的依赖
    local dependencies
    array::readarray dependencies < <(main::app::run_script "${pm_app}" "dependencies")

    local item
    for item in "${dependencies[@]}"; do
        main::global::_recursion_generate_pre_install_list "${item}" || return "$SHELL_FALSE"
    done

    # 获取它的feature
    local features
    array::readarray features < <(main::app::run_script "${pm_app}" "features")
    for item in "${features[@]}"; do
        main::global::_recursion_generate_pre_install_list "${item}" || return "$SHELL_FALSE"
    done

    # 处理自己
    config::global::pre_install_apps::rpush_unique "${pm_app}"
    return "$SHELL_TRUE"
}

# 这个列表目前只是用作过滤使用
function main::global::generate_pre_install_list() {

    config::global::pre_install_apps::clear || return "$SHELL_FALSE"

    println_info "generate global pre install app list, it take a long time..."
    linfo "generate global pre install app list, it take a long time..."

    local pm_app
    for pm_app in "${__pre_install_apps[@]}"; do
        main::global::_recursion_generate_pre_install_list "${pm_app}" || return "$SHELL_FALSE"
    done

    linfo "generate global pre install app list success."
    println_info "generate global pre install app list success."
    return "$SHELL_TRUE"
}

# 生成安装列表
function main::global::generate_top_install_list() {
    # 先清空安装列表
    config::global::top_install_apps::clear || return "$SHELL_FALSE"

    println_info "generate top install app list, it take a long time..."
    linfo "generate top install app list, it take a long time..."

    # 被其他app依赖的app
    local as_dependencies=()
    # 没有被依赖的
    local none_dependencies=()

    local app_path
    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        if config::global::pre_install_apps::is_contain "$pm_app"; then
            continue
        fi

        if ! array::is_contain as_dependencies "$pm_app"; then
            array::rpush_when_not_exist none_dependencies "$pm_app"
        fi

        # 获取它的依赖
        local dependencies
        array::readarray dependencies < <(main::app::run_script "${pm_app}" "dependencies")

        local item
        for item in "${dependencies[@]}"; do
            array::remove none_dependencies "$item"
            array::rpush_when_not_exist as_dependencies "$item"
        done

        # 获取它的feature
        local features
        array::readarray features < <(main::app::run_script "${pm_app}" "features")
        for item in "${features[@]}"; do
            array::remove none_dependencies "$item"
            array::rpush_when_not_exist as_dependencies "$item"
        done
    done
    ldebug "none_dependencies: ${none_dependencies[*]}"
    ldebug "as_dependencies: ${as_dependencies[*]}"

    # 生成安装列表
    local pm_app
    for item in "${none_dependencies[@]}"; do
        config::global::top_install_apps::rpush "$item" || return "$SHELL_FALSE"
    done

    linfo "generate top install app list success"
    println_info "generate top install app list success"

    return "$SHELL_TRUE"
}

# FIXME: 验证功能没有问题
function main::global::post_install() {
    local reverse_pre_install_apps=()
    array::reverse reverse_pre_install_apps __pre_install_apps

    local pm_app
    for pm_app in "${reverse_pre_install_apps[@]}"; do
        main::app::do_finally "${pm_app}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"

}

function main::global::install_single_app() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    linfo "install single app: ${pm_app}"

    main::app::do_install_guide "${pm_app}" || return "$SHELL_FALSE"
    linfo "install single app(${pm_app}) do_install_guide success."

    main::app::do_install "${pm_app}" || return "$SHELL_FALSE"
    linfo "install single app(${pm_app}) do_install success."

    main::app::do_finally "${pm_app}" || return "$SHELL_FALSE"
    linfo "install single app(${pm_app}) do_finally success."

    linfo "install single app(${pm_app}) success."
    return "$SHELL_TRUE"
}

function main::global::install_all_app() {

    # 运行安装指引
    main::global::apps_guide || return "$SHELL_FALSE"

    config::global::installed_apps::clear || return "$SHELL_FALSE"

    # 运行安装
    main::global::apps_install || return "$SHELL_FALSE"

    println_info "start run apps finally hook..."
    println_info "---------------------------------------------"

    # 运行 finally 钩子
    main::global::apps_finally || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::global::command::install() {
    local app_name="$1"
    local pm_app

    if [ -n "${app_name}" ]; then
        pm_app="custom:${app_name}"
    fi

    # 先更新系统
    println_info "upgrade system first..."
    package_manager::upgrade "pacman" || return "$SHELL_FALSE"
    println_info "upgrade system success."

    main::global::pre_install || return "$SHELL_FALSE"

    if [ -n "${pm_app}" ]; then
        main::global::install_single_app "${pm_app}" || return "$SHELL_FALSE"
        # 运行单个安装往往是为了测试，所以就不执行全局的 post_install 了。

        println_success "install app($pm_app) success."
        println_warn "you should check install result."
    else
        main::global::install_all_app || return "$SHELL_FALSE"
        main::global::post_install || return "$SHELL_FALSE"

        println_success "all success."
        println_warn "you should reboot you system."
    fi

    return "$SHELL_TRUE"
}

function main::global::command::uninstall() {

    local pm_app

    while true; do
        pm_app="$(config::global::installed_apps::last)"
        if [ -z "${pm_app}" ]; then
            break
        fi
        main::app::uninstall_self "${pm_app}"
        if [ $? -ne "${SHELL_TRUE}" ]; then
            config::global::installed_apps::rpush "${pm_app}"
            return "$SHELL_FALSE"
        fi
        config::global::installed_apps::rpop "${pm_app}" >/dev/null 2>&1 || return "$SHELL_FALSE"
    done
}

function main::main() {
    local command="$1"
    local command_params=("${@:2}")
    if [ -z "${command}" ]; then
        command="install"
    fi

    # 设置日志的路径
    log::set_log_file "${SCRIPT_DIR_8dac019e}/main.log"

    # 设置记录执行命令的文件路径
    local cmd_history_filepath="${SCRIPT_DIR_8dac019e}/cmd.history"
    rm -f "${cmd_history_filepath}" || return "$SHELL_FALSE"
    cmd::set_cmd_history_filepath "${cmd_history_filepath}" || return "$SHELL_FALSE"

    # 设置配置文件路径
    config::set_config_filepath "${SCRIPT_DIR_8dac019e}/config.yml" || return "$SHELL_FALSE"

    # 单例
    main::_lock || return "$SHELL_FALSE"

    # 导出全局变量
    main::_export_env || return "$SHELL_FALSE"

    # FIXME: 测试需要注释掉，后面要还原
    # 判断循环依赖
    # main::global::check_loop_dependencies || return "$SHELL_FALSE"

    # 这个列表目前只用作过滤判断用
    main::global::generate_pre_install_list || return "$SHELL_FALSE"

    # 生成安装列表
    main::global::generate_top_install_list || return "$SHELL_FALSE"

    case "${command}" in
    "install")
        main::global::command::install "${command_params[@]}" || return "$SHELL_FALSE"
        ;;

    "uninstall")
        # TODO: 这个命令还没有实现和测试
        main::global::command::uninstall || return "$SHELL_FALSE"
        ;;
    *)
        lerror "unknown cmd(${command})"
        return "$SHELL_FALSE"
        ;;
    esac

    return "${SHELL_TRUE}"
}

main::main "$@"
