#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_3cd455df="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/print.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cd455df}/utest.sh"

function array::print() {
    # 虽然是局部变量，但是引用的名字不能和参数的名字一样
    local -n _ref_array_3828487c=$1
    local item
    for item in "${_ref_array_3828487c[@]}"; do
        echo "$item"
    done
    return "$SHELL_TRUE"
}

function array::is_contain() {
    # shellcheck disable=SC2178
    local -n _ref_array_24667025=$1
    local element=$2
    local item
    for item in "${_ref_array_24667025[@]}"; do
        if [ "$item" = "$element" ]; then
            return "$SHELL_TRUE"
        fi
    done
    return "$SHELL_FALSE"
}

# 去重
function array::dedup() {
    # shellcheck disable=SC2178
    local -n _ref_array_a16ccf13=$1
    local temp_array=()
    local item
    for item in "${_ref_array_a16ccf13[@]}"; do
        if array::is_contain temp_array "$item"; then
            continue
        fi
        temp_array+=("$item")
    done
    _ref_array_a16ccf13=("${temp_array[@]}")
    return "$SHELL_TRUE"
}

function array::remove() {
    local -n _ref_array_6338e158=$1
    local remove_item="$2"

    local new_array=()
    local item
    for item in "${_ref_array_6338e158[@]}"; do
        if [ "$item" != "$remove_item" ]; then
            new_array+=("$item")
        fi
    done
    _ref_array_6338e158=("${new_array[@]}")
}

function array::remove_empty() {
    local -n _ref_array_7d0b5b5e=$1
    array::remove _ref_array_7d0b5b5e ""
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
    local -n _ref_array_8b0e7b2e=$1

    readarray -t _ref_array_8b0e7b2e <&0
    array::remove_empty _ref_array_8b0e7b2e
}

function array::rpush() {
    # shellcheck disable=SC2178
    local -n _ref_array_8d8f5bce=$1
    local item=$2
    _ref_array_8d8f5bce+=("${item}")
}

# 数组里没有这个元素时才添加
function array::rpush_unique() {
    # shellcheck disable=SC2178
    local -n _ref_array_868d2cea=$1
    local item=$2
    if ! array::is_contain _ref_array_868d2cea "$item"; then
        _ref_array_868d2cea+=("${item}")
    fi
}

function array::rpop() {
    # shellcheck disable=SC2178
    local -n _ref_array_18f43693=$1
    _ref_array_18f43693=("${_ref_array_18f43693[@]:1}")
}

function array::extend() {
    # shellcheck disable=SC2178
    local -n _ref_array_84a72974=$1
    local -n _ref_array_29f69789=$2
    _ref_array_84a72974+=("${_ref_array_29f69789[@]}")
}

# 反转后保存到其他数组
function array::reverse_new() {
    # shellcheck disable=SC2178
    local -n _ref_array_c0b35efa=$1 # 用于保存反转后的数组
    local -n _ref_array_86c99128=$2 # 需要反转的数组
    local length=${#_ref_array_86c99128[@]}
    while [ "$length" -gt 0 ]; do
        length=$((length - 1))
        _ref_array_c0b35efa+=("${_ref_array_86c99128[$length]}")
    done
}

# 反转后保存到自身
function array::reverse() {
    # shellcheck disable=SC2178
    local -n _ref_array_f46f59e5=$1 # 用于保存反转后的数组
    local length=${#_ref_array_f46f59e5[@]}
    local left=$((length / 2))

    while [ "$left" -gt 0 ]; do
        local left_index=$((left - 1))
        local right_index=$((length - left))
        local temp="${_ref_array_f46f59e5[$left_index]}"
        _ref_array_f46f59e5[left_index]="${_ref_array_f46f59e5[$right_index]}"
        _ref_array_f46f59e5[right_index]="$temp"

        left=$((left - 1))
    done
}

function array::_test_array::reverse_new() {
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

function array::_test_array::reverse() {
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

function array::_test_array::dedup() {
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

string::is_true "$TEST" && array::_test_array::reverse
string::is_true "$TEST" && array::_test_array::reverse_new
string::is_true "$TEST" && array::_test_array::dedup
true
