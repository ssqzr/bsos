#!/bin/bash

# 日志库

# 目前支持两种类型的日志
# 1. stream_handler                                         输出到标准输出、标准错误、终端等。
#   API:
#       log::handler::stream_handler::register              注册 stream_handler
#       log::handler::stream_handler::set_stream            使用 stream_handler 时设置 stream
#           参数列表：
#               stream                                      标准输出(stdout)、标准错误(stderr)、终端(tty)、文件(文件路径)。
#       log::handler::stream_handler::unregister            注销 stream_handler
# 2. file_handler                                           输出到文件。
#   API:
#       log::handler::file_handler::register                注册 file_handler
#       log::handler::file_handler::set_log_file            使用 file_handler 时设置日志文件
#           参数列表：
#               log_filepath                                日志文件路径
#       log::handler::file_handler::unregister              注销 file_handler

# 支持指定日志输出格式，变量使用 {{}} 包裹。
# 可以使用的变量有：
# - {{datetime}}                                            日期时间
# - {{pid}}                                                 进程 ID
# - {{file}}                                                文件
# - {{function}}                                            函数名
# - {{line}}                                                行号
# - {{level}}                                               日志等级
# - {{message}}                                             日志内容
# formatter 格式示例：{{datetime}} {{level}} [{{pid}}] {{file}}:{{line}} [{{function}}] {{message}}
# API:
#   log::formatter::set                                     设置输出格式
#       参数列表：
#           formatter                                       输出格式定义

# 支持指定时间的格式，时间的格式是 date 命令支持的格式，例如：%Y-%m-%d %H:%M:%S
# API:
#   log::formatter::set_datetime_format                     设置时间格式
#       参数列表：
#           datetime_format                                 时间格式定义

# 全部 API 概览:
#   log::formatter::set FORMATTER                             设置日志的输出格式
#   log::formatter::set_datetime_format DATETIME_FORMAT       设置日志里时间的格式

#   log::handler::stream_handler::register                    添加 stream_handler
#   log::handler::stream_handler::unregister                  删除 stream_handler
#   log::handler::stream_handler::set_stream STREAM           设置 stream_handler 的 stream

#   log::handler::file_handler::register                      添加 file_handler
#   log::handler::file_handler::unregister                    删除 file_handler
#   log::handler::file_handler::set_log_file FILEPATH         设置 file_handler 的 log_file

#   log::handler::clean                                       清除所有 handler

#   lsuccess                                                成功日志
#   linfo                                                   流程日志
#   ldebug                                                  调试日志
#   lwarn                                                   告警日志
#   lerror                                                  错误日志
#   lexit                                                   程序退出时的日志输出
#   lwrite                                                  将标准输出的内容直接写入日志文件

if [ -n "${SCRIPT_DIR_30e78b31}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_30e78b31="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/../array.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/../string.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/../utest.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/handler.sh" || exit 1

function log::_log_wrap() {
    local level
    local message_format
    local message_params
    local caller_frame

    local other_options=()
    local other_params=()

    local param
    for param in "$@"; do
        case "$param" in
        --caller-frame=*)
            caller_frame="${param#*=}"
            ;;
        --level=*)
            if [ ! -v level ]; then
                level="${param#*=}"
                continue
            fi
            # 指定了多个，这个是封装的一层，除了 linfo 等函数调用外， linfo 等函数的调用者不应该指定这个参数
            println_error "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        --message-format=*)
            println_error "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        -*)
            other_options+=("$param")
            ;;
        *)
            other_params+=("$param")
            ;;
        esac
    done

    level="${level:-info}"

    caller_frame=${caller_frame:-0}
    # 由于是封装的一层， linfo 等函数是直接传进来的，所以需要算上 linfo 等函数的层级
    ((caller_frame += 2))

    if [ "${#other_params[@]}" -gt 1 ]; then
        message_format="${other_params[0]}"
        message_params=("${other_params[@]:1}")
    else
        message_format="%s"
        message_params=("${other_params[@]}")
    fi

    log::handler::log --caller-frame="${caller_frame}" --level="$level" --message-format="${message_format}" "${other_options[@]}" "${message_params[@]}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# ============================== BEGIN log API BEGIN ==============================

# 关键字参数列表：
#   --caller-frame=FRAME                        函数调用层级
#   --handler=HANDLER[,HANDLER]                 日志处理器，支持重复指定。
#       - HANDLER 的写法如下：
#           - "handler_name"                    指定为 handler_name 的日志处理器
#           - "+handler_name"                   添加为 handler_name 的日志处理器
#           - "-handler_name"                   移除为 handler_name 的日志处理器
#       - 多个 HANDLER 规则使用 "," 隔开。
#       - 支持指定多个 --handler 参数。
#   --formatter=FORMATTER                       日志格式。如果指定了，所有 handler 默认使用此格式。
#   --stream-handler-formatter=FORMATTER        stream_handler 日志格式
#   --stream-handler-stream=STREAM              stream_handler 的 STREAM，取值范围是：stdout、stderr、tty、文件路径。
#   --file-handler-formatter=FORMATTER          file_handler 日志格式
#   --datetime-format=DATETIME_FORMAT           时间格式
# 位置参数列表：
#   位置参数只有一个时：
#       message                                 消息内容
#   位置参数有多个时：
#       message-format                          消息格式
#       message                                 消息内容，支持多个。
function lsuccess() {
    local level="success"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 参数说明参考 lsuccess
function linfo() {
    local level="info"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 参数说明参考 lsuccess
function ldebug() {
    local level="debug"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 参数说明参考 lsuccess
function lwarn() {
    local level="warn"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 参数说明参考 lsuccess
function lerror() {
    local level="error"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 关键字参数列表：
#   --caller-frame=FRAME                        函数调用层级
#   --handler=HANDLER                           日志处理器。参考 lsuccess 等函数的参数说明
#   --formatter=FORMATTER                       日志格式
#   --stream-handler-formatter=FORMATTER        stream_handler 日志格式
#   --file-handler-formatter=FORMATTER          file_handler 日志格式
#   --datetime-format=DATETIME_FORMAT           时间格式
# 位置参数列表：
#   exit_code 退出码
function lexit() {
    local level="error"

    local message
    local exit_code

    local other_options=()

    local param
    for param in "$@"; do
        case "$param" in
        -*)
            other_options+=("$param")
            ;;
        *)
            if [ ! -v exit_code ]; then
                exit_code="$param"
                continue
            fi
            println_error "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    message="script exit with code ${exit_code}"

    log::_log_wrap --level="$level" "${other_options[@]}" "${message}" || return "$SHELL_FALSE"

    exit "${exit_code}"
}

# 参数说明参考 lsuccess
function lwrite() {
    local message
    while IFS= read -r message || [ -n "$message" ]; do
        log::_log_wrap --formatter="{{message}}" "${message}" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

# ============================== END log API END ==============================

# ==================================== 下面是测试代码 ====================================

function TEST::log::all() {
    # source 进来的就不要测试了
    local parent_function_name
    parent_function_name=$(get_caller_function_name 2)
    if [ "$parent_function_name" = "source" ]; then
        return "$SHELL_TRUE"
    fi

}

function log::_main() {

    if string::is_true "$TEST"; then
        TEST::log::all || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

log::_main
