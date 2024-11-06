#!/bin/bash

# APP 的管理模块，调用各个APP的trait来对APP进行安装和卸载

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_f5d93f4f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 因为 source 需要用到路径，所以这个只能在最开始判断
if [ -z "${SRC_ROOT_DIR}" ]; then
    printf "\033[1;31m%s\033[0m" "env SRC_ROOT_DIR is not set\n"
    # 还没有 source，所以$SHELL_FALSE还不可用
    exit 1
fi

# shellcheck source=/dev/null
source "${SRC_ROOT_DIR}/lib/utils/all.sh" || exit 1
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# NOTE: 一些全局的变量必须已经初始化，后面会用到
# NOTE: 可以用到的环境变量如下：
# - HOME 用户主目录
# - XDG_CONFIG_HOME 用户配置文件的根目录
# - XDG_CACHE_HOME 存储用户特定的非重要性数据文件的基准目录
# - XDG_DATA_HOME 存储用户特定的数据文件的基准目录
# - ROOT_PASSWORD root用户的密码
# - SRC_ROOT_DIR 代码的根目录
# - PM_APP_NAME 模板
# - BUILD_TEMP_DIR 安装流程的临时构建根目录
function custom_manager::_env() {
    local app_name="$1"

    if [ -z "${app_name}" ]; then
        lerror "param app_name is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$HOME" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "env HOME is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$XDG_CONFIG_HOME" ]; then
        export XDG_CONFIG_HOME="$HOME/.config"
    fi

    if [ -z "$XDG_CACHE_HOME" ]; then
        export XDG_CACHE_HOME="$HOME/.cache"
    fi

    if [ -z "$XDG_DATA_HOME" ]; then
        export XDG_DATA_HOME="$HOME/.local/share"
    fi

    if [ -z "$ROOT_PASSWORD" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "env ROOT_PASSWORD is not set"
        return "$SHELL_FALSE"
    fi

    # export PM_APP_NAME
    export PM_APP_NAME="custom:${app_name}"

    # export BUILD_TEMP_DIR
    if [ -z "${BUILD_ROOT_DIR}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "env BUILD_ROOT_DIR is not set"
        return "$SHELL_FALSE"
    fi
    # 路径中包含特殊字符可能导致一些问题，例如：
    # 安装yay时，报错：go: GOPATH entry is relative; must be absolute path: "yay/yay/src/gopath".
    # 但是真实的路径是 "custom:yay/yay/src/gopath"，解析有问题
    # 所以使用没有特殊字符的路径
    export BUILD_TEMP_DIR="${BUILD_ROOT_DIR}/${PM_APP_NAME//:/_}"
    unset BUILD_ROOT_DIR

    return "$SHELL_TRUE"
}

function custom_manager::_clean_build() {
    linfo "clean app(${PM_APP_NAME}) build env..."
    fs::directory::safe_delete "${BUILD_TEMP_DIR}" || return "$SHELL_FALSE"
    fs::directory::create_recursive "${BUILD_TEMP_DIR}" || return "$SHELL_FALSE"
    linfo "clean app(${PM_APP_NAME}) build env success."
    return "${SHELL_TRUE}"
}

function custom_manager::prepare() {
    if [ ! -e "${XDG_CONFIG_HOME}" ]; then
        cmd::run_cmd_with_history -- mkdir -p "${XDG_CONFIG_HOME}" || return "${SHELL_FALSE}"
    fi

    if [ ! -e "${XDG_CACHE_HOME}" ]; then
        cmd::run_cmd_with_history -- mkdir -p "${XDG_CACHE_HOME}" || return "${SHELL_FALSE}"
    fi

    return "$SHELL_TRUE"
}

function custom_manager::command::install_guide() {
    if config::app::is_configed::get "$PM_APP_NAME"; then
        # 说明已经配置过了
        linfo "app(${PM_APP_NAME}) install guide has configed, not need to config again"
        return "$SHELL_TRUE"
    fi
    "${app_name}::trait::install_guide" || return "$SHELL_FALSE"
    config::app::is_configed::set_true "$PM_APP_NAME" || return "$SHELL_FALSE"
    linfo "app(${PM_APP_NAME}) install guide config success"
}

function custom_manager::command::pre_install() {
    custom_manager::_clean_build || return "$SHELL_FALSE"
    "${app_name}::trait::pre_install" || return "$SHELL_FALSE"
    linfo "app(${PM_APP_NAME}) pre_install success"
}

function custom_manager::main() {
    local app_name="$1"
    local command="$2"

    if [ -z "${app_name}" ]; then
        lerror "param app_name is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "${command}" ]; then
        lerror "param command is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "${SRC_ROOT_DIR}/app/${app_name}" ]; then
        lerror "app($app_name) is not exists"
        return "$SHELL_FALSE"
    fi

    custom_manager::_env "${app_name}" || return 1
    custom_manager::prepare || return "$SHELL_FALSE"

    # shellcheck source=/dev/null
    source "${SRC_ROOT_DIR}/app/${app_name}/trait.sh" || return "$SHELL_FALSE"

    case "$command" in
    "install_guide")
        custom_manager::command::install_guide || return "$SHELL_FALSE"
        ;;

    "pre_install")
        custom_manager::command::pre_install || return "$SHELL_FALSE"
        ;;

    "description" | "install" | "post_install" | "pre_uninstall" | "uninstall" | "post_uninstall" | "upgrade" | "fixme" | "unfixme" | "dependencies" | "features")
        "${app_name}::trait::${command}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "run ${app_name}::trait::${command} failed"
            return "$SHELL_FALSE"
        fi
        linfo "run ${app_name}::trait::${command} success."
        ;;

    *)
        lerror "command($command) is not exists"
        return "$SHELL_FALSE"
        ;;
    esac

    return "${SHELL_TRUE}"
}

custom_manager::main "$@"
