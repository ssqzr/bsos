#!/bin/bash

# 日志库
# 目前支持两种类型的日志
# 1. stream_handler 输出到标准输出、标准错误、终端等。
# 2. file_handler 输出到文件。
# API:
# log::handler::stream_handler::register 注册 stream_handler
# log::handler::stream_handler::set_stream 使用 stream_handler 时设置 stream
#     参数列表：
#         stream 标准输出(stdout)、标准错误(stderr)、终端(tty)、文件(文件路径)。
# log::handler::stream_handler::unregister 注销 stream_handler
# log::handler::file_handler::register 注册 file_handler
# log::handler::file_handler::set_log_file 使用 file_handler 时设置日志文件
#     参数列表：
#         log_filepath 日志文件路径
# log::handler::file_handler::unregister 注销 file_handler
# log::handler::clean 清除所有 handler

# 支持指定日志输出格式，变量使用 {{}} 包裹。
# 可以使用的变量有：
# - {{datetime}} 日期时间
# - {{pid}} 进程 ID
# - {{filename}} 文件名
# - {{function}} 函数名
# - {{line}} 行号
# - {{level}} 日志等级
# - {{message}} 日志内容
# formatter 格式示例：{{datetime}} {{level}} [{{pid}}] {{filename}}:{{line}} [{{function}}] {{message}}
# API:
# log::formatter::set $formatter 来指定 $formatter

# 支持指定时间的格式，时间的格式是 date 命令支持的格式，例如：%Y-%m-%d %H:%M:%S
# API:
# log::formatter::set_datetime_format $datetime_format 来指定 $datetime_format

# 日志API:
# lsuccess、linfo、ldebug、lwarn、lerror
#     关键字参数列表：
#           --caller-frame=FRAME 函数调用层级
#           --handler=HANDLER 日志处理器，支持指定多个，使用 "," 隔开。支持指定多个 --handler=HANDLER 参数。
#           --formatter=FORMATTER 日志格式
#           --stream-handler-formatter=FORMATTER stream_handler 日志格式
#           --stream-handler-stream=STREAM stream_handler 的 STREAM，取值范围是：stdout、stderr、tty、文件路径。
#           --file-handler-formatter=FORMATTER file_handler 日志格式
#           --datetime-format=DATETIME_FORMAT 时间格式
#     位置参数列表：
#           位置参数只有一个时：
#               message 消息内容
#           位置参数有多个时：
#               message-format 消息格式
#               message 消息内容，支持多个。
# lexit 程序退出时的日志
#     关键字参数列表：
#           --caller-frame=FRAME 函数调用层级
#           --handler=HANDLER 日志处理器，支持指定多个，使用 "," 隔开。支持指定多个 --handler=HANDLER 参数。
#           --formatter=FORMATTER 日志格式
#           --stream-handler-formatter=FORMATTER stream_handler 日志格式
#           --file-handler-formatter=FORMATTER file_handler 日志格式
#           --datetime-format=DATETIME_FORMAT 时间格式
#     位置参数列表：
#           exit_code 退出码
# lwrite

if [ -n "${SCRIPT_DIR_30e78b31}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_30e78b31="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/utest.sh" || exit 1

declare LOG_HANDLER_STREAM="stream_handler"
declare LOG_HANDLER_FILE="file_handler"
declare __valid_log_handlers=("$LOG_HANDLER_STREAM" "$LOG_HANDLER_FILE")

function log::_create_dir_recursive() {
    local dir="$1"
    if [ -z "$dir" ]; then
        return "$SHELL_FALSE"
    fi

    mkdir -p "$dir" >/dev/null 2>&1
    if [ $? -ne "$SHELL_TRUE" ]; then
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function log::_create_parent_directory() {
    local filepath="$1"
    local parent_dir
    parent_dir="$(dirname "${filepath}")" || return "$SHELL_FALSE"
    log::_create_dir_recursive "$parent_dir" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# ============================== BEGIN formatter BEGIN ==============================

function log::formatter::_default_datetime_format() {
    # 格式是 date 命令支持的格式
    echo '%Y-%m-%d %H:%M:%S'
}

function log::formatter::_init() {
    local default_datetime_format
    default_datetime_format="$(log::formatter::_default_datetime_format)"

    if [ ! -v "__log_formatter" ]; then
        # 使用环境变量是因为运行子 shell 的时候也可以使用相同的 handler
        export __log_formatter="{{datetime}} {{level}} [{{pid}}] {{filename}}:{{line}} [{{function}}] {{message}}"
    fi
    if [ ! -v "__log_datetime_format" ]; then
        # 使用环境变量是因为运行子 shell 的时候也可以使用相同的 handler

        export __log_datetime_format="$default_datetime_format"
    fi
    return "$SHELL_TRUE"
}

# log_format 的格式类似: "xxxxxx {{datetime:SSSSSSSSS}} xxxxxxx"
function log::formatter::_get_datetime_foramt() {
    local log_formatter="$1"

    local datetime_format

    log_formatter="${log_formatter:-$__log_formatter}"

    datetime_format=$(grep -o -P "\{\{datetime.*?}}" <<<"${log_formatter}")

    if [ "$datetime_format" == "{{datetime}}" ] || [ "$datetime_format" == "{{datetime:}}" ]; then
        datetime_format=""
    fi

    if [ -z "${datetime_format}" ]; then
        datetime_format=$(log::formatter::_default_datetime_format)
    elif [ "$datetime_format" == "{{datetime}}" ] || [ "$datetime_format" == "{{datetime:}}" ]; then
        datetime_format=$(log::formatter::_default_datetime_format)
    else
        datetime_format="${datetime_format#*:}"
        datetime_format="${datetime_format%*\}\}}"
    fi
    printf "%s" "$datetime_format"
}

function log::formatter::set() {
    local formatter="$1"

    export __log_formatter="$formatter"
}

# 格式是 date 命令支持的格式
function log::formatter::set_datetime_format() {
    local format="$1"

    export __log_datetime_format="$format"
}

function log::formatter::_format_message() {
    local -n _9e86f16f_result="$1"
    shift
    local formatter="$1"
    shift
    local level="$1"
    shift
    local datetime="$1"
    shift
    local pid="$1"
    shift
    local filename="$1"
    shift
    local line="$1"
    shift
    local function_name="$1"
    shift
    local message_format="$1"
    shift
    local message_params
    message_params=("$@")

    local _5faa5dc6_temp_str

    local message
    # shellcheck disable=SC2059
    printf -v message "$message_format" "${message_params[@]}"

    _5faa5dc6_temp_str="${formatter}"
    # 先替换常规字符的
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{level\}\}/${level}}"
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{pid\}\}/${pid}}"
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{line\}\}/${line}}"
    # 再替换可能包含其他字符的
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{function\}\}/${function_name}}"
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{filename\}\}/${filename}}"
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{datetime\}\}/${datetime}}"
    # 最后替换 message，因为 message 可能包含诸如 {{xxx}} 这样的
    _5faa5dc6_temp_str="${_5faa5dc6_temp_str//\{\{message\}\}/${message}}"

    # _9e86f16f_result="$(echo "${formatter}" | sed -e "s/{{level}}/${level}/g" -e "s/{{datetime}}/${datetime}/g" -e "s/{{pid}}/${pid}/g" -e "s/{{filename}}/${filename}/g" -e "s/{{line}}/${line}/g" -e "s/{{function}}/${function_name}/g" -e "s/{{message}}/${message}/g")" || return "$SHELL_FALSE"
    _9e86f16f_result="${_5faa5dc6_temp_str}"
    return "$SHELL_TRUE"
}

# ============================== END formatter END ==============================

# ============================== BEGIN handler BEGIN ==============================

function log::handler::_init() {
    if [ -v "__log_handler" ]; then
        return "$SHELL_TRUE"
    fi

    log::handler::file_handler::register || return "$SHELL_FALSE"
}

function log::handler::_check_handler_name() {
    local handler="$1"
    grep -q -w "$handler" <<<"${__valid_log_handlers[*]}"
    if [ "$?" -eq "$SHELL_FALSE" ]; then
        # println_error "invalid log handler: $handler"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function log::handler::_add() {
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

function log::handler::_remove() {
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

# ============================== END handler END ==============================

# ============================== BEGIN stream_handler BEGIN ==============================

function log::handler::stream_handler::_init() {
    if [ -v "__log_stream_handler_stream" ]; then
        return "$SHELL_TRUE"
    fi
    export __log_stream_handler_stream="tty"
}

function log::handler::stream_handler::set_stream() {
    local stream="$1"
    export __log_stream_handler_stream="$stream"
}

function log::handler::stream_handler::register() {
    log::handler::_add "$LOG_HANDLER_STREAM" || return "$SHELL_FALSE"
    log::handler::stream_handler::_init || return "$SHELL_FALSE"
}

function log::handler::stream_handler::unregister() {
    log::handler::_remove "$LOG_HANDLER_STREAM" || return "$SHELL_FALSE"
}

function log::handler::stream_handler::log() {
    local stream="$1"
    shift
    local formatter="$1"
    shift
    local level="$1"
    shift
    local datetime="$1"
    shift
    local pid="$1"
    shift
    local filename="$1"
    shift
    local line="$1"
    shift
    local function_name="$1"
    shift
    local message_format="$1"
    shift
    local message_params=("$@")

    local formated_message

    log::formatter::_format_message formated_message "${formatter}" "${level}" "${datetime}" "${pid}" "${filename}" "${line}" "${function_name}" "${message_format}" "${message_params[@]}" || return "$SHELL_FALSE"

    "println_${level}" --stream="$stream" "${formated_message}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# ============================== END stream_handler END ==============================

# ============================== BEGIN file_handler BEGIN ==============================

function log::handler::file_handler::_init() {
    if [ -n "${__log_file_handler_filepath}" ]; then
        return "$SHELL_TRUE"
    fi
    local log_dir="${XDG_CACHE_HOME:-$HOME/.cache}"

    # 使用环境变量是因为运行子 shell 的时候也可以使用相同的日志文件
    export __log_file_handler_filepath="${log_dir}/bsos/bsos.log"
    log::_create_parent_directory "${__log_file_handler_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function log::handler::file_handler::register() {
    log::handler::_add "$LOG_HANDLER_FILE" || return "$SHELL_FALSE"
    log::handler::file_handler::_init || return "$SHELL_FALSE"
}

function log::handler::file_handler::unregister() {
    log::handler::_remove "$LOG_HANDLER_FILE" || return "$SHELL_FALSE"
}

# 路径不支持~
# realpath命令也不支持~，例如~/xxxx
function log::handler::file_handler::set_log_file() {
    local filepath="$1"
    # 转成绝对路径
    filepath="$(realpath "${filepath}")"
    if [ -z "$filepath" ]; then
        return "$SHELL_FALSE"
    fi

    export __log_file_handler_filepath="${filepath}"

    log::_create_parent_directory "${__log_file_handler_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function log::handler::file_handler::log() {
    local stream="$1"
    shift
    local formatter="$1"
    shift
    local level="$1"
    shift
    local datetime="$1"
    shift
    local pid="$1"
    shift
    local filename="$1"
    shift
    local line="$1"
    shift
    local function_name="$1"
    shift
    local message_format="$1"
    shift
    local message_params=("$@")

    local formated_message

    log::formatter::_format_message formated_message "${formatter}" "${level}" "${datetime}" "${pid}" "${filename}" "${line}" "${function_name}" "${message_format}" "${message_params[@]}" || return "$SHELL_FALSE"

    printf "%s\n" "${formated_message}" >>"${stream}"
}

# ============================== END file_handler END ==============================

# ============================== BEGIN log API BEGIN ==============================

function log::_log() {
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

    local pid="$$"
    local function_name
    local filename
    local line
    local datetime
    local datetime_format
    local stream

    local handler
    local temp_str
    local temp_array=()
    local param

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
            # shellcheck disable=SC2001
            temp_str="$(echo "$temp_str" | sed -e "s/,/\n/g")" || return "$SHELL_FALSE"
            readarray -t temp_array < <(echo "$temp_str")
            for handler in "${temp_array[@]}"; do
                if [ -z "$handler" ]; then
                    continue
                fi
                handlers+=("$handler")
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

    message_format="${message_format:-%s}"

    formatter="${formatter:-${__log_formatter}}"
    stream_handler_formatter="${stream_handler_formatter:-${formatter}}"
    file_handler_formatter="${file_handler_formatter:-${formatter}}"

    caller_frame="${caller_frame:-0}"
    ((caller_frame += 1))

    function_name=$(get_caller_function_name "${caller_frame}")
    filename=$(get_caller_filename "${caller_frame}")
    line=$(get_caller_file_line_num "${caller_frame}")

    datetime_format="${datetime_format:-${__log_datetime_format}}"
    datetime="$(date "+${datetime_format}")"

    # shellcheck disable=SC2001
    readarray -t handlers < <(echo "${__log_handler}" | sed 's/,/\n/g')

    for handler in "${handlers[@]}"; do
        if [ -z "$handler" ]; then
            continue
        fi
        case "$handler" in
        "${LOG_HANDLER_STREAM}")
            formatter="${stream_handler_formatter}"
            stream="${stream_handler_stream:-${__log_stream_handler_stream}}"
            ;;
        "${LOG_HANDLER_FILE}")
            formatter="${file_handler_formatter}"
            stream="${__log_file_handler_filepath}"
            ;;
        *) ;;
        esac

        "log::handler::${handler}::log" "$stream" "${formatter}" "${level}" "$datetime" "$pid" "$filename" "${line}" "${function_name}" "${message_format}" "${message_params[@]}" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

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

    if [ ! -v level ]; then
        println_error "log level is required"
        return "$SHELL_FALSE"
    fi

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

    log::_log --caller-frame="${caller_frame}" --level="$level" --message-format="${message_format}" "${other_options[@]}" "${message_params[@]}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function lsuccess() {
    local level="success"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
    # local message_format
    # local message_params
    # local caller_frame

    # local other_options=()
    # local other_params=()

    # local param
    # for param in "$@"; do
    #     case "$param" in
    #     --caller-frame=*)
    #         caller_frame="${param#*=}"
    #         ;;
    #     --level=* | --message-format=*)
    #         println_error "unknown option $param"
    #         return "$SHELL_FALSE"
    #         ;;
    #     -*)
    #         other_options+=("$param")
    #         ;;
    #     *)
    #         other_params+=("$param")
    #         ;;
    #     esac
    # done

    # caller_frame=${caller_frame:-0}
    # ((caller_frame += 1))

    # if [ "${#other_params[@]}" -gt 1 ]; then
    #     message_format="${other_params[0]}"
    #     message_params=("${other_params[@]:1}")
    # else
    #     message_format="%s"
    #     message_params=("${other_params[@]}")
    # fi

    # log::_log --caller-frame="${caller_frame}" --level="$level" --message-format="${message_format}" "${other_options[@]}" "${message_params[@]}" || return "$SHELL_FALSE"

    # return "$SHELL_TRUE"
}

function linfo() {
    local level="info"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function ldebug() {
    local level="debug"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function lwarn() {
    local level="warn"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function lerror() {
    local level="error"

    log::_log_wrap --level="${level}" "$@" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function lexit() {
    local level="error"

    local caller_frame
    local message
    local exit_code

    local other_options=()

    local param
    for param in "$@"; do
        case "$param" in
        --caller-frame=*)
            caller_frame="${param#*=}"
            ;;
        --level=* | --message-format=*)
            println_error "unknown option $param"
            return "$SHELL_FALSE"
            ;;
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

    caller_frame=${caller_frame:-0}
    ((caller_frame += 1))

    message="script exit with code ${exit_code}"

    log::_log --caller-frame="${caller_frame}" --level="$level" "${message}" || return "$SHELL_FALSE"

    exit "${exit_code}"
}

function lwrite() {
    cat >>"${__log_file_handler_filepath}"
}

# ============================== END log API END ==============================

# ==================================== 下面是测试代码 ====================================

function log::_test::formatter::_get_datetime_foramt() {
    local formatter
    local default
    local temp_format
    default="$(log::formatter::_default_datetime_format)"

    __log_formatter=""
    formatter=$(log::formatter::_get_datetime_foramt)
    utest::assert_equal "${formatter}" "${default}"

    __log_formatter="{{datetime}}"
    formatter=$(log::formatter::_get_datetime_foramt)
    utest::assert_equal "${formatter}" "${default}"

    __log_formatter="{{datetime:yyyy-MM-dd HH:mm:ss}}"
    formatter=$(log::formatter::_get_datetime_foramt)
    utest::assert_equal "${formatter}" "yyyy-MM-dd HH:mm:ss"

    temp_format='`1234567890-=~!@#$%^&*()_+[]{}\|;:,.<>/?'
    temp_format+="'\""
    __log_formatter="{{datetime:${temp_format}}}"
    formatter=$(log::formatter::_get_datetime_foramt)
    utest::assert_equal "${formatter}" "${temp_format}"

    __log_formatter="{{datetime:123}}"
    formatter=$(log::formatter::_get_datetime_foramt "{{12datetime:abc}}")
    utest::assert_equal "${formatter}" "${default}"

    temp_format='`1234567890-=~!@#$%^&*()_+[]{}\|;:,.<>/?'
    temp_format+="'\""
    __log_formatter=""
    formatter=$(log::formatter::_get_datetime_foramt "{{datetime:${temp_format}}}")
    utest::assert_equal "${formatter}" "${temp_format}"
}

function log::_test::_check_log_handler() {
    log::handler::_check_handler_name ""
    utest::assert_fail $?

    log::handler::_check_handler_name "xxxx"
    utest::assert_fail $?

    log::handler::_check_handler_name "${LOG_HANDLER_FILE}"
    utest::assert $?

    log::handler::_check_handler_name "${LOG_HANDLER_STREAM}"
    utest::assert $?

    return "$SHELL_TRUE"
}

function log::_test::add_handler() {
    log::handler::_add ""
    utest::assert_fail $?

    log::handler::_add "xxxx"
    utest::assert_fail $?

    __log_handler=""
    log::handler::_add "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE}"

    __log_handler=""
    log::handler::_add "${LOG_HANDLER_FILE}"
    log::handler::_add "${LOG_HANDLER_STREAM}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"
    log::handler::_add "${LOG_HANDLER_STREAM}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"

    return "$SHELL_TRUE"
}

function log::_test::remove_handler() {
    log::handler::_remove ""
    utest::assert_fail $?

    log::handler::_remove "xxxx"
    utest::assert_fail $?

    __log_handler=""
    log::handler::_remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler="${LOG_HANDLER_FILE}"
    log::handler::_remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler="${LOG_HANDLER_FILE},"
    log::handler::_remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler=",${LOG_HANDLER_FILE}"
    log::handler::_remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ""

    __log_handler=",${LOG_HANDLER_FILE},"
    log::handler::_remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" ","

    __log_handler="${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"
    log::handler::_remove "${LOG_HANDLER_FILE}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_STREAM}"

    __log_handler="${LOG_HANDLER_FILE},${LOG_HANDLER_STREAM}"
    log::handler::_remove "${LOG_HANDLER_STREAM}"
    utest::assert $?
    utest::assert_equal "${__log_handler}" "${LOG_HANDLER_FILE}"
}

function log::_test::all() {
    # source 进来的就不要测试了
    local parent_function_name
    parent_function_name=$(get_caller_function_name 2)
    if [ "$parent_function_name" = "source" ]; then
        return "$SHELL_TRUE"
    fi

    log::_test::formatter::_get_datetime_foramt
    log::_test::_check_log_handler || return "$SHELL_FALSE"
    log::_test::add_handler || return "$SHELL_FALSE"
    log::_test::remove_handler || return "$SHELL_FALSE"

}

function log::_main() {
    log::formatter::_init || exit "$CODE_ERROR"
    log::handler::_init || exit "$CODE_ERROR"

    if [ "$TEST" == "true" ] || [ "$TEST" == "1" ]; then
        log::_test::all || return "$SHELL_FALSE"
    fi
}

log::_main
