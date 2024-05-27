#!/bin/bash

if [ -n "${SCRIPT_DIR_3cd455df}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_3cd455df="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/print.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/utest.sh"

function array::print() {
    # 虽然是局部变量，但是引用的名字不能和参数的名字一样
    local -n array_3828487c=$1
    local item_3828487c
    for item_3828487c in "${array_3828487c[@]}"; do
        echo "$item_3828487c"
    done
    return "$SHELL_TRUE"
}

function array::length() {
    local -n array_4bd6518c=$1

    echo "${#array_4bd6518c[@]}"
}

function array::is_empty() {
    local -n array_6d0f7b0e=$1

    if [ "$(array::length "${!array_6d0f7b0e}")" -eq "0" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function array::is_contain() {
    # shellcheck disable=SC2178
    local -n array_24667025=$1
    local element_24667025=$2
    local item_24667025
    for item_24667025 in "${array_24667025[@]}"; do
        if [ "$item_24667025" = "$element_24667025" ]; then
            return "$SHELL_TRUE"
        fi
    done
    return "$SHELL_FALSE"
}

# 去重
function array::dedup() {
    # shellcheck disable=SC2178
    local -n array_a16ccf13=$1
    local temp_array_a16ccf13=()
    local item_a16ccf13
    for item_a16ccf13 in "${array_a16ccf13[@]}"; do
        if array::is_contain temp_array_a16ccf13 "$item_a16ccf13"; then
            continue
        fi
        temp_array_a16ccf13+=("$item_a16ccf13")
    done
    array_a16ccf13=("${temp_array_a16ccf13[@]}")
    return "$SHELL_TRUE"
}

function array::remove() {
    local -n array_6338e158=$1
    local remove_item_6338e158="$2"

    local new_array_6338e158=()
    local item_6338e158
    for item_6338e158 in "${array_6338e158[@]}"; do
        if [ "$item_6338e158" != "$remove_item_6338e158" ]; then
            new_array_6338e158+=("$item_6338e158")
        fi
    done
    array_6338e158=("${new_array_6338e158[@]}")
}

function array::remove_empty() {
    local -n array_7d0b5b5e=$1
    array::remove "${!array_7d0b5b5e}" ""
}

# readarray的用法： readarray -t array_var < <(command)
# NOTE: 上面的用法有一个问题，当command执行失败异常退出时，readarray并不会报错，下面两种方式都不能解决问题
# - readarray -t array_var < <(command)
# - readarray -t array_var < <(command || || return "$SHELL_FALSE")
# 建议如下的写法：
# temp_str="$(command)" || return "$SHELL_FALSE"
# readarray -t array_var < <(echo "$temp_str")
# 因为 echo 出错的几率更小
# 所以这个函数也推荐先执行命令，然后使用echo输出结果
function array::readarray() {
    local -n array_8b0e7b2e=$1

    readarray -t array_8b0e7b2e <&0
    array::remove_empty "${!array_8b0e7b2e}"
}

function array::rpush() {
    # shellcheck disable=SC2178
    local -n array_8d8f5bce=$1
    local item_8d8f5bce=$2
    array_8d8f5bce+=("${item_8d8f5bce}")
}

# 数组里没有这个元素时才添加
function array::rpush_unique() {
    # shellcheck disable=SC2178
    local -n array_868d2cea=$1
    local item_868d2cea=$2
    if ! array::is_contain "${!array_868d2cea}" "$item_868d2cea"; then
        array_868d2cea+=("${item_868d2cea}")
    fi
}

function array::rpop() {
    # shellcheck disable=SC2178
    local -n array_18f43693=$1
    local -n result_18f43693
    if [ "${#@}" -gt 1 ]; then
        result_18f43693=$2
    fi
    if array::is_empty "${!array_18f43693}"; then
        println_error --stream="stderr" "array(${!array_18f43693}) is empty, can not rpop"
        return "$SHELL_FALSE"
    fi
    if [ -R result_18f43693 ]; then
        result_18f43693="${array_18f43693[-1]}"
    fi
    unset "array_18f43693[-1]"
    return "$SHELL_TRUE"
}

function array::lpush() {
    # shellcheck disable=SC2178
    local -n array_af246e16=$1
    local item_af246e16=$2

    array_af246e16=("$item_af246e16" "${array_af246e16[@]}")
    return "$SHELL_TRUE"
}

# 数组里没有这个元素时才添加
function array::lpush_unique() {
    # shellcheck disable=SC2178
    local -n array_15434693=$1
    local item_15434693=$2

    if ! array::is_contain "${!array_15434693}" "$item_15434693"; then
        array::lpush "${!array_15434693}" "$item_15434693" || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function array::lpop() {
    # shellcheck disable=SC2178
    local -n array_fd6d55c0=$1
    local -n result_fd6d55c0
    if [ "${#@}" -gt 1 ]; then
        result_fd6d55c0=$2
    fi

    if array::is_empty "${!array_fd6d55c0}"; then
        println_error --stream="stderr" "array(${!array_fd6d55c0}) is empty, can not lpop"
        return "$SHELL_FALSE"
    fi

    if [ -R result_fd6d55c0 ]; then
        result_fd6d55c0="${array_fd6d55c0[0]}"
    fi
    # 不能使用 unset "array_fd6d55c0[0]"
    # 测试发现第一次 lpop ("1" "2" "3") 正常，返回 1，剩余元素为 (2 3)。继续 lpop 不符合预期，返回空，剩余元素仍为 (2 3)。
    array_fd6d55c0=("${array_fd6d55c0[@]:1}")
    return "$SHELL_TRUE"
}

function array::extend() {
    # shellcheck disable=SC2178
    local -n array_84a72974=$1
    local -n array2_84a72974=$2
    array_84a72974+=("${array2_84a72974[@]}")
}

# 反转后保存到其他数组
function array::reverse_new() {
    # shellcheck disable=SC2178
    local -n result_c0b35efa=$1 # 用于保存反转后的数组
    local -n array_c0b35efa=$2  # 需要反转的数组
    local length_c0b35efa
    length_c0b35efa="$(array::length "${!array_c0b35efa}")"
    while [ "$length_c0b35efa" -gt 0 ]; do
        length_c0b35efa=$((length_c0b35efa - 1))
        result_c0b35efa+=("${array_c0b35efa[$length_c0b35efa]}")
    done
}

# 反转后保存到自身
function array::reverse() {
    # shellcheck disable=SC2178
    local -n array_f46f59e5=$1 # 用于保存反转后的数组
    local length_f46f59e5
    length_f46f59e5="$(array::length "${!array_f46f59e5}")"
    local left_f46f59e5=$((length_f46f59e5 / 2))
    local left_index_f46f59e5
    local right_index_f46f59e5
    local temp_f46f59e5

    while [ "$left_f46f59e5" -gt 0 ]; do
        left_index_f46f59e5=$((left_f46f59e5 - 1))
        right_index_f46f59e5=$((length_f46f59e5 - left_f46f59e5))
        temp_f46f59e5="${array_f46f59e5[$left_index_f46f59e5]}"
        array_f46f59e5[left_index_f46f59e5]="${array_f46f59e5[$right_index_f46f59e5]}"
        array_f46f59e5[right_index_f46f59e5]="$temp_f46f59e5"

        left_f46f59e5=$((left_f46f59e5 - 1))
    done
}

function array::map() {
    local -n result_f4a7c537="$1"
    shift
    local -n array_f4a7c537="$1"
    shift
    local function_name_f4a7c537="$1"
    shift
    local function_params_f4a7c537=("$@")

    local index_f4a7c537
    local temp_array_f4a7c537=()

    for ((index_f4a7c537 = 0; index_f4a7c537 < "${#array_f4a7c537[@]}"; index_f4a7c537++)); do
        temp_array_f4a7c537+=("$("${function_name_f4a7c537}" "${array_f4a7c537[$index_f4a7c537]}" "${function_params_f4a7c537[@]}")") || return "$SHELL_FALSE"
    done
    # shellcheck disable=SC2034
    result_f4a7c537=("${temp_array_f4a7c537[@]}")
    return "$SHELL_TRUE"
}

function array::join_with() {
    local -n array_3f2ce83a="$1"
    shift
    local separator_3f2ce83a="${1-}"
    local result_3f2ce83a=""
    local item_3f2ce83a=""
    for item_3f2ce83a in "${array_3f2ce83a[@]}"; do
        if [ -z "$result_3f2ce83a" ]; then
            result_3f2ce83a="$item_3f2ce83a"
            continue
        fi

        result_3f2ce83a+="${separator_3f2ce83a}${item_3f2ce83a}"
    done
    echo "$result_3f2ce83a"
    return "$SHELL_TRUE"
}

###################################### 下面是测试代码 ######################################

function TEST::array::length() {
    local arr
    utest::assert_equal "$(array::length arr)" 0

    array::lpush arr 1
    utest::assert_equal "$(array::length arr)" 1

    array::lpush arr 2
    utest::assert_equal "$(array::length arr)" 2

    array::lpush arr 3
    utest::assert_equal "$(array::length arr)" 3
}

function TEST::array::is_empty() {
    local arr
    array::is_empty arr
    utest::assert $?

    arr=()
    array::is_empty arr
    utest::assert $?

    array::lpush arr 1
    array::is_empty arr
    utest::assert_fail $?

    array::lpush arr 2
    array::is_empty arr
    utest::assert_fail $?
}

function TEST::array::reverse_new() {
    local arr=(1 2 3 4 5)
    local res=()

    array::reverse_new res arr
    utest::assert_equal "${res[*]}" "5 4 3 2 1"

    local arr=("a" "b" "c" "d" "e")
    local res=()

    array::reverse_new res arr
    utest::assert_equal "${res[*]}" "e d c b a"

    arr=(1 2 3 4)
    res=()
    array::reverse_new res arr
    utest::assert_equal "${res[*]}" "4 3 2 1"
}

function TEST::array::reverse() {
    local arr=(1 2 3 4 5)

    array::reverse arr
    utest::assert_equal "${arr[*]}" "5 4 3 2 1"

    local arr=("a" "b" "c" "d" "e")

    array::reverse arr
    utest::assert_equal "${arr[*]}" "e d c b a"

    arr=(1 2 3 4)
    array::reverse arr
    utest::assert_equal "${arr[*]}" "4 3 2 1"
}

function TEST::array::dedup() {
    local arr=(1 2 3 4 5)

    array::dedup arr
    utest::assert_equal "${arr[*]}" "1 2 3 4 5"

    arr=("a" "b" "c" "d" "e")
    array::dedup arr
    utest::assert_equal "${arr[*]}" "a b c d e"

    arr=(1 3 2 3 4 3 5)
    array::dedup arr
    utest::assert_equal "${arr[*]}" "1 3 2 4 5"

    arr=(1 1 1 1 1 1 1)
    array::dedup arr
    utest::assert_equal "${arr[*]}" "1"

    arr=()
    array::dedup arr
    utest::assert_equal "${arr[*]}" ""

    arr=("a" "b" "a" "d" "d" "e")
    array::dedup arr
    utest::assert_equal "${arr[*]}" "a b d e"
}

function TEST::array::rpush() {
    local arr=()
    array::rpush arr 1
    utest::assert_equal "${arr[*]}" "1"
    array::rpush arr 2
    utest::assert_equal "${arr[*]}" "1 2"
    array::rpush arr 3
    utest::assert_equal "${arr[*]}" "1 2 3"
}

function TEST::array::rpush_unique() {
    local arr=()
    array::rpush_unique arr 1
    utest::assert_equal "${arr[*]}" "1"
    array::rpush_unique arr 2
    utest::assert_equal "${arr[*]}" "1 2"
    array::rpush_unique arr 3
    utest::assert_equal "${arr[*]}" "1 2 3"

    array::rpush_unique arr 1
    utest::assert_equal "${arr[*]}" "1 2 3"

    array::rpush_unique arr 3
    utest::assert_equal "${arr[*]}" "1 2 3"
}

function TEST::array::rpop() {
    local arr
    local item
    array::rpop arr 2>/dev/null
    utest::assert_fail $?

    arr=()
    array::rpop arr 2>/dev/null
    utest::assert_fail $?

    array::rpush arr 1
    array::rpop arr item
    utest::assert_equal "$item" "1"
    utest::assert_equal "${arr[*]}" ""

    arr=()
    array::rpush arr 1
    array::rpush arr 2
    array::rpush arr 3
    array::rpop arr item
    utest::assert $?
    utest::assert_equal "$item" "3"
    utest::assert_equal "${arr[*]}" "1 2"

    array::rpop arr item
    utest::assert $?
    utest::assert_equal "$item" "2"
    utest::assert_equal "${arr[*]}" "1"

    array::rpop arr item
    utest::assert $?
    utest::assert_equal "$item" "1"
    utest::assert_equal "${arr[*]}" ""

    arr=()
    array::rpush arr 1
    array::rpush arr 2
    array::rpush arr 3
    array::rpop arr item
    utest::assert $?
    utest::assert_equal "$item" "3"
    utest::assert_equal "${arr[*]}" "1 2"
    array::rpush arr 3
    array::rpop arr item
    utest::assert $?
    utest::assert_equal "$item" "3"
    utest::assert_equal "${arr[*]}" "1 2"
}

function TEST::array::lpush() {
    local arr=()
    array::lpush arr 1
    utest::assert_equal "${arr[*]}" "1"
    array::lpush arr 2
    utest::assert_equal "${arr[*]}" "2 1"
    array::lpush arr 3
    utest::assert_equal "${arr[*]}" "3 2 1"
}

function TEST::array::lpush_unique() {
    local arr=()
    array::lpush_unique arr 1
    utest::assert_equal "${arr[*]}" "1"
    array::lpush_unique arr 2
    utest::assert_equal "${arr[*]}" "2 1"
    array::lpush_unique arr 3
    utest::assert_equal "${arr[*]}" "3 2 1"

    array::lpush_unique arr 1
    utest::assert_equal "${arr[*]}" "3 2 1"

    array::lpush_unique arr 3
    utest::assert_equal "${arr[*]}" "3 2 1"
}

function TEST::array::lpop() {
    local arr
    local item
    array::lpop arr 2>/dev/null
    utest::assert_fail $?

    arr=()
    array::lpop arr 2>/dev/null
    utest::assert_fail $?

    array::lpush arr 1
    array::lpop arr item
    utest::assert $?
    utest::assert_equal "$item" "1"
    utest::assert_equal "${arr[*]}" ""

    arr=()
    array::rpush arr 1
    array::rpush arr 2
    array::rpush arr 3
    array::lpop arr item
    utest::assert $?
    utest::assert_equal "$item" "1"
    utest::assert_equal "${arr[*]}" "2 3"

    array::lpop arr item
    utest::assert $?
    utest::assert_equal "$item" "2"
    utest::assert_equal "${arr[*]}" "3"

    array::lpop arr item
    utest::assert $?
    utest::assert_equal "$item" "3"
    utest::assert_equal "${arr[*]}" ""
}

function TEST::array::map() {
    local res

    function trim() {
        local str="$1"
        echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
        return "$SHELL_TRUE"
    }

    # 测试 trim 函数正确性，顺便规避 shellcheck 的检查
    utest::assert_equal "$(trim " ab    ")" "ab"

    res=()
    array::map res res trim
    utest::assert_equal "${#res[@]}" 0

    res=("")
    array::map res res trim
    utest::assert_equal "${#res[@]}" 1
    utest::assert_equal "${res[0]}" ""

    res=(" ")
    array::map res res trim
    utest::assert_equal "${#res[@]}" 1
    utest::assert_equal "${res[0]}" ""

    res=("  ")
    array::map res res trim
    utest::assert_equal "${#res[@]}" 1
    utest::assert_equal "${res[0]}" ""

    res=("  " "a" " ab ")
    array::map res res trim
    utest::assert_equal "${#res[@]}" 3
    utest::assert_equal "${res[0]}" ""
    utest::assert_equal "${res[1]}" "a"
    utest::assert_equal "${res[2]}" "ab"
}

function TEST::array::join_with::default() {
    local arr=()
    local res

    res=$(array::join_with arr)
    utest::assert $?
    utest::assert_equal "$res" ""

    arr=("abc")
    res=$(array::join_with arr)
    utest::assert $?
    utest::assert_equal "$res" "abc"

    arr=("abc" "def")
    res=$(array::join_with arr)
    utest::assert $?
    utest::assert_equal "$res" "abcdef"

    arr=(" " " ")
    res=$(array::join_with arr)
    utest::assert $?
    utest::assert_equal "$res" "  "
}

function TEST::array::join_with::on_char() {
    local arr=()
    local res

    res=$(array::join_with arr ",")
    utest::assert $?
    utest::assert_equal "$res" ""

    arr=("abc")
    res=$(array::join_with arr ",")
    utest::assert $?
    utest::assert_equal "$res" "abc"

    arr=("abc" "def")
    res=$(array::join_with arr ",")
    utest::assert $?
    utest::assert_equal "$res" "abc,def"

    arr=(" " " ")
    res=$(array::join_with arr ",")
    utest::assert $?
    utest::assert_equal "$res" " , "

    arr=("," ",")
    res=$(array::join_with arr ",")
    utest::assert $?
    utest::assert_equal "$res" ",,,"
}

function TEST::array::join_with::two_char() {
    local arr=()
    local res

    res=$(array::join_with arr ",,")
    utest::assert $?
    utest::assert_equal "$res" ""

    arr=("abc")
    res=$(array::join_with arr ",,")
    utest::assert $?
    utest::assert_equal "$res" "abc"

    arr=("abc" "def")
    res=$(array::join_with arr ",,")
    utest::assert $?
    utest::assert_equal "$res" "abc,,def"

    arr=(" " " ")
    res=$(array::join_with arr ",,")
    utest::assert $?
    utest::assert_equal "$res" " ,, "

    arr=("," ",")
    res=$(array::join_with arr ",,")
    utest::assert $?
    utest::assert_equal "$res" ",,,,"

    arr=("abc" "def")
    res=$(array::join_with arr ", ")
    utest::assert $?
    utest::assert_equal "$res" "abc, def"
}

function array::_main() {
    return "$SHELL_TRUE"
}

array::_main
