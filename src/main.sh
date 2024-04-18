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
    local filepath="/etc/sudoers.d/10-${username}"
    linfo "enable user(${username}) no password to run sudo"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'mkdir -p \""$(dirname "${filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) NOPASSWD:ALL\" \> "${filepath}"\' || return "${SHELL_FALSE}"
    linfo "enable user(${username}) no password to run sudo success"

    # 设置当前组内的用户执行pamac不需要输入密码
    local group_name
    group_name="$(id -ng)"
    linfo "enable no password for group(${group_name}) to run pamac"
    local src_filepath="${SCRIPT_DIR_8dac019e}/assets/polkit/10-pamac.rules"
    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'mkdir -p \""$(dirname "${filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'cp -f \""${src_filepath}"\" \""${filepath}"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'sed -i \"s/usergroup/"${group_name}"/g\" \""${filepath}"\"\' || return "${SHELL_FALSE}"
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
    linfo "disable no password for user(${username})"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) ALL\" \> "${filepath}"\' || return "${SHELL_FALSE}"
    linfo "disable no password for user(${username}) success"

    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    linfo "disable no password for pamac, delete filepath=${filepath}"
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \'rm -f \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "disable no password for pamac success"

    linfo "disable no password success"
    println_success "disable no password success"
    return "$SHELL_TRUE"
}

# 这些模块是在所有模块安装前需要安装的，因为其他模块的安装都需要这些模块
# 这些模块应该是没什么依赖的
# 这些模块不需要用户确认，一定要求安装的，并且没有安装指引
function main::install_core_dependencies() {

    local pm_app
    local core_apps=()
    local temp_str

    linfo "start install core dependencies..."

    temp_str="$(base::core_apps::list)" || return "$SHELL_FALSE"
    array::readarray core_apps < <(echo "${temp_str}")
    for pm_app in "${core_apps[@]}"; do
        if ! manager::app::is_custom "$pm_app"; then
            manager::app::do_install_use_pm "$pm_app" || return "$SHELL_FALSE"
        else
            manager::app::run_custom_manager "${pm_app}" "install" || return "$SHELL_FALSE"
        fi
    done

    linfo "install core dependencies success."
    return "$SHELL_TRUE"
}

function main::must_do() {

    # 先安装全局都需要的包
    main::install_core_dependencies || return "$SHELL_FALSE"

    # 将当前用户添加到wheel组
    cmd::run_cmd_with_history sudo usermod -aG wheel "$(id -un)" || return "$SHELL_FALSE"
}

function main::command::install() {
    local reuse_cache="$1"
    local app_names="$2"
    local temp_str

    local pm_apps=()

    if [ -n "${app_names}" ]; then
        temp_str=$(echo "$app_names" | awk -F ',' -v OFS="\n" '{ for (i = 1; i <= NF; i++) print "custom:"$i }')
        array::readarray pm_apps < <(echo "${temp_str}")
    fi

    manager::app::check_loop_dependencies || return "$SHELL_FALSE"
    manager::cache::do "$reuse_cache" "${pm_apps[@]}" || return "$SHELL_FALSE"

    install_flow::main_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::uninstall() {
    local reuse_cache="$1"
    local app_names="$2"
    local temp_str

    local pm_apps=()

    if [ -n "${app_names}" ]; then
        temp_str=$(echo "$app_names" | awk -F ',' -v OFS="\n" '{ for (i = 1; i <= NF; i++) print "custom:"$i }')
        array::readarray pm_apps < <(echo "${temp_str}")
    fi

    manager::app::check_loop_dependencies || return "$SHELL_FALSE"
    manager::cache::do "$reuse_cache" "${pm_apps[@]}" || return "$SHELL_FALSE"

    uninstall_flow::main_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::check() {
    manager::app::check_loop_dependencies
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "check_loop_dependencies failed"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

function main::ask_reuse_cache() {
    local reuse_cache
    while true; do
        printf_blue "reuse cache if exists ??? (y/n)[Y] "
        # 超时的退出码是1，Ctrl+C的退出码是130
        read -t 5 -r -e -n 1 reuse_cache
        if [ $? -eq 130 ]; then
            lerror "quite input, exit"
            return 130
        fi
        linfo "get input reuse_cache=${reuse_cache}"
        if [ -z "$reuse_cache" ]; then
            reuse_cache="y"
            break
        fi
        if string::is_true_or_false "$reuse_cache"; then
            break
        fi
        println_error "input invalid, please input y or n."
    done
    if string::is_true "$reuse_cache"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
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
    local reuse_cache

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

    main::ask_reuse_cache
    reuse_cache="$?"
    if [ $reuse_cache -eq 130 ]; then
        return "$SHELL_FALSE"
    fi

    main::enable_no_password || return "$SHELL_FALSE"

    main::must_do || return "$SHELL_FALSE"
    # NOTE: 在执行 main::must_do 之后才可以使用 yq 操作配置文件

    local code
    case "${command}" in
    "install")
        main::command::install "$reuse_cache" "${command_params[@]}"
        code=$?
        ;;

    "uninstall")
        main::command::uninstall "$reuse_cache" "${command_params[@]}"
        code=$?
        ;;

    "check")
        main::command::check
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
