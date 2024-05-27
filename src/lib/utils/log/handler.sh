#!/bin/bash

if [ -n "${SCRIPT_DIR_1fc52484}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1fc52484="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/../string.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/../utest.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/utils.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/formatter.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/stream_handler.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1fc52484}/file_handler.sh" || exit 1

declare LOG_HANDLER_STREAM="stream_handler"
declare LOG_HANDLER_FILE="file_handler"
declare __valid_log_handlers=("$LOG_HANDLER_STREAM" "$LOG_HANDLER_FILE")

function log::handler::_init() {
    if [ -v "__log_handler" ]; then
        return "$SHELL_TRUE"
    fi

    export __log_handler=""

    log::handler::file_handler::register || return "$SHELL_FALSE"
}

function log::handler::_check_handler_name() {
    local handler="$1"

    if [ -z "$handler" ]; then
        println_error "parameter handler is empty"
        return "$SHELL_FALSE"
    fi

    grep -q -w "$handler" <<<"${__valid_log_handlers[*]}"
    if [ "$?" -eq "$SHELL_FALSE" ]; then
        println_error "invalid log handler: $handler"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function log::handler::get() {
    local -n handlers_dcf99861="$1"

    string::split_with "${!handlers_dcf99861}" "${__log_handler}" "," || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function log::handler::add() {
    local handler="$1"

    log::handler::_check_handler_name "$handler" || return "$SHELL_FALSE"

    grep -q -w "$handler" <<<"$__log_handler"
    if [ "$?" -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi
    if [ -z "${__log_handler}" ]; then
        export __log_handler="$handler"
    else
        export __log_handler="${__log_handler},$handler"
    fi
    return "$SHELL_TRUE"
}

function log::handler::remove() {
    local handler="$1"
    local temp_str

    log::handler::_check_handler_name "$handler" || return "$SHELL_FALSE"

    temp_str="$(echo "${__log_handler}" | sed -e "s/^${handler}$//g" -e "s/^$handler,//g" -e "s/,$handler$//g" -e "s/,$handler,/,/g")" || return "$SHELL_TRUE"

    export __log_handler="${temp_str}"

    return "$SHELL_TRUE"
}

function log::handler::clean() {
    export __log_handler=""
}

# 参数说明
# 必选参数：
#     --level=LEVEL               日志级别
#     --file=FILE                 文件路径
#     --line=LINE                 行号
#     --function-name=FUNCTION    函数名
# 可选参数：
#     --stream=STREAM             输出流
#     --formatter=FORMATTER       日志的格式
#     --datetime-format=FORMAT    时间格式
#     --message-format=FORMAT     消息格式
# 位置参数：
#     message-params              消息参数
function log::handler::template_handler::trait::log() {
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
        --function-name=*)
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

    stream="${stream:-/dev/stdout}"

    message=$(log::formatter::format_message --formatter="${formatter}" --level="${level}" --datetime-format="${datetime_format}" --file="${file}" --line="${line}" --function-name="${function_name}" --message-format="${message_format}" "${message_params[@]}") || return "$SHELL_FALSE"

    printf "%s\n" "${message}" >>"${stream}"
}

# 参数说明
# 必选参数
#   --level=LEVEL                       日志级别
# 可选参数
#   --caller-frame=FRAME                调用栈帧
#   --handler=HANDLER                   日志处理器
#   --stream=STREAM                     输出流
#   --formatter=FORMATTER               日志的格式
#   --stream-handler-formatter          stream_handler 日志格式
#   --stream-handler-stream=STREAM      stream_handler 输出流
#   --file-handler-formatter            file_handler 日志格式
#   --datetime-format=FORMAT            时间格式
#   --message-format=FORMAT             消息格式
# 位置参数
#     message-params              消息参数
function log::handler::log() {
    # 参数
    local level
    local message_format
    local message_params=()
    local caller_frame
    local handlers=()
    local formatter
    local stream_handler_formatter
    local stream_handler_stream
    local file_handler_formatter
    local datetime_format

    local function_name
    local file
    local line
    local stream

    local handler
    local temp_str
    local temp_array=()
    local param

    log::handler::get handlers || return "$SHELL_FALSE"

    for param in "$@"; do
        case "$param" in
        --level=*)
            level="${param#*=}"
            ;;
        --caller-frame=*)
            caller_frame="${param#*=}"
            ;;
        --handler=*)
            temp_str="${param#*=}"
            string::split_with temp_array "${temp_str}" "," || return "$SHELL_FALSE"
            for handler in "${temp_array[@]}"; do
                handler=$(string::trim "$handler") || return "$SHELL_FALSE"
                if [ -z "$handler" ]; then
                    continue
                fi

                if [ "${handler:0:1}" == "+" ]; then
                    handler="${handler:1}"
                    handler=$(string::trim "$handler") || return "$SHELL_FALSE"
                    if [ -z "$handler" ]; then
                        continue
                    fi
                    array::rpush_unique handlers "${handler}" || return "$SHELL_FALSE"
                elif [ "${handler:0:1}" == "-" ]; then
                    handler="${handler:1}"
                    handler=$(string::trim "$handler") || return "$SHELL_FALSE"
                    if [ -z "$handler" ]; then
                        continue
                    fi
                    array::remove handlers "${handler}" || return "$SHELL_FALSE"
                else
                    handlers=("$handler")
                fi
            done
            ;;
        --formatter=*)
            formatter="${param#*=}"
            ;;
        --stream-handler-formatter=*)
            stream_handler_formatter="${param#*=}"
            ;;
        --stream-handler-stream=*)
            stream_handler_stream="${param#*=}"
            ;;
        --file-handler-formatter=*)
            file_handler_formatter="${param#*=}"
            ;;
        --datetime-format=*)
            datetime_format="${param#*=}"
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

    stream_handler_formatter="${stream_handler_formatter:-${formatter}}"
    file_handler_formatter="${file_handler_formatter:-${formatter}}"

    caller_frame="${caller_frame:-0}"
    ((caller_frame += 1))

    function_name=$(get_caller_function_name "${caller_frame}")
    file=$(debug::function::filepath "${caller_frame}")
    line=$(get_caller_file_line_num "${caller_frame}")

    for handler in "${handlers[@]}"; do
        if [ -z "$handler" ]; then
            continue
        fi
        case "$handler" in
        "${LOG_HANDLER_STREAM}")
            formatter="${stream_handler_formatter}"
            stream="${stream_handler_stream}"
            ;;
        "${LOG_HANDLER_FILE}")
            formatter="${file_handler_formatter}"
            ;;
        *) ;;
        esac

        # 底层 handler 需要实现 log::handler::${handler}::trait::log 函数
        # 函数模板见： log::handler::template_handler::trait::log
        "log::handler::${handler}::trait::log" --stream="$stream" --formatter="${formatter}" --level="${level}" --datetime-format="${datetime_format}" --file="${file}" --line="${line}" --function-name="${function_name}" --message-format="${message_format}" "${message_params[@]}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

# ==================================== 下面是测试代码 ====================================

function TEST::log::handler::_check_handler_name() {
    log::handler::_check_handler_name "" >/dev/null
    utest::assert_fail $?

    log::handler::_check_handler_name "xxxx" >/dev/null
    utest::assert_fail $?

    log::handler::_check_handler_name "${LOG_HANDLER_FILE}"
    utest::assert $?

    log::handler::_check_handler_name "${LOG_HANDLER_STREAM}"
    utest::assert $?

    return "$SHELL_TRUE"
}

function TEST::log::handler::add() {
    log::handler::add "" >/dev/null
    utest::assert_fail $?

    log::handler::add "xxxx" >/dev/null
    utest::assert_fail $?

    __log_handler=""
    log::handler::add "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE}"

    __log_handler=""
    log::handler::add "${LOG_HANDLER_FILE}"
    log::handler::add "${LOG_HANDLER_STREAM}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"
    log::handler::add "${LOG_HANDLER_STREAM}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"

    return "$SHELL_TRUE"
}

function TEST::log::handler::remove() {
    log::handler::remove "" >/dev/null
    utest::assert_fail $?

    log::handler::remove "xxxx" >/dev/null
    utest::assert_fail $?

    __log_handler=""
    log::handler::remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler="${LOG_HANDLER_FILE}"
    log::handler::remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler="${LOG_HANDLER_FILE},"
    log::handler::remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler=",${LOG_HANDLER_FILE}"
    log::handler::remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler=",${LOG_HANDLER_FILE},"
    log::handler::remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ","

    __log_handler="${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"
    log::handler::remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_STREAM}"

    __log_handler="${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"
    log::handler::remove "${LOG_HANDLER_STREAM}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE}"
}

# ==================================== 下面是测试代码 ====================================

function log::handler::_main() {

    log::handler::_init || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

log::handler::_main
