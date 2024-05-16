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
source "${SCRIPT_DIR_6f82ee3f}/utest.sh"

# 解析 -x -x=aa --x --x=aa 的参数
# 参数解析成功，返回 true，输出 解析 的值
# 参数解析失败，返回 false
function parameter::parse_value() {
    local -n _5cb47da1_result="$1"
    local _aef4ba0f_option="$2"
    local _74871808_temp_str

    if [ -z "$_aef4ba0f_option" ]; then
        lerror "param(option) is empty"
        return "$SHELL_FALSE"
    fi

    # 参数需要以 - 开头，这里对有几个 - 不做限制
    if [[ "$_aef4ba0f_option" != -* ]]; then
        lerror "option($_aef4ba0f_option) format is invalid"
        return "$SHELL_FALSE"
    fi

    _74871808_temp_str="${_aef4ba0f_option#*=}"
    if [ "$_74871808_temp_str" == "$_aef4ba0f_option" ]; then
        # 没有找到 =，说明没有传值
        _5cb47da1_result=""
        return "$SHELL_TRUE"
    fi

    _5cb47da1_result="$_74871808_temp_str"

    return "$SHELL_TRUE"
}

function parameter::parse_string() {

    # 关键字参数
    local is_no_empty="$SHELL_FALSE"
    local min_length=0
    local max_length
    local default_value

    local _226eba81_temp_str
    local next_params=()
    local is_parse_self="$SHELL_TRUE"

    local param
    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            next_params+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        --no-empty | --no-empty=*)
            parameter::parse_value is_no_empty "$param" || return "$SHELL_FALSE"
            if ! string::is_true_or_false "$is_no_empty"; then
                lerror "option(--no-empty) value($is_no_empty) format is invalid"
                return "$SHELL_FALSE"
            fi
            if [ -z "$is_no_empty" ] || string::is_true "$is_no_empty"; then
                is_no_empty="$SHELL_TRUE"
            else
                is_no_empty="$SHELL_FALSE"
            fi
            ;;
        --min=*)
            min_length="${param#*=}"
            if ! string::is_num "$min_length"; then
                lerror "option(--min) value($min_length) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --max=*)
            max_length="${param#*=}"
            if ! string::is_num "$max_length"; then
                lerror "option(--max) value($max_length) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --default=*)
            default_value="${param#*=}"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    # 位置参数
    local -n _b7f786d2_result="${next_params[0]}"
    local _939cc810_option="${next_params[1]}"

    if [ -z "$_939cc810_option" ]; then
        lerror "param(option) is empty"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min_length" ] && [ -n "$max_length" ] && [ "$min_length" -gt "$max_length" ]; then
        lerror "param min($min_length) gt max($max_length)"
        return "$SHELL_FALSE"
    fi

    parameter::parse_value _226eba81_temp_str "${_939cc810_option}" || return "$SHELL_FALSE"

    # 先赋值默认值
    if [ -z "$_226eba81_temp_str" ] && [ -n "$default_value" ]; then
        _226eba81_temp_str="$default_value"
    fi

    if [ "$is_no_empty" -eq "$SHELL_TRUE" ] && [ -z "${_226eba81_temp_str}" ]; then
        # 参数限定不能为空
        lerror --caller-level="1" "check option(${_939cc810_option}) string type failed, string limit no empty, current value is empty"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min_length" ] && [ "${#_226eba81_temp_str}" -lt "$min_length" ]; then
        lerror --caller-level="1" "check option(${_939cc810_option}) string type failed, value limit min length is $min_length, current value(${_226eba81_temp_str}) length is ${#_226eba81_temp_str}"
        return "$SHELL_FALSE"
    fi

    if [ -n "$max_length" ] && [ "${#_226eba81_temp_str}" -gt "$max_length" ]; then
        lerror --caller-level="1" "check option(${_939cc810_option}) string type failed, value limit max length is $max_length, current value(${_226eba81_temp_str}) length is ${#_226eba81_temp_str}"
        return "$SHELL_FALSE"
    fi

    _b7f786d2_result="$_226eba81_temp_str"

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
    local default_value

    local _a8926db1_temp_str
    local next_params=()
    local is_parse_self="$SHELL_TRUE"

    local param
    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            next_params+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        --default=*)
            default_value="${param#*=}"
            if ! string::is_true_or_false "$default_value"; then
                lerror "option(--default) value($default_value) format is invalid"
                return "$SHELL_FALSE"
            fi
            string::is_true "$default_value"
            default_value="$?"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    # 位置参数
    local -n _7aab068b_result="${next_params[0]}"
    _5589d0cd_option="${next_params[1]}"

    if [ -z "$_5589d0cd_option" ]; then
        lerror "param(option) is empty"
        return "$SHELL_FALSE"
    fi

    default_value=${default_value:-$SHELL_TRUE}

    parameter::parse_value _a8926db1_temp_str "$_5589d0cd_option" || return "$SHELL_FALSE"

    if [ -z "${_a8926db1_temp_str}" ] && [ -n "$default_value" ]; then
        _7aab068b_result="$default_value"
        return "$SHELL_TRUE"
    fi

    if ! string::is_true_or_false "$_a8926db1_temp_str"; then
        # 构造成父级函数打印的现象
        lerror --caller-level=1 "check option($_5589d0cd_option) boolean type failed, value($_a8926db1_temp_str) format is invalid"
        return "$SHELL_FALSE"
    fi

    string::is_true "$_a8926db1_temp_str"
    _7aab068b_result="$?"

    return "$SHELL_TRUE"
}

function parameter::parse_num() {

    # 关键字参数
    local min
    local max
    local default_value

    local _84cda4a4_temp_str
    local next_params=()
    local is_parse_self="$SHELL_TRUE"

    local param
    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            next_params+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        --min=*)
            min="${param#*=}"
            if ! string::is_num "$min"; then
                lerror "option(--min) value($min) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --max=*)
            max="${param#*=}"
            if ! string::is_num "$max"; then
                lerror "option(--max) value($max) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        --default=*)
            default_value="${param#*=}"
            if ! string::is_num "$default_value"; then
                lerror "option(--default) value($default_value) format is not number"
                return "$SHELL_FALSE"
            fi
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    # 位置参数
    local -n _875b0d67_result="${next_params[0]}"
    local _0988dc65_option="${next_params[1]}"

    if [ -z "$_0988dc65_option" ]; then
        lerror "param(option) is empty"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min" ] && [ -n "$max" ] && [ "$min" -gt "$max" ]; then
        lerror "param min($min) gt max($max)"
        return "$SHELL_FALSE"
    fi

    parameter::parse_value _84cda4a4_temp_str "${_0988dc65_option}" || return "$SHELL_FALSE"

    # 先赋值默认值
    if [ -z "$_84cda4a4_temp_str" ] && [ -n "$default_value" ]; then
        _84cda4a4_temp_str="$default_value"
    elif [ -z "$_84cda4a4_temp_str" ]; then
        # 没有赋值，也没有给默认值
        lerror --caller-level=1 "check option(${_0988dc65_option}) number type failed, value is empty and no default value"
        return "$SHELL_FALSE"
    fi

    if ! string::is_num "$_84cda4a4_temp_str"; then
        lerror "check option(${_0988dc65_option}) number type failed, value($_84cda4a4_temp_str) is not number"
        return "$SHELL_FALSE"
    fi

    if [ -n "$min" ] && [ "${_84cda4a4_temp_str}" -lt "$min" ]; then
        lerror --caller-level="1" "check option(${_0988dc65_option}) number type failed, value limit min value is $min, current value is ${_84cda4a4_temp_str}"
        return "$SHELL_FALSE"
    fi

    if [ -n "$max" ] && [ "${_84cda4a4_temp_str}" -gt "$max" ]; then
        lerror --caller-level="1" "check option(${_0988dc65_option}) number type failed, value limit max value is $max, current value is ${_84cda4a4_temp_str}"
        return "$SHELL_FALSE"
    fi

    _875b0d67_result="$_84cda4a4_temp_str"

    return "$SHELL_TRUE"
}

function parameter::_test_parse_value() {
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

function parameter::_test_parse_string() {
    local value

    value=""
    parameter::parse_string -- value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_string --no-empty -- value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_string --no-empty -- value "--abc=123"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --min=1 -- value "--abc=123"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --min=5 -- value "--abc=123"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_string --min=3 --max=3 -- value "--abc=123"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --default="123" -- value "--abc"
    utest::assert $?
    utest::assert_equal "$value" "123"

    value=""
    parameter::parse_string --default="123" -- value "--abc="
    utest::assert $?
    utest::assert_equal "$value" "123"
}

function parameter::_test_parse_bool() {
    local value

    value=""
    parameter::parse_bool -- value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool -- value "abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool -- value "-xx=abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool -- value "--xx=abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_bool --default=y -- value "-x"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool --default=1 -- value "--xx"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool --default=true -- value "-x="
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool --default=n -- value "--xx="
    utest::assert $?
    utest::assert_fail "$value"

    value=""
    parameter::parse_bool -- value "-x=1"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool -- value "-x=y"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool -- value "--xx=true"
    utest::assert $?
    utest::assert "$value"

    value=""
    parameter::parse_bool -- value "-x=0"
    utest::assert $?
    utest::assert_fail "$value"

    value=""
    parameter::parse_bool -- value "-x=n"
    utest::assert $?
    utest::assert_fail "$value"

    value=""
    parameter::parse_bool -- value "--xx=False"
    utest::assert $?
    utest::assert_fail "$value"

}

function parameter::_test_parse_num() {

    local value
    value=""
    parameter::parse_num -- value
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num -- value "abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num -- value "-xx"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num -- value "--xx=abc"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num --default=123 -- value "-x"
    utest::assert $?
    utest::assert_equal "$value" 123

    value=""
    parameter::parse_num --min=12 -- value "-x=12"
    utest::assert $?
    utest::assert_equal "$value" 12

    value=""
    parameter::parse_num --min=12 -- value "-x=11"
    utest::assert_fail $?
    utest::assert_equal "$value" ""

    value=""
    parameter::parse_num --max=10 -- value "-x=10"
    utest::assert $?
    utest::assert_equal "$value" 10

    value=""
    parameter::parse_num --max=12 -- value "-x=13"
    utest::assert_fail $?
    utest::assert_equal "$value" ""
}

function parameter::_test_all() {
    # source 进来的就不要测试了
    local parent_function_name
    parent_function_name=$(get_caller_function_name 1)
    if [ "$parent_function_name" = "source" ]; then
        return
    fi
    parameter::_test_parse_value
    parameter::_test_parse_bool
    parameter::_test_parse_string
    parameter::_test_parse_num
}

string::is_true "$TEST" && parameter::_test_all
true
