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

function array::is_not_empty() {
    ! array::is_empty "$@"
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

function array::is_not_contain() {
    ! array::is_contain "$@"
}

# 通过下标获取数组元素
# 下标支持负数
function array::get() {
    local -n array_0181bda3=$1
    shift
    local index_0181bda3=$1
    shift

    local length_0181bda3
    local min_index_0181bda3

    length_0181bda3=$(array::length "${!array_0181bda3}") || return "$SHELL_FALSE"

    ((min_index_0181bda3 = 0 - length_0181bda3))

    if array::is_empty "${!array_0181bda3}"; then
        return "$SHELL_FALSE"
    fi

    if [ "${index_0181bda3}" -lt "${min_index_0181bda3}" ] || [ "${index_0181bda3}" -ge "${length_0181bda3}" ]; then
        return "$SHELL_FALSE"
    fi

    echo "${array_0181bda3[${index_0181bda3}]}"
    return "$SHELL_TRUE"
}

# 查找元素，返回找到的第一个下标
# 没有找到输出 -1
function array::find() {
    local -n array_5866a273=$1
    shift
    local item_5866a273=$1
    shift
    local length_5866a273
    local index_5866a273

    length_5866a273=$(array::length "${!array_5866a273}") || return "$SHELL_FALSE"

    for ((index_5866a273 = 0; index_5866a273 < length_5866a273; index_5866a273++)); do
        if [ "${array_5866a273[${index_5866a273}]}" = "${item_5866a273}" ]; then
            echo "${index_5866a273}"
            return "$SHELL_TRUE"
        fi
    done
    echo "-1"
    return "$SHELL_TRUE"
}

# 查找元素，返回找到的第一个下标
# 没有找到返回 $SHELL_FALSE
function array::index() {
    local index
    index=$(array::find "$@")
    if [ "$index" -eq "-1" ]; then
        return "$SHELL_FALSE"
    fi
    echo "$index"
    return "$SHELL_TRUE"
}

function array::first() {
    local -n array_89220a75=$1
    array::get "${!array_89220a75}" 0 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function array::last() {
    local -n array_b8bc739b=$1
    array::get "${!array_b8bc739b}" -1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
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

function array::remove_at() {
    local -n array_a6fe79c9=$1
    local index_a6fe79c9="$2"

    local length_a6fe79c9
    local min_index_a6fe79c9

    length_a6fe79c9=$(array::length "${!array_a6fe79c9}") || return "$SHELL_FALSE"

    ((min_index_a6fe79c9 = 0 - length_a6fe79c9))

    if array::is_empty "${!array_a6fe79c9}"; then
        return "$SHELL_FALSE"
    fi

    if [ "${index_a6fe79c9}" -lt "${min_index_a6fe79c9}" ] || [ "${index_a6fe79c9}" -ge "${length_a6fe79c9}" ]; then
        return "$SHELL_FALSE"
    fi

    if [ "${index_a6fe79c9}" -lt "0" ]; then
        index_a6fe79c9=$((length_a6fe79c9 + index_a6fe79c9))
    fi

    array_a6fe79c9=("${array_a6fe79c9[@]::${index_a6fe79c9}}" "${array_a6fe79c9[@]:${index_a6fe79c9}+1}")
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

function array::copy() {
    local -n result_610fd6e5="$1"
    shift
    local -n array_610fd6e5="$1"
    shift
    # shellcheck disable=SC2034
    result_610fd6e5=("${array_610fd6e5[@]}")
    return "$SHELL_TRUE"
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

function array::insert() {
    local -n array_7a7653c6="$1"
    shift
    local index_7a7653c6="$1"
    shift
    local item_7a7653c6="$1"
    shift
    local length_7a7653c6

    length_7a7653c6="$(array::length "${!array_7a7653c6}")"
    if [ "$index_7a7653c6" -lt "0" ] || [ "$index_7a7653c6" -gt "${length_7a7653c6}" ]; then
        lerror "index is out of range, index=${index_7a7653c6}, length=${length_7a7653c6}"
        return "$SHELL_FALSE"
    fi

    if [ "$index_7a7653c6" -eq "0" ]; then
        array::lpush "${!array_7a7653c6}" "$item_7a7653c6" || return "$SHELL_FALSE"
        return "$SHELL_TRUE"
    fi

    if [ "$index_7a7653c6" -eq "${length_7a7653c6}" ]; then
        array::rpush "${!array_7a7653c6}" "$item_7a7653c6" || return "$SHELL_FALSE"
        return "$SHELL_TRUE"
    fi

    array_7a7653c6=("${array_7a7653c6[@]:0:index_7a7653c6}" "$item_7a7653c6" "${array_7a7653c6[@]:index_7a7653c6}")

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

function TEST::array::is_not_empty() {
    local arr
    array::is_not_empty arr
    utest::assert_fail $?

    arr=()
    array::is_not_empty arr
    utest::assert_fail $?

    array::lpush arr 1
    array::is_not_empty arr
    utest::assert $?

    array::lpush arr 2
    array::is_not_empty arr
    utest::assert $?
}

function TEST::array::get() {
    local arr

    array::get arr 0
    utest::assert_fail $?

    array::get arr -0
    utest::assert_fail $?

    array::get arr 1
    utest::assert_fail $?

    arr=(1 2 3 4 5)

    utest::assert_equal "$(array::get arr -0)" 1
    utest::assert_equal "$(array::get arr -1)" 5
    utest::assert_equal "$(array::get arr -2)" 4
    utest::assert_equal "$(array::get arr -3)" 3
    utest::assert_equal "$(array::get arr -4)" 2
    utest::assert_equal "$(array::get arr -5)" 1
    array::get arr -6
    utest::assert_fail $?

    utest::assert_equal "$(array::get arr 0)" 1
    utest::assert_equal "$(array::get arr 1)" 2
    utest::assert_equal "$(array::get arr 2)" 3
    utest::assert_equal "$(array::get arr 3)" 4
    utest::assert_equal "$(array::get arr 4)" 5
    array::get arr 5
    utest::assert_fail $?
}

function TEST::array::find() {
    local arr

    utest::assert_equal "$(array::find arr "xxxx")" -1
    utest::assert_equal "$(array::find arr "1")" -1

    arr=(1 2 3)
    utest::assert_equal "$(array::find arr "1")" 0
    utest::assert_equal "$(array::find arr "2")" 1
    utest::assert_equal "$(array::find arr "3")" 2

    utest::assert_equal "$(array::find arr "4")" -1

    arr=("a" "b" "a" "b" "c")
    utest::assert_equal "$(array::find arr "a")" 0
    utest::assert_equal "$(array::find arr "b")" 1
    utest::assert_equal "$(array::find arr "c")" 4
}

function TEST::array::index() {
    local arr
    local index

    array::index arr "xxxx"
    utest::assert_fail $?
    utest::assert_equal "$(array::index arr "xxxx")" ""

    arr=(1 2 3)
    utest::assert_equal "$(array::index arr "1")" 0
    utest::assert_equal "$(array::index arr "2")" 1
    utest::assert_equal "$(array::index arr "3")" 2
    index=$(array::index arr "3")
    utest::assert $?
    index=$(array::index arr "4")
    utest::assert_fail $?
    utest::assert_equal "$(array::index arr "4")" ""

    arr=("a" "b" "a" "b" "c")
    utest::assert_equal "$(array::index arr "a")" 0
    utest::assert_equal "$(array::index arr "b")" 1
    utest::assert_equal "$(array::index arr "c")" 4
}

function TEST::array::first() {
    local arr

    array::first arr
    utest::assert_fail $?

    arr=(1 2 3 4 5)
    utest::assert_equal "$(array::first arr)" 1
}

function TEST::array::last() {
    local arr

    array::last arr
    utest::assert_fail $?

    arr=(1 2 3 4 5)
    utest::assert_equal "$(array::last arr)" 5
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

function TEST::array::insert() {
    local arr=()

    array::insert arr -1 1>/dev/null
    utest::assert_fail $?

    array::insert arr 1 1>/dev/null
    utest::assert_fail $?

    array::insert arr 0 1
    utest::assert_equal "${arr[*]}" "1"

    array::insert arr 1 2
    utest::assert_equal "${arr[*]}" "1 2"

    array::insert arr 0 3
    utest::assert_equal "${arr[*]}" "3 1 2"

    array::insert arr 1 4
    utest::assert_equal "${arr[*]}" "3 4 1 2"

    array::insert arr -1 1>/dev/null
    utest::assert_fail $?

    array::insert arr 5 1>/dev/null
    utest::assert_fail $?
}

function TEST::array::remove() {
    local arr=("1" "2" "3" "1" "4" "5")
    array::remove arr 0
    utest::assert_equal "${arr[*]}" "1 2 3 1 4 5"
    array::remove arr 1
    utest::assert_equal "${arr[*]}" "2 3 4 5"
}

function TEST::array::remove_at() {
    local arr=("1" "2" "3" "1" "4" "5" "6" "7")
    array::remove_at arr 0
    utest::assert_equal "${arr[*]}" "2 3 1 4 5 6 7"
    array::remove_at arr 1
    utest::assert_equal "${arr[*]}" "2 1 4 5 6 7"
    array::remove_at arr -1
    utest::assert_equal "${arr[*]}" "2 1 4 5 6"
    array::remove_at arr -5
    utest::assert_equal "${arr[*]}" "1 4 5 6"
    array::remove_at arr -2
    utest::assert_equal "${arr[*]}" "1 4 6"
}

function TEST::array::copy() {
    local arr=("1" "2" "3" "4" "5" "6" "7")
    local arr_copy

    array::copy arr_copy arr
    utest::assert_equal "${arr_copy[*]}" "${arr[*]}"

    array::rpop arr
    utest::assert_equal "${arr[*]}" "1 2 3 4 5 6"
    utest::assert_equal "${arr_copy[*]}" "1 2 3 4 5 6 7"

    array::lpop arr_copy
    utest::assert_equal "${arr[*]}" "1 2 3 4 5 6"
    utest::assert_equal "${arr_copy[*]}" "2 3 4 5 6 7"
}

function array::_main() {
    return "$SHELL_TRUE"
}

array::_main
