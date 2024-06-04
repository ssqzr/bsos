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
# shellcheck source=/dev/null
source "${SCRIPT_DIR_aa90c9d9}/level.sh" || exit 1

function log::formatter::default_datetime_format() {
    # 格式是 date 命令支持的格式
    echo '%Y-%m-%d %H:%M:%S'
}

function log::formatter::default_formatter() {
    echo "{{datetime}} {{level}} [{{pid}}] {{file|basename}}:{{line}} [{{function_name}}] {{message|trim}}"
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

function log::formatter::get_pid() {
    if [ -n "$BASHPID" ]; then
        echo "$BASHPID"
    else
        echo $$
    fi
    return "$SHELL_TRUE"
}

function log::formatter::variable::filter::justify() {
    local data="$1"
    shift
    local width="$1"
    shift
    local alignment="$1"

    local length
    local left_fill
    local right_fill
    local result

    length="$(string::length "$data")" || return "$SHELL_FALSE"
    if [ "$length" -ge "$width" ]; then
        echo "$data"
        return "$SHELL_TRUE"
    fi

    case "$alignment" in
    left)
        # printf '%-*s' "$width" "$data"
        left_fill=0
        ((right_fill = width - length))
        ;;
    right)
        # printf '%*s' "$width" "$data"
        right_fill=0
        ((left_fill = width - length))
        ;;
    center)
        ((left_fill = (width - length) / 2))
        ((right_fill = width - length - left_fill))
        ;;
    **)
        println_error --stream=stderr "unknown alignment: $alignment"
        return "$SHELL_FALSE"
        ;;
    esac

    result="$(printf "%${left_fill}s%s%${right_fill}s" "" "$data" "")" || return "$SHELL_FALSE"
    echo "$result"
    return "$SHELL_TRUE"
}

function log::formatter::variable::filter::trim() {
    local data="$1"
    shift
    string::trim "$data" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function log::formatter::variable::filter::to_upper() {
    local data="$1"
    shift
    echo "${data@U}"
    return "$SHELL_TRUE"
}

function log::formatter::variable::filter::to_lower() {
    local data="$1"
    shift
    echo "${data@L}"
    return "$SHELL_TRUE"
}

function log::formatter::variable::filter::basename() {
    local data="$1"
    shift
    basename "$data"
    return "$SHELL_TRUE"
}

# 运行 filter
# 参数说明
# 位置参数：
#       filter_info=FILTER_INFO           变量过滤器的元数据信息，使用 “ ” 分割，第一个元素是过滤器名，后面是参数
#       value=VALUE                       要替换的值
function log::formatter::variable::apply_filter() {
    local filter_info="$1"
    shift
    local value="$1"
    shift
    local filter_name
    local filter_params
    local filter_info_array=()
    local result

    filter_info="$(string::trim "$filter_info")" || return "$SHELL_FALSE"

    string::split_with filter_info_array "$filter_info" || return "$SHELL_FALSE"

    array::remove_empty filter_info_array || return "$SHELL_FALSE"

    if array::is_empty filter_info_array; then
        println_error --stream=stderr "filter is empty"
        return "$SHELL_FALSE"
    fi

    filter_name="${filter_info_array[0]}"
    filter_params=("${filter_info_array[@]:1}")
    if debug::function::is_not_exists "log::formatter::variable::filter::$filter_name"; then
        println_error --stream=stderr "unknown filter: $filter_name"
        return "$SHELL_FALSE"
    fi
    result="$("log::formatter::variable::filter::$filter_name" "${value}" "${filter_params[@]}")" || return "$SHELL_FALSE"

    echo "$result"
    return "$SHELL_TRUE"
}

# 变量应用所有的 filter
function log::formatter::variable::apply_filters() {
    local -n filters_info_fddbd86a="$1"
    shift
    local value_fddbd86a="$1"
    shift

    local item_fddbd86a
    local result_fddbd86a=""

    if array::is_empty "${!filters_info_fddbd86a}"; then
        echo "${value_fddbd86a}"
        return "$SHELL_TRUE"
    fi

    result_fddbd86a="${value_fddbd86a}"
    for item_fddbd86a in "${filters_info_fddbd86a[@]}"; do
        result_fddbd86a=$(log::formatter::variable::apply_filter "${item_fddbd86a}" "${result_fddbd86a}") || return "$SHELL_FALSE"
    done

    echo "${result_fddbd86a}"
    return "$SHELL_TRUE"
}

function log::formatter::find_next_variable() {
    local -n left_e3412fc9="$1"
    shift
    local -n right_e3412fc9="$1"
    shift
    local formatter_e3412fc9="$1"

    # println_error --stream=stderr "[test] formatter: $formatter_e3412fc9"

    left_e3412fc9=0
    right_e3412fc9=0
    local length_e3412fc9=${#formatter_e3412fc9}
    local is_start_found="$SHELL_FALSE"

    while [ "$left_e3412fc9" -le "$((length_e3412fc9 - 4))" ] && [ "$right_e3412fc9" -le "$((length_e3412fc9 - 2))" ]; do
        if [ "$is_start_found" -ne "$SHELL_TRUE" ]; then
            if [ "${formatter_e3412fc9:$left_e3412fc9:3}" == "{{{" ]; then
                # 需要找仅仅是 {{ 开头的
                ((left_e3412fc9 += 1))
                continue
            fi
            if [ "${formatter_e3412fc9:$left_e3412fc9:2}" != "{{" ]; then
                ((left_e3412fc9 += 1))
                continue
            fi
            ((right_e3412fc9 = left_e3412fc9 + 2))
            is_start_found="$SHELL_TRUE"
            continue
        fi
        # 开头找到了，继续找结尾
        if [ "${formatter_e3412fc9:$right_e3412fc9:2}" == "{{" ]; then
            # 再次发现了 {{ ，开头重新开始计算
            ((left_e3412fc9 = right_e3412fc9))
            is_start_found="$SHELL_FALSE"
            continue
        fi

        if [ "${formatter_e3412fc9:$right_e3412fc9:2}" == "}}" ]; then
            # 找到了结尾，返回
            ((right_e3412fc9 += 1))
            return "$SHELL_TRUE"
        fi
        ((right_e3412fc9 += 1))
    done

    left_e3412fc9=0
    right_e3412fc9=0
    return "$SHELL_FALSE"
}

# 参数说明
# 必选参数：
#     --level=LEVEL               日志级别
#     --file=FILE                 文件路径
#     --line=LINE                 行号
#     --function-name=FUNCTION    函数名
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

    local pid
    local param
    local message
    local temp_str
    local datetime
    local current=0
    local left=0
    local right=0
    local formatter_length=0
    local var_infos=()
    local var_name=""
    local result
    local is_parse_self="$SHELL_TRUE"

    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            message_params+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        --formatter=*)
            formatter="${param#*=}"
            ;;
        --level=*)
            # shellcheck disable=SC2034
            level="${param#*=}"
            ;;
        --datetime-format=*)
            datetime_format="${param#*=}"
            ;;
        --file=*)
            # shellcheck disable=SC2034
            file="${param#*=}"
            ;;
        --line=*)
            # shellcheck disable=SC2034
            line="${param#*=}"
            ;;
        --function-name=*)
            # shellcheck disable=SC2034
            function_name="${param#*=}"
            ;;
        --message-format=*)
            message_format="${param#*=}"
            ;;
        -*)
            println_error --stream=stderr "[$(debug::function::call_stack)] unknown option $param"
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
    # shellcheck disable=SC2034
    pid="$(log::formatter::get_pid)" || return "$SHELL_FALSE"
    level=$(log::level::level_name "${level}") || return "$SHELL_FALSE"

    datetime="$(log::formatter::get_datetime_by_format "$datetime_format")" || return "$SHELL_FALSE"

    # shellcheck disable=SC2059
    printf -v message "$message_format" "${message_params[@]}"

    formatter_length="$(string::length "$formatter")"
    result=""

    while [ "$current" -lt "$formatter_length" ]; do
        log::formatter::find_next_variable left right "${formatter:$current}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            # 没找到就将后面所有字符都直接添加到结果中
            result+="${formatter:$current}"
            break
        fi
        # NOTE: left right 是相对于 current 后面字符的偏移量，而不是相对于 formatter 的
        # println_error --stream=stderr "[test] find next variable: left=$left right=$right str=${formatter:$left:$((right - left + 1))}"
        # 找到，就开始替换
        result+="${formatter:$current:$left}"

        string::split_with var_infos "${formatter:$((current + left + 2)):$((right - left + 1 - 4))}" "|"
        if array::is_empty var_infos; then
            result+="${formatter:$((current + left)):$((right - left + 1))}"
            ((current += right + 1))
            continue
        fi

        array::map var_infos var_infos string::trim
        if string::is_empty "${var_infos[0]}"; then
            # 第一个是变量的名称
            result+="${formatter:$((current + left)):$((right - left + 1))}"
            ((current += right + 1))
            continue
        fi

        array::remove_empty var_infos

        var_name="${var_infos[0]}"
        var_infos=("${var_infos[@]:1}")
        case "$var_name" in
        level | pid | datetime | file | line | function_name | message)
            temp_str="$(log::formatter::variable::apply_filters var_infos "${!var_name}")"
            if [ $? -ne "$SHELL_TRUE" ]; then
                result+="${formatter:$((current + left)):$((right - left + 1))}"
                ((current += right + 1))
                continue
            fi

            result+="$temp_str"
            ((current += right + 1))
            continue
            ;;
        *)
            println_error --stream=stderr "unknown variable name: $var_name"
            return "$SHELL_FALSE"
            ;;
        esac

    done

    echo "${result}"
    return "$SHELL_TRUE"
}

# ==================================== 下面是测试代码 ====================================
function TEST::log::formatter::variable::filter::justify() {
    local res

    res=$(log::formatter::variable::filter::justify "abc" 5 left)
    utest::assert_equal "$res" "abc  "

    res=$(log::formatter::variable::filter::justify "abc" 5 right)
    utest::assert_equal "$res" "  abc"

    res=$(log::formatter::variable::filter::justify "abc" 9 center)
    utest::assert_equal "$res" "   abc   "

    res=$(log::formatter::variable::filter::justify "abc" 10 center)
    utest::assert_equal "$res" "   abc    "

    res=$(log::formatter::variable::filter::justify "abc" 1 center)
    utest::assert_equal "$res" "abc"

}

function TEST::log::formatter::variable::apply_filter::justify() {
    local res

    res=$(log::formatter::variable::apply_filter "" "  abc  " 2>/dev/null)
    utest::assert_fail $?

    res=$(log::formatter::variable::apply_filter "justify 5 left" "abc")
    utest::assert $?
    utest::assert_equal "$res" "abc  "

    res=$(log::formatter::variable::apply_filter "   justify  5   right   " "abc")
    utest::assert $?
    utest::assert_equal "$res" "  abc"

    res=$(log::formatter::variable::apply_filter "   justify  2   right   " "abc")
    utest::assert $?
    utest::assert_equal "$res" "abc"
}

function TEST::log::formatter::variable::apply_filter::trim() {
    local res

    res=$(log::formatter::variable::apply_filter "" "  abc  " 2>/dev/null)
    utest::assert_fail $?

    res=$(log::formatter::variable::apply_filter "trim" "  abc  ")
    utest::assert $?
    utest::assert_equal "$res" "abc"

    res=$(log::formatter::variable::apply_filter "   trim    " "  abc  ")
    utest::assert $?
    utest::assert_equal "$res" "abc"
}

function TEST::log::formatter::variable::apply_filter::basename() {
    local res

    res=$(log::formatter::variable::apply_filter "" "  abc  " 2>/dev/null)
    utest::assert_fail $?

    res=$(log::formatter::variable::apply_filter "basename" "/a/b/c/d")
    utest::assert $?
    utest::assert_equal "$res" "d"

    res=$(log::formatter::variable::apply_filter "basename" "/a/b/c/d.txt")
    utest::assert $?
    utest::assert_equal "$res" "d.txt"

    res=$(log::formatter::variable::apply_filter "basename" "abc.xxx")
    utest::assert $?
    utest::assert_equal "$res" "abc.xxx"

    res=$(log::formatter::variable::apply_filter "basename" "/")
    utest::assert $?
    utest::assert_equal "$res" "/"
}

function TEST::log::formatter::variable::apply_filters() {
    local filters_info=()
    local res

    res="$(log::formatter::variable::apply_filters filters_info "  abc  ")"
    utest::assert $?
    utest::assert_equal "$res" "  abc  "

    filters_info=("trim")
    res="$(log::formatter::variable::apply_filters filters_info "  abc  ")"
    utest::assert $?
    utest::assert_equal "$res" "abc"

    filters_info=("trim" "justify 5 left")
    res="$(log::formatter::variable::apply_filters filters_info "  abc  ")"
    utest::assert $?
    utest::assert_equal "$res" "abc  "

    filters_info=("justify 5 left" "trim")
    res="$(log::formatter::variable::apply_filters filters_info "  abc  ")"
    utest::assert $?
    utest::assert_equal "$res" "abc"

    # 仅仅为了规避 shellcheck 未使用变量的告警
    echo "${filters_info[*]}" >/dev/null
}

function TEST::log::formatter::find_next_variable::not_found() {
    local left=0
    local right=0

    log::formatter::find_next_variable left right ""
    utest::assert_fail $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 0

    log::formatter::find_next_variable left right "{}"
    utest::assert_fail $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 0

    log::formatter::find_next_variable left right "{{}"
    utest::assert_fail $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 0

    log::formatter::find_next_variable left right "{}}"
    utest::assert_fail $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 0

    log::formatter::find_next_variable left right "{{{}"
    utest::assert_fail $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 0

    log::formatter::find_next_variable left right "{{{{"
    utest::assert_fail $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 0
}

function TEST::log::formatter::find_next_variable::found() {
    local left=0
    local right=0

    log::formatter::find_next_variable left right "{{}}"
    utest::assert $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 3

    left=0
    right=0
    log::formatter::find_next_variable left right "{{{}}}"
    utest::assert $?
    utest::assert_equal "$left" 1
    utest::assert_equal "$right" 4

    left=0
    right=0
    log::formatter::find_next_variable left right "{{{}}"
    utest::assert $?
    utest::assert_equal "$left" 1
    utest::assert_equal "$right" 4

    left=0
    right=0
    log::formatter::find_next_variable left right "{{}}}"
    utest::assert $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 3

    left=0
    right=0
    log::formatter::find_next_variable left right "{{xxx}}"
    utest::assert $?
    utest::assert_equal "$left" 0
    utest::assert_equal "$right" 6

    left=0
    right=0
    log::formatter::find_next_variable left right "abc {{xxx}}"
    utest::assert $?
    utest::assert_equal "$left" 4
    utest::assert_equal "$right" 10

    left=0
    right=0
    log::formatter::find_next_variable left right "abc {{xxx}}} def"
    utest::assert $?
    utest::assert_equal "$left" 4
    utest::assert_equal "$right" 10

    left=0
    right=0
    log::formatter::find_next_variable left right "abc {{xxx}} def}}"
    utest::assert $?
    utest::assert_equal "$left" 4
    utest::assert_equal "$right" 10
}

function TEST::log::formatter::format_message() {
    local message
    local temp_str

    # 测试格式
    message=$(log::formatter::format_message --formatter="{{level}} {{file}}:{{line}} {{function_name}} {{message}}" --level="$LOG_LEVEL_INFO" --file="test.sh" --line="1" --function-name="function_name" "test message")
    utest::assert $?
    utest::assert_equal "$message" "info test.sh:1 function_name test message"

    # 测试时间
    message=$(log::formatter::format_message --level="$LOG_LEVEL_INFO" --formatter="{{datetime}} {{level}} {{message}}" --datetime-format="%Y" "test message")
    utest::assert $?
    utest::assert_equal "$message" "$(log::formatter::get_datetime_by_format "%Y") info test message"

    # 测试特殊字符
    temp_str='123abcABC`~!@#$%^&*()-=_+\|[]{};:",.<>/?'
    temp_str+="'"
    message=$(log::formatter::format_message --formatter="{{level}} {{message}}" --level="$LOG_LEVEL_INFO" "${temp_str}")
    utest::assert $?
    utest::assert_equal "$message" "info ${temp_str}"

    # 测试可变参数
    message=$(log::formatter::format_message --formatter="{{level}} {{message}}" --level="$LOG_LEVEL_INFO" --message-format="%s|%s" "${temp_str}" "abcdefg")
    utest::assert $?
    utest::assert_equal "$message" "info ${temp_str}|abcdefg"

    # 测试 message 字符串以 -- 开头
    message=$(log::formatter::format_message --formatter="{{level}} {{message}}" --level="$LOG_LEVEL_INFO" -- "--abcdefg")
    utest::assert $?
    utest::assert_equal "$message" "info --abcdefg"

    message=$(log::formatter::format_message --formatter="{{level}} {{message}}" --level="$LOG_LEVEL_INFO" -- "--abcdefg" "--" "--12345")
    utest::assert $?
    utest::assert_equal "$message" "info --abcdefg----12345"
}

function TEST::log::formatter::format_message::justify_filter() {
    local message
    local temp_str

    message=$(log::formatter::format_message --formatter="{{level|justify 10 left}} {{file}}:{{line}} {{function_name}} {{message}}" --level="$LOG_LEVEL_INFO" --file="test.sh" --line="1" --function-name="function_name" "test message")
    utest::assert $?
    utest::assert_equal "$message" "info       test.sh:1 function_name test message"

    message=$(log::formatter::format_message --formatter="{{level|justify 10 right}} {{file}}:{{line}} {{function_name}} {{message}}" --level="$LOG_LEVEL_INFO" --file="test.sh" --line="1" --function-name="function_name" "test message")
    utest::assert $?
    utest::assert_equal "$message" "      info test.sh:1 function_name test message"
}

function TEST::log::formatter::format_message::trim_filter() {
    local message
    local temp_str

    message=$(log::formatter::format_message --formatter="{{level}} {{file}}:{{line}} {{function_name}} {{message  |   trim}}" --level="$LOG_LEVEL_INFO" --file="test.sh" --line="1" --function-name="function_name" "    test message  ")
    utest::assert $?
    utest::assert_equal "$message" "info test.sh:1 function_name test message"
}

function log::formatter::_main() {
    log::formatter::_init || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

log::formatter::_main
