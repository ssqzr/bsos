#!/bin/bash

if [ -n "${SCRIPT_DIR_96697859}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_96697859="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_96697859}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_96697859}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_96697859}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_96697859}/../string.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_96697859}/../utest.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_96697859}/formatter.sh" || exit 1

function log::handler::file_handler::_init() {
    if [ -n "${__log_file_handler_filepath}" ]; then
        return "$SHELL_TRUE"
    fi
    local log_dir="${XDG_CACHE_HOME:-$HOME/.cache}"

    # 使用环境变量是因为运行子 shell 的时候也可以使用相同的日志文件
    export __log_file_handler_filepath="${log_dir}/bsos/bsos.log"
    log::utils::create_parent_directory "${__log_file_handler_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function log::handler::file_handler::register() {
    log::handler::add "$LOG_HANDLER_FILE" || return "$SHELL_FALSE"
    log::handler::file_handler::_init || return "$SHELL_FALSE"
}

function log::handler::file_handler::unregister() {
    log::handler::remove "$LOG_HANDLER_FILE" || return "$SHELL_FALSE"
}

# 路径不支持~
# realpath命令也不支持~，例如~/xxxx
function log::handler::file_handler::set_log_file() {
    local filepath="$1"
    filepath=$(string::trim "$filepath")
    if [ "${filepath:0:1}" = "~" ]; then
        filepath="${HOME}${filepath:1}"
    fi
    # 转成绝对路径
    filepath="$(realpath "${filepath}")"
    if [ -z "$filepath" ]; then
        return "$SHELL_FALSE"
    fi

    export __log_file_handler_filepath="${filepath}"

    log::utils::create_parent_directory "${__log_file_handler_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 参数说明参考 log::handler::template_handler::trait::log
function log::handler::file_handler::trait::log() {
    local stream
    local formatter
    local level
    local datetime_format
    local file
    local line
    local function_name
    local message_format
    local message_params=()

    local message
    local param

    for param in "$@"; do
        case "$param" in
        --stream=*)
            stream="${param#*=}"
            ;;
        --formatter=*)
            formatter="${param#*=}"
            ;;
        --level=*)
            level="${param#*=}"
            ;;
        --datetime-format=*)
            datetime_format="${param#*=}"
            ;;
        --file=*)
            file="${param#*=}"
            ;;
        --line=*)
            line="${param#*=}"
            ;;
        --function=*)
            function_name="${param#*=}"
            ;;
        --message-format=*)
            message_format="${param#*=}"
            ;;
        -*)
            println_error "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            message_params+=("$param")
            ;;
        esac
    done

    stream="${stream:-${__log_file_handler_filepath}}"

    message=$(log::formatter::format_message --formatter="${formatter}" --level="${level}" --datetime-format="${datetime_format}" --file="${file}" --line="${line}" --function="${function_name}" --message-format="${message_format}" "${message_params[@]}") || return "$SHELL_FALSE"

    if [ -z "$stream" ]; then
        printf "%s\n" "${message}"
    else
        printf "%s\n" "${message}" >>"${stream}"
    fi
}

# ==================================== 下面是测试代码 ====================================

function TEST::log::handler::file_handler::trait::log() {
    local stream="/dev/stdout"
    local output

    # 测试 formatter
    output=$(log::handler::file_handler::trait::log --stream="${stream}" --formatter="{{datetime}} {{level}} {{file}}:{{line}} [{{function}}] {{message}}" --level="debug" --file="test.sh" --line="10" --function="main" --datetime-format="%Y" --message-format="%s|%s" "hello world" "hello world")
    utest::assert $?
    utest::assert_equal "${output}" "$(log::formatter::get_datetime_by_format "%Y") debug test.sh:10 [main] hello world|hello world"

}

function log::handler::file_handler::_main() {
    log::handler::file_handler::_init || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

log::handler::file_handler::_main
