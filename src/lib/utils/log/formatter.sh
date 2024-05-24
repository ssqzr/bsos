#!/bin/bash

if [ -n "${SCRIPT_DIR_aa90c9d9}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_aa90c9d9="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_aa90c9d9}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_aa90c9d9}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_aa90c9d9}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_aa90c9d9}/../string.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_aa90c9d9}/../utest.sh" || exit 1

function log::formatter::default_datetime_format() {
    # 格式是 date 命令支持的格式
    echo '%Y-%m-%d %H:%M:%S'
}

function log::formatter::default_formatter() {
    echo "{{datetime}} {{level}} [{{pid}}] {{file}}:{{line}} [{{function}}] {{message}}"
}

function log::formatter::_init() {
    local default_formatter
    local default_datetime_format
    default_formatter="$(log::formatter::default_formatter)"
    default_datetime_format="$(log::formatter::default_datetime_format)"

    if [ ! -v "__log_formatter" ]; then
        # 使用环境变量是因为运行子 shell 的时候也可以使用相同的 handler
        export __log_formatter="${default_formatter}"
    fi
    if [ ! -v "__log_datetime_format" ]; then
        # 使用环境变量是因为运行子 shell 的时候也可以使用相同的 handler

        export __log_datetime_format="$default_datetime_format"
    fi
    return "$SHELL_TRUE"
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

function log::formatter::get_datetime_by_format() {
    local format="$1"
    local datetime

    format="${format:-$__log_datetime_format}"
    datetime="$(date "+${format}")" || return "$SHELL_FALSE"
    echo "$datetime"
    return "$SHELL_TRUE"
}

# 参数说明
# 必选参数：
#     --level=LEVEL               日志级别
#     --file=FILE                 文件路径
#     --line=LINE                 行号
#     --function=FUNCTION         函数名
# 可选参数：
#     --formatter=FORMATTER       日志的格式
#     --datetime-format=FORMAT    时间格式
#     --message-format=FORMAT     消息格式
# 位置参数：
#     message-params              消息参数
function log::formatter::format_message() {
    # 参数列表
    local formatter
    local level
    local datetime_format
    local file
    local line
    local function_name
    local message_format
    local message_params=()

    local pid="$$"
    local param
    local message
    local temp_str
    local datetime
    local is_patsub_replacement

    for param in "$@"; do
        case "$param" in
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

    # 赋默认值
    formatter="${formatter:-$__log_formatter}"
    message_format="${message_format:-%s}"

    datetime="$(log::formatter::get_datetime_by_format "$datetime_format")" || return "$SHELL_FALSE"

    # shellcheck disable=SC2059
    printf -v message "$message_format" "${message_params[@]}"

    # https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
    # patsub_replacement 默认是启用的
    # ${temp_str//\{\{message\}\}/${message}} 当 $message 包含 "&" 字符时，"&" 会被替换为匹配模式，也就是 "{{message}}"
    # 例如：
    # temp_str="{{message}}"
    # message="abc&"
    # temp_str="${temp_str//\{\{message\}\}/${message}}"
    # echo $temp_str 将输出 abc{{message}}
    if shopt -q patsub_replacement; then
        is_patsub_replacement="$SHELL_TRUE"
        shopt -u patsub_replacement
    fi

    # 由于 message 可能包含各种特殊字符，所以不能使用 sed 命令。
    # 例如： sed -e "s/{{message}}/${message}/g" 当 $message 包含 "/" 字符时，会出现问题，并且没法转义
    temp_str="${formatter}"
    # 先替换常规字符的
    temp_str="${temp_str//\{\{level\}\}/${level}}"
    temp_str="${temp_str//\{\{pid\}\}/${pid}}"
    temp_str="${temp_str//\{\{line\}\}/${line}}"
    # 再替换可能包含其他字符的
    temp_str="${temp_str//\{\{function\}\}/${function_name}}"
    temp_str="${temp_str//\{\{file\}\}/${file}}"
    temp_str="${temp_str//\{\{datetime\}\}/${datetime}}"
    # 最后替换 message，因为 message 可能包含诸如 {{xxx}} 这样的
    temp_str="${temp_str//\{\{message\}\}/${message}}"

    if [ "$is_patsub_replacement" -eq "$SHELL_TRUE" ]; then
        shopt -s patsub_replacement
    fi

    echo "${temp_str}"
    return "$SHELL_TRUE"
}

# ==================================== 下面是测试代码 ====================================

function TEST::log::formatter::format_message() {
    local message
    local temp_str

    # 测试格式
    message=$(log::formatter::format_message --formatter="{{level}} {{pid}} {{file}}:{{line}} {{function}} {{message}}" --level="info" --file="test.sh" --line="1" --function="function_name" "test message")
    utest::assert $?
    utest::assert_equal "$message" "info $$ test.sh:1 function_name test message"

    # 测试时间
    message=$(log::formatter::format_message --formatter="{{datetime}} {{message}}" --datetime-format="%Y" "test message")
    utest::assert $?
    utest::assert_equal "$message" "$(log::formatter::get_datetime_by_format "%Y") test message"

    # 测试特殊字符
    temp_str='123abcABC`~!@#$%^&*()-=_+\|[]{};:",.<>/?'
    temp_str+="'"
    message=$(log::formatter::format_message --formatter="{{level}} {{message}}" --level="info" "${temp_str}")
    utest::assert $?
    utest::assert_equal "$message" "info ${temp_str}"

    # 测试可变参数
    message=$(log::formatter::format_message --formatter="{{level}} {{message}}" --level="info" --message-format="%s|%s" "${temp_str}" "abcdefg")
    utest::assert $?
    utest::assert_equal "$message" "info ${temp_str}|abcdefg"
}

function TEST::log::formatter::all() {
    # source 进来的就不要测试了
    local parent_function_name
    parent_function_name=$(get_caller_function_name 2)
    if [ "$parent_function_name" = "source" ]; then
        return "$SHELL_TRUE"
    fi
    TEST::log::formatter::format_message || return "$SHELL_FALSE"
}

function log::formatter::_main() {
    log::formatter::_init || return "$SHELL_FALSE"

    if string::is_true "$TEST"; then
        TEST::log::formatter::all || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

log::formatter::_main
