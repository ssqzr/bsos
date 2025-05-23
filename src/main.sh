#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_8dac019e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/config/config.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/config/cache.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/lib/package_manager/manager.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/base.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/app.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/flow.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/cache.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/flags.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/utils.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/manager/setup.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8dac019e}/dev.sh"

# 输出帮助信息
function main::help() {
    local help=""

    help="
$(debug::function::filename) [OPTIONS] <SUBCOMMAND> [SUBCOMMAND OPTIONS]

OPTIONS:

    --reuse-cache[=yes/no]                                      启用复用缓存
                                                                    不指定参数或者 --reuse-cache=false 表示不启用
                                                                    --reuse-cache 或者 --reuse-cache=yes 表示启用

    --check-loop[=yes/no]                                       启用检查循环依赖
                                                                    不指定参数或者 --check-loop=false 表示不启用
                                                                    --check-loop 或者 --check-loop=yes 表示启用

    -h, --help                                                  显示帮助信息

SUBCOMMAND:
    install                                                     安装
        --app=[PACKAGE_MANAGER:]APP_NAME,...                    安装的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom
        --exclude-app=[PACKAGE_MANAGER:]APP_NAME,...            排除的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom
        --continue-after-guide[=yes/no]                         安装向导完成后是否直接继续，不直接继续会弹框询问是否继续

    uninstall                                                   卸载
        --app=[PACKAGE_MANAGER:]APP_NAME,...                    安装的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom
        --exclude-app=[PACKAGE_MANAGER:]APP_NAME,...            排除的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom

    upgrade                                                     升级
        --app=[PACKAGE_MANAGER:]APP_NAME,...                    安装的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom
        --exclude-app=[PACKAGE_MANAGER:]APP_NAME,...            排除的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom

    fixme                                                       修复安装时不能解决的问题
                                                                    可能因为当时环境受限的原因，需要在特定环境下才可以执行的步骤。
        --app=[PACKAGE_MANAGER:]APP_NAME,...                    安装的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom
        --exclude-app=[PACKAGE_MANAGER:]APP_NAME,...            排除的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom

    unfixme                                                     撤销修复
        --app=[PACKAGE_MANAGER:]APP_NAME,...                    安装的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom
        --exclude-app=[PACKAGE_MANAGER:]APP_NAME,...            排除的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                    没有指定 PACKAGE_MANAGER 时，默认是：custom

    dev [DEV SUBCOMMAND] [DEV SUBCOMMAND OPTIONS]               开发协助命令
        create                                                  根据模板创建部署应用的实现代码
            --app=APP_NAME,APP_NAME,...                             创建的应用列表，使用 ',' 分割。参数可以指定多次。

        update                                                  更新模板
            --app=APP_NAME,APP_NAME,...                             更新模板的应用列表，使用 ',' 分割。参数可以指定多次。

        check_loop                                              检查 APP 之间是否循环依赖

        install                                                 测试应用的安装流程
            --app=[PACKAGE_MANAGER:]APP_NAME,...                    安装的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                        没有指定 PACKAGE_MANAGER 时，默认是：custom
            --exclude-app=[PACKAGE_MANAGER:]APP_NAME,...            排除的应用列表，使用 ',' 分割。参数可以指定多次。
                                                                        没有指定 PACKAGE_MANAGER 时，默认是：custom

        trait                                                   执行 APP 的 trait 函数
            --app=APP_NAME,APP_NAME,...                             应用列表，使用 ',' 分割。参数可以指定多次。
            --trait=TRAIT_NAME,TRAIT_NAME,...                       执行 trait 函数名列表，使用 ',' 分割。参数可以指定多次。

    "

    echo "${help}"

    return "${SHELL_TRUE}"
}

# 这些模块是在所有模块安装前需要安装的，因为其他模块的安装都需要这些模块
# 这些模块应该是没什么依赖的
# 这些模块不需要用户确认，一定要求安装的，并且没有安装指引
function main::install_core_dependencies() {

    local pm_app
    local core_apps=()
    # shellcheck disable=SC2034
    local exclude_apps=()
    local temp_str

    linfo "start install core dependencies..."

    manager::base::core_apps::all core_apps || return "$SHELL_FALSE"

    for pm_app in "${core_apps[@]}"; do
        linfo "core app(${pm_app}) install..."
        if ! manager::app::is_custom "$pm_app"; then
            manager::app::do_command_use_pm exclude_apps "install" "$pm_app" || return "$SHELL_FALSE"
        else
            linfo "app(${pm_app}) run pre_install..."
            manager::app::run_custom_manager "${pm_app}" "pre_install" || return "$SHELL_FALSE"
            linfo "app(${pm_app}) run install..."
            manager::app::run_custom_manager "${pm_app}" "install" || return "$SHELL_FALSE"
            linfo "app(${pm_app}) run post_install..."
            manager::app::run_custom_manager "${pm_app}" "post_install" || return "$SHELL_FALSE"
        fi
        linfo "core app(${pm_app}) install success."
    done

    linfo "install core dependencies success."
    return "$SHELL_TRUE"
}

function main::must_do() {
    # 清理锁
    package_manager::clean_lock || return "$SHELL_FALSE"

    # 先安装全局都需要的包
    main::install_core_dependencies || return "$SHELL_FALSE"

    # 将当前用户添加到wheel组
    cmd::run_cmd_with_history --sudo -- usermod -aG wheel "$(os::user::name)" || return "$SHELL_FALSE"
}

function main::command::install() {
    local temp_str
    local app_names=()
    local pm_apps=()
    local exclude_app_names=()
    local exclude_pm_apps=()
    local continue_after_guide="${SHELL_FALSE}"
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --exclude-app=*)
            parameter::parse_array --separator="," --option="$param" exclude_app_names || return "$SHELL_FALSE"
            ;;
        --continue-after-guide | --continue-after-guide=*)
            temp=""
            parameter::parse_bool --option="$param" continue_after_guide || return "$SHELL_FALSE"
            if [ "$continue_after_guide" -eq "$SHELL_TRUE" ]; then
                manager::flags::continue_after_guide::add || return "$SHELL_FALSE"
            fi
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

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    array::remove_empty exclude_app_names || return "$SHELL_FALSE"
    array::dedup exclude_app_names || return "$SHELL_FALSE"

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    for temp_str in "${exclude_app_names[@]}"; do
        exclude_pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    manager::cache::do "install" pm_apps exclude_pm_apps || return "$SHELL_FALSE"

    manager::flow::install::main || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::uninstall() {
    local temp_str
    local app_names=()
    local pm_apps=()
    local exclude_app_names=()
    local exclude_pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --exclude-app=*)
            parameter::parse_array --separator="," --option="$param" exclude_app_names || return "$SHELL_FALSE"
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

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    array::remove_empty exclude_app_names || return "$SHELL_FALSE"
    array::dedup exclude_app_names || return "$SHELL_FALSE"

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    for temp_str in "${exclude_app_names[@]}"; do
        exclude_pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    manager::cache::do "uninstall" pm_apps exclude_pm_apps || return "$SHELL_FALSE"

    manager::flow::uninstall::main || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::upgrade() {
    local temp_str
    local app_names=()
    local pm_apps=()
    local exclude_app_names=()
    local exclude_pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --exclude-app=*)
            parameter::parse_array --separator="," --option="$param" exclude_app_names || return "$SHELL_FALSE"
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

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    array::remove_empty exclude_app_names || return "$SHELL_FALSE"
    array::dedup exclude_app_names || return "$SHELL_FALSE"

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    for temp_str in "${exclude_app_names[@]}"; do
        exclude_pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    manager::cache::do "upgrade" pm_apps exclude_pm_apps || return "$SHELL_FALSE"

    manager::flow::upgrade::main || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::fixme() {
    local temp_str
    local app_names=()
    local pm_apps=()
    local exclude_app_names=()
    local exclude_pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --exclude-app=*)
            parameter::parse_array --separator="," --option="$param" exclude_app_names || return "$SHELL_FALSE"
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

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    array::remove_empty exclude_app_names || return "$SHELL_FALSE"
    array::dedup exclude_app_names || return "$SHELL_FALSE"

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    for temp_str in "${exclude_app_names[@]}"; do
        exclude_pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    manager::cache::do "fixme" pm_apps exclude_pm_apps || return "$SHELL_FALSE"

    manager::flow::fixme::main || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::command::unfixme() {
    local temp_str
    local app_names=()
    local pm_apps=()
    local exclude_app_names=()
    local exclude_pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --exclude-app=*)
            parameter::parse_array --separator="," --option="$param" exclude_app_names || return "$SHELL_FALSE"
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

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    array::remove_empty exclude_app_names || return "$SHELL_FALSE"
    array::dedup exclude_app_names || return "$SHELL_FALSE"

    for temp_str in "${app_names[@]}"; do
        pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    for temp_str in "${exclude_app_names[@]}"; do
        exclude_pm_apps+=("$(manager::utils::convert_app_name "$temp_str")") || return "$SHELL_FALSE"
    done

    manager::cache::do "unfixme" pm_apps exclude_pm_apps || return "$SHELL_FALSE"

    manager::flow::unfixme::main || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function main::_do_main() {
    local command="$1"
    local command_params=("${@:2}")

    main::must_do || return "$SHELL_FALSE"
    # NOTE: 在执行 main::must_do 之后才可以使用 yq 操作配置文件

    case "${command}" in
    "install" | "uninstall" | "upgrade" | "fixme" | "unfixme")
        "main::command::${command}" "${command_params[@]}" || return "$SHELL_FALSE"
        ;;
    *)
        lerror "unknown command(${command})"
        return "$SHELL_FALSE"
        ;;
    esac
    return "$SHELL_TRUE"
}

function main::run() {
    local command
    local config_filepath
    local code
    local remain_params=()
    local remain_options=()
    local param
    local temp

    # 先解析全局的参数
    for param in "$@"; do
        case "$param" in
        --reuse-cache | --reuse-cache=*)
            temp=""
            parameter::parse_bool --option="$param" temp || return "$SHELL_FALSE"
            if [ "$temp" -eq "$SHELL_TRUE" ]; then
                manager::flags::reuse_cache::add || return "$SHELL_FALSE"
            fi
            ;;
        --check-loop= | --check-loop=*)
            temp=""
            parameter::parse_bool --option="$param" temp || return "$SHELL_FALSE"
            if [ "$temp" -eq "$SHELL_TRUE" ]; then
                manager::flags::check_loop::add || return "$SHELL_FALSE"
            fi
            ;;
        -h | --help)
            main::help || return "$SHELL_FALSE"
            return "$SHELL_TRUE"
            ;;
        -*)
            remain_options+=("$param")
            ;;
        *)
            remain_params+=("$param")
            ;;
        esac
    done

    if array::is_empty remain_params; then
        # 默认是 install 命令
        remain_params=("install")
    fi

    # 创建临时根目录，程序运行时需要的临时目录和文件都放在这里
    fs::directory::create_recursive "$(global::temp_base_dir)" || return "$SHELL_FALSE"

    # 单例
    manager::setup::lock::lock || return "$SHELL_FALSE"
    # 信号的处理
    manager::setup::signal::register || return "$SHELL_FALSE"

    # 设置配置文件路径
    config_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/config.yml"
    config::set_config_filepath "${config_filepath}" || return "$SHELL_FALSE"

    # 导出全局变量
    manager::setup::export_env || return "$SHELL_FALSE"
    fs::directory::create_recursive "$BUILD_ROOT_DIR" || return "$SHELL_FALSE"

    manager::setup::enable_no_password "${ROOT_PASSWORD}" || return "$SHELL_FALSE"

    # 调用子命令
    array::lpop remain_params command || return "$SHELL_FALSE"
    case "${command}" in
    "dev")
        develop::command "${remain_params[@]}" "${remain_options[@]}"
        code=$?
        ;;

    *)
        main::_do_main "${command}" "${remain_params[@]}" "${remain_options[@]}"
        code=$?
        ;;
    esac

    return "${code}"
}

function main::wrap_run() {
    local log_filepath
    local cmd_history_filepath

    # 第一步就是检查用户，不然可能会污染环境
    manager::setup::check_root_user || return "$SHELL_FALSE"

    # 其次设置日志的路径，尽量记录日志
    log_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/main.log"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "${log_filepath}" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_DEBUG" || return "$SHELL_FALSE"
    # 最长的是 success 字符串，长度为 7
    export LOG_HANDLER_STREAM_FORMATTER="{{datetime}} [{{level|to_upper|justify 7 center}}] {{message}}"

    # 设置记录执行命令的文件路径
    # 可以删除，只是为了方便排错
    cmd_history_filepath="$(dirname "${SCRIPT_DIR_8dac019e}")/cmd.history"
    rm -f "${cmd_history_filepath}" || return "$SHELL_FALSE"
    cmd::set_cmd_history_filepath "${cmd_history_filepath}" || return "$SHELL_FALSE"

    main::run "$@"
    if [ $? -eq "$SHELL_FALSE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "something is wrong, please check log file: ${log_filepath}"
        return "$SHELL_FALSE"
    fi
}

main::wrap_run "$@"
