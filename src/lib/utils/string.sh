#!/bin/bash

# 字符串操作相关的工具

if [ -n "${SCRIPT_DIR_c5f5ae0d}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_c5f5ae0d="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_c5f5ae0d}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_c5f5ae0d}/debug.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_c5f5ae0d}/utest.sh"

function string::random() {
    echo "${RANDOM}"
}

function string::gen_random() {
    local prefix="$1"
    local random="$2"
    local suffix="$2"
    local now
    local data

    now="$(date '+%Y-%m-%d-%H-%M-%S.%N')"
    if [ -z "${random}" ]; then
        random="$(string::random)"
    fi

    if [ -n "${prefix}" ]; then
        data+="${prefix}-"
    fi

    data+="${now}-${random}"

    if [ -n "${suffix}" ]; then
        data+="-${suffix}"
    fi
    echo "$data"
}

function string::is_empty() {
    local data="$1"
    if [ -z "$data" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function string::is_not_empty() {
    local data="$1"
    string::is_empty "$data" && return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function string::length() {
    local data="$1"
    echo "${#data}"
}

function string::default() {
    local -n data_5c1d20cc="$1"
    local default_5c1d20cc="$2"
    if string::is_empty "$data_5c1d20cc"; then
        data_5c1d20cc="$default_5c1d20cc"
    fi
    return "$SHELL_TRUE"
}

# 去掉字符串两边的空格
function string::trim() {
    local str="$1"
    echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function string::is_bool() {
    local data="$1"

    data=$(string::trim "$data")

    # 空字符串认为是 false
    if string::is_empty "$data"; then
        return "$SHELL_FALSE"
    fi

    echo "$data" | grep -q -i -E "^[01yn]$|^yes$|^no$|^true$|^false$"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function string::is_not_bool() {
    string::is_bool "$1" && return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 这个函数只能判断字符串是否是 true ，反向不能判断是否为 false
function string::is_true() {
    local data="$1"

    data=$(string::trim "$data")

    echo "$data" | grep -q -i -E "^[1y]$|^yes$|^true$"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

# 这个函数只能判断字符串是否是 false ，反向不能判断是否为 true
function string::is_false() {
    local data="$1"

    data=$(string::trim "$data")

    echo "$data" | grep -q -i -E "^[0n]$|^no$|^false$"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function string::print_yes_no() {
    local boolean="$1"

    if [ -z "$boolean" ]; then
        printf "no"
        return
    fi

    if [ "$boolean" -eq "$SHELL_TRUE" ]; then
        printf "yes"
        return
    fi
    printf "no"
}

function string::is_num() {
    local data="$1"
    echo "$data" | grep -q -E "^[0-9]+$"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function string::split_with() {
    local -n array_5c9e7642="$1"
    local data_5c9e7642="$2"
    local separator_5c9e7642="${3:- }"

    local temp_str_5c9e7642

    if [ -z "${data_5c9e7642}" ]; then
        array_5c9e7642=()
        return "$SHELL_TRUE"
    fi

    # shellcheck disable=SC2001
    temp_str_5c9e7642=$(echo "$data_5c9e7642" | sed -e "s/$separator_5c9e7642/\n/g") || return "$SHELL_FALSE"
    readarray -t "${!array_5c9e7642}" < <(echo "$temp_str_5c9e7642")

    return "$SHELL_TRUE"
}

######################################### 下面是单元测试代码 #########################################

function TEST::string::is_empty() {
    string::is_empty
    utest::assert $?

    string::is_empty ""
    utest::assert $?

    string::is_empty " "
    utest::assert_fail $?

    string::is_empty "0"
    utest::assert_fail $?

    string::is_empty "1"
    utest::assert_fail $?
}

function TEST::string::is_not_empty() {
    string::is_not_empty
    utest::assert_fail $?

    string::is_not_empty ""
    utest::assert_fail $?

    string::is_not_empty " "
    utest::assert $?

    string::is_not_empty "0"
    utest::assert $?

    string::is_not_empty "1"
    utest::assert $?
}

function TEST::string::length() {
    utest::assert_equal "$(string::length "")" 0

    utest::assert_equal "$(string::length " ")" 1

    utest::assert_equal "$(string::length "abc")" 3

}

function TEST::string::default() {
    local str

    string::default str
    utest::assert_equal "$str" ""

    str=""
    string::default str "abc"
    utest::assert_equal "$str" "abc"

    str=" "
    string::default str "abc"
    utest::assert_equal "$str" " "

    str="123"
    string::default str "abc"
    utest::assert_equal "$str" "123"

}

function TEST::string::is_bool() {
    string::is_bool ""
    utest::assert_fail $?

    string::is_bool "0"
    utest::assert $?

    string::is_bool "1"
    utest::assert $?

    string::is_bool "y"
    utest::assert $?

    string::is_bool "Y"
    utest::assert $?

    string::is_bool "N"
    utest::assert $?

    string::is_bool "y"
    utest::assert $?

    string::is_bool "yes"
    utest::assert $?

    string::is_bool "yEs"
    utest::assert $?

    string::is_bool "YEs"
    utest::assert $?

    string::is_bool "YES"
    utest::assert $?

    string::is_bool "no"
    utest::assert $?

    string::is_bool "No"
    utest::assert $?

    string::is_bool "nO"
    utest::assert $?

    string::is_bool "NO"
    utest::assert $?

    string::is_bool "true"
    utest::assert $?

    string::is_bool "True"
    utest::assert $?

    string::is_bool "tRue"
    utest::assert $?

    string::is_bool "truE"
    utest::assert $?

    string::is_bool "tRUe"
    utest::assert $?

    string::is_bool "TRuE"
    utest::assert $?

    string::is_bool "TRUE"
    utest::assert $?

    string::is_bool "false"
    utest::assert $?

    string::is_bool "False"
    utest::assert $?

    string::is_bool "fAlse"
    utest::assert $?

    string::is_bool "falsE"
    utest::assert $?

    string::is_bool "FAlse"
    utest::assert $?

    string::is_bool "faLSe"
    utest::assert $?

    string::is_bool "fAlsE"
    utest::assert $?

    string::is_bool "FALse"
    utest::assert $?

    string::is_bool "fALSe"
    utest::assert $?

    string::is_bool "fALsE"
    utest::assert $?

    string::is_bool "FALSe"
    utest::assert $?

    string::is_bool "fALSE"
    utest::assert $?

    string::is_bool "FALSE"
    utest::assert $?

    string::is_bool "00"
    utest::assert_fail $?

    string::is_bool "11"
    utest::assert_fail $?

    string::is_bool "01"
    utest::assert_fail $?

    string::is_bool "yy"
    utest::assert_fail $?

    string::is_bool "nn"
    utest::assert_fail $?

    string::is_bool "yn"
    utest::assert_fail $?

    string::is_bool "ye"
    utest::assert_fail $?

    string::is_bool "yess"
    utest::assert_fail $?

    string::is_bool "noo"
    utest::assert_fail $?

    string::is_bool "tru"
    utest::assert_fail $?

    string::is_bool "truee"
    utest::assert_fail $?

    string::is_bool "fals"
    utest::assert_fail $?

    string::is_bool "ffalse"
    utest::assert_fail $?

    string::is_bool "xxxxx"
    utest::assert_fail $?

}

function TEST::string::is_not_bool() {
    string::is_not_bool ""
    utest::assert $?

    string::is_not_bool "0"
    utest::assert_fail $?

    string::is_not_bool "1"
    utest::assert_fail $?

    string::is_not_bool "xxxx"
    utest::assert $?
}

function TEST::string::is_true() {
    string::is_true ""
    utest::assert_fail $?

    string::is_true "0"
    utest::assert_fail $?

    string::is_true "1"
    utest::assert $?

    string::is_true "y"
    utest::assert $?

    string::is_true "Y"
    utest::assert $?

    string::is_true "n"
    utest::assert_fail $?

    string::is_true "N"
    utest::assert_fail $?

    string::is_true "yes"
    utest::assert $?

    string::is_true "no"
    utest::assert_fail $?

    string::is_true "true"
    utest::assert $?

    string::is_true "True"
    utest::assert $?

    string::is_true "TrUe"
    utest::assert $?

    string::is_true "TRuE"
    utest::assert $?

    string::is_true "TRUE"
    utest::assert $?

    string::is_true "false"
    utest::assert_fail $?

    string::is_true "False"
    utest::assert_fail $?

    string::is_true "FalSe"
    utest::assert_fail $?

    string::is_true "FaLSe"
    utest::assert_fail $?

    string::is_true "FALSE"
    utest::assert_fail $?
}

function TEST::string::is_false() {
    string::is_false ""
    utest::assert_fail $?

    string::is_false "0"
    utest::assert $?

    string::is_false "1"
    utest::assert_fail $?

    string::is_false "y"
    utest::assert_fail $?

    string::is_false "Y"
    utest::assert_fail $?

    string::is_false "n"
    utest::assert $?

    string::is_false "N"
    utest::assert $?

    string::is_false "yes"
    utest::assert_fail $?

    string::is_false "no"
    utest::assert $?

    string::is_false "true"
    utest::assert_fail $?

    string::is_false "True"
    utest::assert_fail $?

    string::is_false "TrUe"
    utest::assert_fail $?

    string::is_false "TRuE"
    utest::assert_fail $?

    string::is_false "TRUE"
    utest::assert_fail $?

    string::is_false "false"
    utest::assert $?

    string::is_false "False"
    utest::assert $?

    string::is_false "FalSe"
    utest::assert $?

    string::is_false "FaLSe"
    utest::assert $?

    string::is_false "FALSE"
    utest::assert $?
}

function string::_main() {

    return "$SHELL_TRUE"
}

string::_main
