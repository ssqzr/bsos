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
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/flags.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/dev.sh"

function main::ask() {
    local code
    if ! manager::flags::check_loop::is_exists; then
        tui::builtin::confirm "check apps loop dependencies ?" "y"
        code=$?
        if [ $code -eq 130 ]; then
            return "$SHELL_FALSE"
        elif [ $code -eq "$SHELL_TRUE" ]; then
            manager::flags::check_loop::add || return "$SHELL_FALSE"
        fi
    fi

    if ! manager::flags::reuse_cache::is_exists; then
        tui::builtin::confirm "reuse cache if exists ?" "y"
        code=$?
        if [ $code -eq 130 ]; then
            return "$SHELL_FALSE"
        elif [ $code -eq "$SHELL_TRUE" ]; then
            manager::flags::reuse_cache::add || return "$SHELL_FALSE"
        fi
    fi
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
        linfo "core app(${pm_app}) install..."
        if ! manager::app::is_custom "$pm_app"; then
            manager::app::do_install_use_pm "$pm_app" || return "$SHELL_FALSE"
        else
            linfo "app(${pm_app}) run pre_install..."
            manager::app::run_custom_manager "${pm_app}" "pre_install" || return "$SHELL_FALSE"
            linfo "app(${pm_app}) run do_install..."
            manager::app::run_custom_manager "${pm_app}" "do_install" || return "$SHELL_FALSE"
            linfo "app(${pm_app}) run post_install..."
            manager::app::run_custom_manager "${pm_app}" "post_install" || return "$SHELL_FALSE"
        fi
        linfo "core app(${pm_app}) install success."
    done

    linfo "install core dependencies success."
    return "$SHELL_TRUE"
}

function main::must_do() {

    # 先安装全局都需要的包
    main::install_core_dependencies || return "$SHELL_FALSE"

    # 将当前用户添加到wheel组
    cmd::run_cmd_with_history -- sudo usermod -aG wheel "$(id -un)" || return "$SHELL_FALSE"
}

function main::check() {

    if ! manager::flags::check_loop::is_exists; then
        linfo "no need check loop dependencies"
    else
        manager::app::check_loop_relationships
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "check_loop_dependencies failed"
            return "$SHELL_FALSE"
        fi
    fi

    # 其他检查

    return "$SHELL_TRUE"
}

function main::command::install() {
    local app_names
    local temp_str
    local pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ -v app_names ]; then
        array::remove_empty app_names || return "$SHELL_FALSE"
        array::dedup app_names || return "$SHELL_FALSE"
    fi

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("custom:$temp_str")
    done

    manager::cache::do "${pm_apps[@]}" || return "$SHELL_FALSE"

    install_flow::main_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::uninstall() {
    local app_names
    local temp_str
    local pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ -v app_names ]; then
        array::remove_empty app_names || return "$SHELL_FALSE"
        array::dedup app_names || return "$SHELL_FALSE"
    fi

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("custom:$temp_str")
    done

    manager::cache::do "${pm_apps[@]}" || return "$SHELL_FALSE"

    uninstall_flow::main_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::fixme() {
    local app_names
    local temp_str
    local pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ -v app_names ]; then
        array::remove_empty app_names || return "$SHELL_FALSE"
        array::dedup app_names || return "$SHELL_FALSE"
    fi

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("custom:$temp_str")
    done

    manager::cache::do "${pm_apps[@]}" || return "$SHELL_FALSE"

    install_flow::fixme_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::unfixme() {
    local app_names
    local temp_str
    local pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ -v app_names ]; then
        array::remove_empty app_names || return "$SHELL_FALSE"
        array::dedup app_names || return "$SHELL_FALSE"
    fi

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("custom:$temp_str")
    done

    manager::cache::do "${pm_apps[@]}" || return "$SHELL_FALSE"

    uninstall_flow::unfixme_flow || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::_do_main() {
    local command="$1"
    local command_params=("${@:2}")

    main::ask || return "$SHELL_FALSE"

    main::must_do || return "$SHELL_FALSE"
    # NOTE: 在执行 main::must_do 之后才可以使用 yq 操作配置文件

    main::check || return "$SHELL_FALSE"

    case "${command}" in
    "install" | "uninstall" | "fixme" | "unfixme")
        "main::command::${command}" "${command_params[@]}" || return "$SHELL_FALSE"
        ;;
    *)
        lerror "unknown command(${command})"
        return "$SHELL_FALSE"
        ;;
    esac
    return "$SHELL_TRUE"
}

function main::signal::handler_exit() {
    local code="$1"
    linfo "exit code: ${code}"
    base::disable_no_password || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function main::run() {
    local command
    local log_filepath
    local cmd_history_filepath
    local config_filepath
    local code
    local remain_params=()
    local flags=()
    local param
    local temp_str

    # 先解析全局的参数
    for param in "$@"; do
        case "$param" in
        --flag=*)
            parameter::parse_array --separator="," --option="$param" flags || return "$SHELL_FALSE"
            ;;
        *)
            remain_params+=("$param")
            ;;
        esac
    done

    for temp_str in "${flags[@]}"; do
        manager::flags::append "${temp_str}" || return "$SHELL_FALSE"
    done

    if array::is_empty remain_params; then
        # 默认是 install 命令
        remain_params=("install")
    fi

    # 第一步就是检查用户，不然可能会污染环境
    base::check_root_user || return "$SHELL_FALSE"

    # 其次设置日志的路径，尽量记录日志
    log_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/main.log"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "${log_filepath}" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_DEBUG" || return "$SHELL_FALSE"

    # 单例
    base::lock || return "$SHELL_FALSE"

    # 设置记录执行命令的文件路径
    cmd_history_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/cmd.history"
    rm -f "${cmd_history_filepath}" || return "$SHELL_FALSE"
    cmd::set_cmd_history_filepath "${cmd_history_filepath}" || return "$SHELL_FALSE"

    # 设置配置文件路径
    config_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/config.yml"
    config::set_config_filepath "${config_filepath}" || return "$SHELL_FALSE"

    # 导出全局变量
    base::export_env || return "$SHELL_FALSE"

    base::enable_no_password || return "$SHELL_FALSE"
    trap 'main::signal::handler_exit "$?"' EXIT

    array::lpop remain_params command || return "$SHELL_FALSE"
    case "${command}" in
    "dev")
        develop::command "${remain_params[@]}"
        code=$?
        ;;

    *)
        main::_do_main "${command}" "${remain_params[@]}"
        code=$?
        ;;
    esac

    return "${code}"
}

function main::wrap_run() {
    main::run "$@"
    if [ $? -eq "$SHELL_TRUE" ]; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "all success."
        return "$SHELL_TRUE"
    else
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "something is wrong, please check log."
        return "$SHELL_FALSE"
    fi
}

main::wrap_run "$@"
