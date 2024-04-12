#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_8dac019e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/config/config.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/package_manager/manager.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/base.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/app_manager.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/install_flow.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/uninstall_flow.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/cache.sh"

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

function main::input_password() {
    # 执行 su 需要输入密码
    local password
    while true; do
        printf_blue "Please input your root password: "
        read -r -s -e password
        if [ -z "$password" ]; then
            println_warn "password is required to continue."
            continue
        fi
        break
    done
    export ROOT_PASSWORD="${password}"
}

# 导出全局的变量
function main::_export_env() {
    export LC_ALL="C"
    export SRC_ROOT_DIR="${SCRIPT_DIR_8dac019e}"
    export BUILD_ROOT_DIR="/var/tmp/arch_os_install/build"

    main::input_password
}

# 启用无需密码
function main::enable_no_password() {
    # NOTE: 此时不一定有sudo，只能通过su root来执行
    linfo "enable no password..."
    println_info "enable no password..."

    local username
    username=$(id -un)
    local dst_filepath="/etc/sudoers.d/10-${username}"
    linfo "enable user(${username}) no password to run sudo"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'mkdir -p \""$(dirname "${dst_filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) NOPASSWD:ALL\" \> "${dst_filepath}"\' || return "${SHELL_FALSE}"
    linfo "enable user(${username}) no password to run sudo success"

    # 设置当前组内的用户执行pamac不需要输入密码
    local group_name
    group_name="$(id -ng)"
    linfo "enable no password for group(${group_name}) to run pamac"
    local src_filepath="${SCRIPT_DIR_8dac019e}/assets/polkit/10-pamac.rules"
    dst_filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'cp -f \""${src_filepath}"\" \""${dst_filepath}"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'sed -i \"s/usergroup/"${group_name}"/g\" \""${dst_filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "enable no password for group(${group_name}) to run pamac success"

    linfo "enable no password success"
    println_success "enable no password success"

    return "$SHELL_TRUE"
}

# 禁用无需密码
function main::disable_no_password() {
    # NOTE: 此时不一定有sudo，只能通过su root来执行

    linfo "disable no password..."
    println_info "disable no password..."

    local username
    username=$(id -un)
    local filepath="/etc/sudoers.d/10-${username}"
    linfo "disable no password for user(${username}), delete filepath=${filepath}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'rm -f \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "disable no password for user(${username}) success"

    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    linfo "disable no password for pamac, delete filepath=${filepath}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'rm -f \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "disable no password for pamac success"

    linfo "disable no password success"
    println_success "disable no password success"
    return "$SHELL_TRUE"
}

function main::command::install() {
    local app_name="$1"
    local pm_app

    if [ -n "${app_name}" ]; then
        pm_app="custom:${app_name}"
    fi
    # 生成需要处理的应用列表
    manager::cache::generate_top_apps "$pm_app" || return "$SHELL_FALSE"

    install_flow::main_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::uninstall() {
    local app_name="$1"
    local pm_app

    if [ -n "${app_name}" ]; then
        pm_app="custom:${app_name}"
    fi
    # 生成需要处理的应用列表
    manager::cache::generate_top_apps "$pm_app" || return "$SHELL_FALSE"

    uninstall_flow::main_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::main() {
    local command="$1"
    local command_params=("${@:2}")
    if [ -z "${command}" ]; then
        command="install"
    fi
    local log_filepath
    local cmd_history_filepath
    local config_filepath

    # 单例
    main::_lock || return "$SHELL_FALSE"

    # 设置日志的路径
    log_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/main.log"
    log::set_log_file "${log_filepath}"

    # 设置记录执行命令的文件路径
    cmd_history_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/cmd.history"
    rm -f "${cmd_history_filepath}" || return "$SHELL_FALSE"
    cmd::set_cmd_history_filepath "${cmd_history_filepath}" || return "$SHELL_FALSE"

    # 设置配置文件路径
    config_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/config.yml"
    config::set_config_filepath "${config_filepath}" || return "$SHELL_FALSE"

    # 导出全局变量
    main::_export_env || return "$SHELL_FALSE"

    # FIXME: 测试需要注释掉，后面要还原
    # 判断循环依赖
    # manager::app::check_loop_dependencies || return "$SHELL_FALSE"

    manager::cache::do || return "$SHELL_FALSE"

    main::enable_no_password || return "$SHELL_FALSE"

    local code
    case "${command}" in
    "install")
        main::command::install "${command_params[@]}"
        code=$?
        ;;

    "uninstall")
        main::command::uninstall "${command_params[@]}"
        code=$?
        ;;
    *)
        lerror "unknown cmd(${command})"
        code="$SHELL_FALSE"
        ;;
    esac

    main::disable_no_password || return "$SHELL_FALSE"

    return "${code}"
}

main::main "$@"
