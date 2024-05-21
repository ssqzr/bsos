#!/bin/bash

if [ -n "${SCRIPT_DIR_6f82ee3f}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_6f82ee3f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_6f82ee3f}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6f82ee3f}/debug.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6f82ee3f}/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6f82ee3f}/string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6f82ee3f}/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6f82ee3f}/utest.sh"

# 解析 -x -x=aa --x --x=aa 的参数
# 参数解析成功，返回 true，输出 解析 的值
# 参数解析失败，返回 false
function parameter::parse_value() {
    local -n result_5cb47da1="$1"
    local option_5cb47da1="$2"
    local temp_str_5cb47da1

    if [ -z "$option_5cb47da1" ]; then
        lerror "param(option) is empty"
        return "$SHELL_FALSE"
    fi

    # 参数需要以 - 开头，这里对有几个 - 不做限制
    if [[ "$option_5cb47da1" != -* ]]; then
        lerror "option($option_5cb47da1) format is invalid"
        return "$SHELL_FALSE"
    fi

    temp_str_5cb47da1="${option_5cb47da1#*=}"
    if [ "$temp_str_5cb47da1" == "$option_5cb47da1" ]; then
        # 没有找到 =，说明没有传值
        result_5cb47da1=""
        return "$SHELL_TRUE"
    fi

    # shellcheck disable=SC2034
    result_5cb47da1="$temp_str_5cb47da1"

    return "$SHELL_TRUE"
}

function parameter::parse_string() {
    # 关键字参数
    local -n result_b7f786d2
    local is_no_empty_b7f786d2="$SHELL_FALSE"
    local min_length_b7f786d2
    local max_length_b7f786d2
    local default_b7f786d2
    local option_b7f786d2

    local temp_str_b7f786d2

    local param_b7f786d2
    for param_b7f786d2 in "$@"; do
        case "$param_b7f786d2" in
        --no-empty | --no-empty=*)
            parameter::parse_value is_no_empty_b7f786d2 "$param_b7f786d2" || return "$SHELL_FALSE"
            if string::is_not_empty "$is_no_empty_b7f786d2" && string::is_not_bool "$is_no_empty_b7f786d2"; then
                lerror --caller-frame="1" "option(--no-empty) value($is_no_empty_b7f786d2) format is invalid"
                return "$SHELL_FALSE"
            fi
            if [ -z "$is_no_empty_b7f786d2" ] || string::is_true "$is_no_empty_b7f786d2"; then
                is_no_empty_b7f786d2="$SHELL_TRUE"
            else
                is_no_empty_b7f786d2="$SHELL_FALSE"
            fi
            ;;
        --min=*)
            min_length_b7f786d2="${param_b7f786d2#*=}"
            if ! string::is_num "$min_length_b7f786d2"; then
                lerror --caller-frame="1" "option(--min) value($min_length_b7f786d2) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --max=*)
            max_length_b7f786d2="${param_b7f786d2#*=}"
            if ! string::is_num "$max_length_b7f786d2"; then
                lerror --caller-frame="1" "option(--max) value($max_length_b7f786d2) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --default=*)
            default_b7f786d2="${param_b7f786d2#*=}"
            ;;
        --option=*)
            option_b7f786d2="${param_b7f786d2#*=}"
            ;;
        -*)
            lerror "unknown option $param_b7f786d2"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -R result_b7f786d2 ]; then
                result_b7f786d2="$param_b7f786d2"
                continue
            fi
            lerror --caller-frame="1" "unknown parameter $param_b7f786d2"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -R result_b7f786d2 ]; then
        lerror --caller-frame="1" "param(result-ref) is not set"
        return "$SHELL_FALSE"
    fi

    if [ ! -v option_b7f786d2 ]; then
        lerror --caller-frame="1" "param(--option) is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$option_b7f786d2" ]; then
        lerror --caller-frame="1" "param(--option) is empty"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min_length_b7f786d2" ] && [ -n "$max_length_b7f786d2" ] && [ "$min_length_b7f786d2" -gt "$max_length_b7f786d2" ]; then
        lerror --caller-frame="1" "param min($min_length_b7f786d2) gt max($max_length_b7f786d2)"
        return "$SHELL_FALSE"
    fi

    parameter::parse_value temp_str_b7f786d2 "${option_b7f786d2}" || return "$SHELL_FALSE"

    # 先赋值默认值
    if [ -z "$temp_str_b7f786d2" ] && [ -n "$default_b7f786d2" ]; then
        temp_str_b7f786d2="$default_b7f786d2"
    fi

    if [ "$is_no_empty_b7f786d2" -eq "$SHELL_TRUE" ] && [ -z "${temp_str_b7f786d2}" ]; then
        # 参数限定不能为空
        lerror --caller-frame="1" "check option(${option_b7f786d2}) string type failed, string limit no empty, current value is empty"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min_length_b7f786d2" ] && [ "$(string::length "${temp_str_b7f786d2}")" -lt "$min_length_b7f786d2" ]; then
        lerror --caller-frame="1" "check option(${option_b7f786d2}) string type failed, value limit min length is $min_length_b7f786d2, current value(${temp_str_b7f786d2}) length is $(string::length "${temp_str_b7f786d2}")"
        return "$SHELL_FALSE"
    fi

    if [ -n "$max_length_b7f786d2" ] && [ "$(string::length "${temp_str_b7f786d2}")" -gt "$max_length_b7f786d2" ]; then
        lerror --caller-frame="1" "check option(${option_b7f786d2}) string type failed, value limit max length is $max_length_b7f786d2, current value(${temp_str_b7f786d2}) length is $(string::length "${temp_str_b7f786d2}")"
        return "$SHELL_FALSE"
    fi

    result_b7f786d2="$temp_str_b7f786d2"

    return "$SHELL_TRUE"
}

# 解析 -x -x=aa --x --x=aa 的参数
# 参数解析成功，返回 true，输出 bool 的值
# 参数解析失败，返回 false
# NOTE:
# 1. 字符串 0 和 1 并不对应 shell 里的 true 和 false，字符串 0 解析为 false，字符串 1 解析为 true
# 2. 不建议使用字符串 0 和 1 做为参数值
# 3. 空字符串解析为 true
function parameter::parse_bool() {
    # 关键字参数
    local -n result_7aab068b
    local default_7aab068b
    local option_7aab068b

    local temp_str_7aab068b

    local param_7aab068b
    for param_7aab068b in "$@"; do
        case "$param_7aab068b" in
        --default=*)
            default_7aab068b="${param_7aab068b#*=}"
            if string::is_not_bool "$default_7aab068b"; then
                lerror --caller-frame="1" "option(--default) value($default_7aab068b) format is invalid"
                return "$SHELL_FALSE"
            fi
            string::is_true "$default_7aab068b"
            default_7aab068b="$?"
            ;;
        --option=*)
            option_7aab068b="${param_7aab068b#*=}"
            ;;
        -*)
            lerror "unknown option $param_7aab068b"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -R result_7aab068b ]; then
                result_7aab068b="$param_7aab068b"
                continue
            fi
            lerror --caller-frame="1" "unknown parameter $param_7aab068b"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -R result_7aab068b ]; then
        lerror --caller-frame="1" "param(result-ref) is not set"
        return "$SHELL_FALSE"
    fi

    if [ ! -v option_7aab068b ]; then
        lerror --caller-frame="1" "param(--option) is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$option_7aab068b" ]; then
        lerror --caller-frame="1" "param(--option) is empty"
        return "$SHELL_FALSE"
    fi

    default_7aab068b=${default_7aab068b:-$SHELL_TRUE}

    parameter::parse_value temp_str_7aab068b "$option_7aab068b" || return "$SHELL_FALSE"

    if [ -z "${temp_str_7aab068b}" ] && [ -n "$default_7aab068b" ]; then
        result_7aab068b="$default_7aab068b"
        return "$SHELL_TRUE"
    fi

    if string::is_not_bool "$temp_str_7aab068b"; then
        # 构造成父级函数打印的现象
        lerror --caller-frame="1" "check option($option_7aab068b) boolean type failed, value($temp_str_7aab068b) format is invalid"
        return "$SHELL_FALSE"
    fi

    string::is_true "$temp_str_7aab068b"
    result_7aab068b="$?"

    return "$SHELL_TRUE"
}

function parameter::parse_num() {

    # 关键字参数
    local -n result_875b0d67
    local min_875b0d67
    local max_875b0d67
    local default_875b0d67
    local option_875b0d67

    local temp_str_875b0d67

    local param_875b0d67
    for param_875b0d67 in "$@"; do
        case "$param_875b0d67" in
        --min=*)
            min_875b0d67="${param_875b0d67#*=}"
            if ! string::is_num "$min_875b0d67"; then
                lerror --caller-frame="1" "option(--min) value($min_875b0d67) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --max=*)
            max_875b0d67="${param_875b0d67#*=}"
            if ! string::is_num "$max_875b0d67"; then
                lerror --caller-frame="1" "option(--max) value($max_875b0d67) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --default=*)
            default_875b0d67="${param_875b0d67#*=}"
            if ! string::is_num "$default_875b0d67"; then
                lerror --caller-frame="1" "option(--default) value($default_875b0d67) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --option=*)
            option_875b0d67="${param_875b0d67#*=}"
            ;;
        -*)
            lerror "unknown option $param_875b0d67"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -R result_875b0d67 ]; then
                result_875b0d67="$param_875b0d67"
                continue
            fi
            lerror --caller-frame="1" "unknown parameter $param_875b0d67"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -R result_875b0d67 ]; then
        lerror --caller-frame="1" "param(result-ref) is not set"
        return "$SHELL_FALSE"
    fi

    if [ ! -v option_875b0d67 ]; then
        lerror --caller-frame="1" "param(--option) is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$option_875b0d67" ]; then
        lerror --caller-frame="1" "param(option) is empty"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min_875b0d67" ] && [ -n "$max_875b0d67" ] && [ "$min_875b0d67" -gt "$max_875b0d67" ]; then
        lerror --caller-frame="1" "param min($min_875b0d67) gt max($max_875b0d67)"
        return "$SHELL_FALSE"
    fi

    parameter::parse_value temp_str_875b0d67 "${option_875b0d67}" || return "$SHELL_FALSE"

    # 先赋值默认值
    if [ -z "$temp_str_875b0d67" ] && [ -n "$default_875b0d67" ]; then
        temp_str_875b0d67="$default_875b0d67"
    elif [ -z "$temp_str_875b0d67" ]; then
        # 没有赋值，也没有给默认值
        lerror --caller-frame="1" "check option(${option_875b0d67}) number type failed, value is empty and no default value"
        return "$SHELL_FALSE"
    fi

    if ! string::is_num "$temp_str_875b0d67"; then
        lerror --caller-frame="1" "check option(${option_875b0d67}) number type failed, value($temp_str_875b0d67) is not number"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min_875b0d67" ] && [ "${temp_str_875b0d67}" -lt "$min_875b0d67" ]; then
        lerror --caller-frame="1" "check option(${option_875b0d67}) number type failed, value limit min value is $min_875b0d67, current value is ${temp_str_875b0d67}"
        return "$SHELL_FALSE"
    fi

    if [ -n "$max_875b0d67" ] && [ "${temp_str_875b0d67}" -gt "$max_875b0d67" ]; then
        lerror --caller-frame="1" "check option(${option_875b0d67}) number type failed, value limit max value is $max_875b0d67, current value is ${temp_str_875b0d67}"
        return "$SHELL_FALSE"
    fi

    result_875b0d67="$temp_str_875b0d67"

    return "$SHELL_TRUE"
}

function parameter::parse_array() {
    # 关键字参数
    local -n result_46d69f2e
    local option_46d69f2e
    local separator_46d69f2e
    local temp_str_46d69f2e
    # shellcheck disable=SC2034
    local temp_array_46d69f2e

    local param_46d69f2e
    for param_46d69f2e in "$@"; do
        case "$param_46d69f2e" in
        --separator=*)
            separator_46d69f2e="${param_46d69f2e#*=}"
            ;;
        --option=*)
            option_46d69f2e="${param_46d69f2e#*=}"
            ;;
        -*)
            lerror "unknown option $param_46d69f2e"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -R result_46d69f2e ]; then
                result_46d69f2e="$param_46d69f2e"
                continue
            fi
            lerror --caller-frame="1" "unknown parameter $param_46d69f2e"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -R result_46d69f2e ]; then
        lerror --caller-frame="1" "param(result-ref) is not set"
        return "$SHELL_FALSE"
    fi

    if [ ! -v option_46d69f2e ]; then
        lerror --caller-frame="1" "param(--option) is not set"
        return "$SHELL_FALSE"
    fi

    string::default separator_46d69f2e "," || return "$SHELL_FALSE"

    parameter::parse_value temp_str_46d69f2e "${option_46d69f2e}" || return "$SHELL_FALSE"

    if [ -z "$temp_str_46d69f2e" ]; then
        ldebug "param(${option_46d69f2e}) value is empty"
        return "$SHELL_TRUE"
    fi

    string::split_with temp_array_46d69f2e "$temp_str_46d69f2e" "$separator_46d69f2e" || return "$SHELL_FALSE"

    array::extend "${!result_46d69f2e}" temp_array_46d69f2e || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# ==================================== 下面是测试代码 ====================================

function TEST::parameter::parse_value() {
    local value

    parameter::parse_value value
    utest::assert_fail $?

    parameter::parse_value value "xx"
    utest::assert_fail $?
    parameter::parse_value value "xx=abc"
    utest::assert_fail $?

    parameter::parse_value value "-x"
    utest::assert $?
    utest::assert_equal "$value" ""

    parameter::parse_value value "-xxx"
    utest::assert $?
    utest::assert_equal "$value" ""

    parameter::parse_value value "-x="
    utest::assert $?
    utest::assert_equal "$value" ""

    parameter::parse_value value "-xxx="
    utest::assert $?
    utest::assert_equal "$value" ""

    parameter::parse_value value "-xx=abc"
    utest::assert $?
    utest::assert_equal "$value" "abc"

    parameter::parse_value value "--xx="
    utest::assert $?
    utest::assert_equal "$value" ""

    parameter::parse_value value "--xx=abc"
    utest::assert $?
    utest::assert_equal "$value" "abc"

}

function TEST::parameter::parse_string() {
    local value

    value=""
    parameter::parse_string value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_string --no-empty value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_string --no-empty value --option="--abc=123"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --min=1 value --option="--abc=123"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --min=5 value --option="--abc=123"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_string --min=3 --max=3 value --option="--abc=123"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --default="123" value --option="--abc"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --default="123" value --option="--abc="
    utest::assert $?
    utest::assert_equal "$value" "123"
}

function TEST::parameter::parse_bool() {
    local value

    value=""
    parameter::parse_bool value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool value --option="abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool value --option="-xx=abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool value --option="--xx=abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool --default=y value --option="-x"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool --default=1 value --option="--xx"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool --default=true value --option="-x="
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool --default=n value --option="--xx="
    utest::assert $?
    utest::assert_fail "$value"

    value=""
    parameter::parse_bool value --option="-x=1"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool value --option="-x=y"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool value --option="--xx=true"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool value --option="-x=0"
    utest::assert $?
    utest::assert_fail "$value"

    value=""
    parameter::parse_bool value --option="-x=n"
    utest::assert $?
    utest::assert_fail "$value"

    value=""
    parameter::parse_bool value --option="--xx=False"
    utest::assert $?
    utest::assert_fail "$value"

}

function TEST::parameter::parse_num() {

    local value
    value=""
    parameter::parse_num value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num value --option="abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num value --option="-xx"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num value --option="--xx=abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num --default=123 value --option="-x"
    utest::assert $?
    utest::assert_equal "$value" 123

    value=""
    parameter::parse_num --min=12 value --option="-x=12"
    utest::assert $?
    utest::assert_equal "$value" 12

    value=""
    parameter::parse_num --min=12 value --option="-x=11"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num --max=10 value --option="-x=10"
    utest::assert $?
    utest::assert_equal "$value" 10

    value=""
    parameter::parse_num --max=12 value --option="-x=13"
    utest::assert_fail $?
    utest::assert_equal "$value" ""
}

function TEST::parameter::parse_array() {
    local arr

    parameter::parse_array arr --option=""
    utest::assert_fail $?

    parameter::parse_array arr --option="-x="
    utest::assert $?
    array::is_empty arr
    utest::assert $?

    parameter::parse_array arr --option="-x=a"
    utest::assert $?
    utest::assert_equal "${arr[*]}" "a"

    parameter::parse_array arr --option="-x=b"
    utest::assert $?
    utest::assert_equal "${arr[*]}" "a b"

    parameter::parse_array arr --option="-x=1,2"
    utest::assert $?
    utest::assert_equal "${arr[*]}" "a b 1 2"

}

function TEST::parameter::all() {
    # source 进来的就不要测试了
    local parent_function_name
    parent_function_name=$(get_caller_function_name 1)
    if [ "$parent_function_name" = "source" ]; then
        return
    fi
    TEST::parameter::parse_value || return "$SHELL_FALSE"
    TEST::parameter::parse_bool || return "$SHELL_FALSE"
    TEST::parameter::parse_string || return "$SHELL_FALSE"
    TEST::parameter::parse_num || return "$SHELL_FALSE"
    TEST::parameter::parse_array || return "$SHELL_FALSE"
}

string::is_true "$TEST" && TEST::parameter::all
true
