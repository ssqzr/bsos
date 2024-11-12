#!/bin/bash

# 注意事项：
# 1. 浮点数精度是通过 printf 实现的， awk 里的 printf ，bash 的 printf 都是参考的 C 语言标准库里的 printf
# 2. printf 对于 0.5 的值处理，偶舍奇进。
#       当数值的整数部分为偶数时， .5 不进位，会被舍去
#       当数值的整数部分为奇数时， .5 进位
#       https://en.wikipedia.org/wiki/IEEE_754#Rounding_rules
#       https://learn.microsoft.com/zh-cn/cpp/c-runtime-library/reference/printf-printf-l-wprintf-wprintf-l?view=msvc-170
#       具体测试看 TEST::math::printf_0_5
# 3. 浮点数的计算一定不要想当然，可能就出乎预料

if [ -n "${SCRIPT_DIR_4947c3c0}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_4947c3c0="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_4947c3c0}/../constant.sh"

# 判断是否是整数，正负整数都是整数
function math::is_integer() {
    local num=$1
    if [[ $num =~ ^-?[0-9]+$ ]]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

function math::is_not_integer() {
    ! math::is_integer "$1"
}

# 大于
# 1. 整数、浮点数
# 2. 正数、负数
function math::gt() {
    local num1=$1
    local num2=$2
    local res
    res=$(awk "BEGIN{if(${num1} > ${num2}) print 0; else print 1}") || return "$SHELL_FALSE"
    if [ "$res" = "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

# 小于
# 1. 整数、浮点数
# 2. 正数、负数
function math::lt() {
    local num1=$1
    local num2=$2
    local res
    res=$(awk "BEGIN{if(${num1} < ${num2}) print 0; else print 1}") || return "$SHELL_FALSE"
    if [ "$res" = "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

# 等于
# 1. 整数、浮点数
# 2. 正数、负数
function math::eq() {
    local num1=$1
    local num2=$2
    local res
    res=$(awk "BEGIN{if(${num1} == ${num2}) print 0; else print 1}") || return "$SHELL_FALSE"
    if [ "$res" = "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

function math::ne() {
    ! math::eq "$1" "$2"
}

# 大于等于
# 1. 整数、浮点数
# 2. 正数、负数
function math::ge() {
    math::gt "$1" "$2" || math::eq "$1" "$2"
}

# 小于等于
# 1. 整数、浮点数
# 2. 正数、负数
function math::le() {
    math::lt "$1" "$2" || math::eq "$1" "$2"
}

# 向下取整
# 1.123 => 1
function math::floor() {
    local num=$1
    local res=""
    # awk '{ print floor($1) }' | awk -l math
    # awk int 是朝0截断:
    #   -3 => -3    -3.9 => -3
    #   0 => 0    -0 => -0
    #   1 => 1    1.9 => 1
    res=$(awk "BEGIN{print int($num)}") || return "$SHELL_FALSE"
    if math::eq "$num" "$res"; then
        echo "$res"
        return "$SHELL_TRUE"
    fi
    if math::ge "$num" 0; then
        echo "$res"
        return "$SHELL_TRUE"
    else
        # awk "BEGIN{print int($num - 1)}" || return "$SHELL_FALSE"
        echo "$((res - 1))"
        return "$SHELL_TRUE"
    fi
}

# 向上取整
# 1.123 => 2
function math::ceil() {
    local num=$1
    local res

    res=$(math::floor "$num") || return "$SHELL_FALSE"
    if math::eq "$num" "$res"; then
        echo "$res"
        return "$SHELL_TRUE"
    fi
    echo "$((res + 1))"

    return "$SHELL_TRUE"
}

# 四舍五入
# 1.123 => 1
# 1.5 => 2
# -1.500001 => -2
# -1.5 => -1
# -1.49999 => -1
# NOTE: 浮点数需要注意精度的问题
# 0.499999 => 0
# 0.4999999 => 1
function math::round() {
    local num=$1
    local res

    res=$(awk "BEGIN{print $num+0.5}") || return "$SHELL_FALSE"
    lerror "lzw_test res=$res"
    res=$(math::floor "$res") || return "$SHELL_FALSE"
    echo "$res"

    return "$SHELL_TRUE"
}

function math::_check_accuracy() {
    local accuracy="$1"
    shift
    if math::is_not_integer "$accuracy"; then
        lerror "param accuracy($accuracy) must be integer"
        return "$SHELL_FALSE"
    fi
    if math::lt "$accuracy" 0; then
        lerror "param accuracy($accuracy) must be greater than or equal to 0"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# NOTE: 注意溢出
function math::add() {
    local num1="$1"
    shift
    local num2="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift
    local res

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${num1} + ${num2})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${num1} + ${num2})}")
    fi

    echo "$res"

    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# NOTE: 注意溢出
function math::sub() {
    local num1="$1"
    shift
    local num2="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift
    local res

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${num1} - ${num2})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${num1} - ${num2})}")
    fi

    echo "$res"

    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# NOTE: 注意溢出
function math::mul() {
    local num1="$1"
    shift
    local num2="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift
    local res

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${num1} * ${num2})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${num1} * ${num2})}")
    fi

    echo "$res"

    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# accuracy 是保留小数点后的位数，采用四舍五入的方式，注意 .5 的取舍是 偶舍奇进
function math::div() {
    # 被除数
    local dividend="$1"
    shift
    # 除数
    local divisor="$1"
    shift
    local accuracy="$1"
    shift

    local res

    if [ "$divisor" = "0" ]; then
        lerror "the divisor cannot be 0"
        return "$SHELL_FALSE"
    fi

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${dividend} / ${divisor})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${dividend} / ${divisor})}")
    fi

    echo "$res"
    return "$SHELL_TRUE"
}

function math::abs() {
    local num=$1
    shift

    if math::ge "$num" 0; then
        echo "$num"
        return "$SHELL_TRUE"
    fi

    math::sub 0 "$num" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::rand() {
    local min=$1
    shift
    local max=$1
    shift

    local diff_num

    min=${min:-0}

    num=$(head -n 10 "/dev/urandom" | cksum | awk -F ' ' '{print $1}')

    if [ -z "$max" ]; then
        if math::lt "$num" "$min"; then
            num=$((num + min))
        fi
    else
        diff_num=$((max - min + 1))
        num=$((num % diff_num + min))
    fi

    echo "$num"

    return "$SHELL_TRUE"
}

function math::sqrt() {
    local num=$1
    shift

    if math::lt "$num" 0; then
        lerror "param num($num) < 0"
        return "$SHELL_FALSE"
    fi

    awk "BEGIN{print sqrt($num)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::pi() {
    awk "BEGIN{print atan2(0, -1)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::degree_to_radian() {
    local degree=$1
    shift

    awk "BEGIN{print ($degree * atan2(0, -1) / 180)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::sin_by_radian() {
    local radian=$1
    shift

    awk "BEGIN{print sin($radian)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::sin_by_degree() {
    local degree=$1
    shift

    # local radian
    # radian=$(math::degree_to_radian "$degree") || return "$SHELL_FALSE"
    # math::sin_by_radian "$radian" || return "$SHELL_FALSE"
    awk "BEGIN{print sin($degree * atan2(0, -1) / 180)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::cos_by_radian() {
    local radian=$1
    shift

    awk "BEGIN{print cos($radian)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function math::cos_by_degree() {
    local degree=$1
    shift

    awk "BEGIN{print cos($degree * atan2(0, -1) / 180)}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

######################################### 下面是单元测试代码 #########################################
function TEST::math::printf_0_5() {
    utest::assert_equal "$(printf "%.0f" 0.5)" "0"
    utest::assert_equal "$(printf "%.0f" 1.5)" "2"
    utest::assert_equal "$(printf "%.0f" 2.5)" "2"
    utest::assert_equal "$(printf "%.0f" 3.5)" "4"
    utest::assert_equal "$(printf "%.0f" 4.5)" "4"
    utest::assert_equal "$(printf "%.0f" 5.5)" "6"
    utest::assert_equal "$(printf "%.0f" 6.5)" "6"
    utest::assert_equal "$(printf "%.0f" 7.5)" "8"
    utest::assert_equal "$(printf "%.0f" 8.5)" "8"
    utest::assert_equal "$(printf "%.0f" 9.5)" "10"
    utest::assert_equal "$(printf "%.0f" 10.5)" "10"
    utest::assert_equal "$(printf "%.0f" 11.5)" "12"
    utest::assert_equal "$(printf "%.0f" 12.5)" "12"
}

function TEST::math::is_integer() {
    math::is_integer 0
    utest::assert $?

    math::is_integer "-0"
    utest::assert $?

    math::is_integer 1
    utest::assert $?

    math::is_integer "-1"
    utest::assert $?

    math::is_integer 0.0
    utest::assert_fail $?

    math::is_integer "-0.0"
    utest::assert_fail $?

    math::is_integer 1.0
    utest::assert_fail $?

    math::is_integer "-1.0"
    utest::assert_fail $?

    math::is_integer 1.1
    utest::assert_fail $?

    math::is_integer "-1.1"
    utest::assert_fail $?

    math::is_integer 1.1234567890
    utest::assert_fail $?

    math::is_integer "-1.1234567890"
    utest::assert_fail $?
}

function TEST::math::is_not_integer() {
    math::is_not_integer 0
    utest::assert_fail $?

    math::is_not_integer "-0"
    utest::assert_fail $?

    math::is_not_integer 1
    utest::assert_fail $?

    math::is_not_integer "-1"
    utest::assert_fail $?

    math::is_not_integer 0.0
    utest::assert $?

    math::is_not_integer "-0.0"
    utest::assert $?

    math::is_not_integer 1.0
    utest::assert $?

    math::is_not_integer "-1.0"
    utest::assert $?

    math::is_not_integer 1.1
    utest::assert $?

    math::is_not_integer "-1.1"
    utest::assert $?

    math::is_not_integer 1.1234567890
    utest::assert $?

    math::is_not_integer "-1.1234567890"
    utest::assert $?
}

function TEST::math::gt() {
    # 整数比较
    math::gt 1 0
    utest::assert $?

    math::gt 0 1
    utest::assert_fail $?

    math::gt 1 1
    utest::assert_fail $?

    # 浮点数比较
    math::gt 1.1 1.0
    utest::assert $?

    math::gt 1.11 1.1
    utest::assert $?

    math::gt 1.1 1.10
    utest::assert_fail $?

    # 负整数比较
    math::gt -1 -2
    utest::assert $?

    math::gt -1 -1
    utest::assert_fail $?

    math::gt -2 -1
    utest::assert_fail $?

    # 负浮点数比较
    math::gt -1.1 -1.2
    utest::assert $?

    math::gt -1.1 -1.1
    utest::assert_fail $?

    math::gt -1.1 -1.10
    utest::assert_fail $?

    math::gt -1.10 -1.1
    utest::assert_fail $?

    math::gt -1.2 -1.1
    utest::assert_fail $?
}

function TEST::math::lt() {
    # 整数比较
    math::lt 0 1
    utest::assert $?

    math::lt 1 0
    utest::assert_fail $?

    math::lt 1 1
    utest::assert_fail $?

    # 浮点数比较
    math::lt 1.0 1.1
    utest::assert $?

    math::lt 1.1 1.11
    utest::assert $?

    math::lt 1.1 1.10
    utest::assert_fail $?

    # 负整数比较
    math::lt -2 -1
    utest::assert $?

    math::lt -1 -1
    utest::assert_fail $?

    math::lt -1 -2
    utest::assert_fail $?

    # 负浮点数比较
    math::lt -1.2 -1.1
    utest::assert $?

    math::lt -1.1 -1.1
    utest::assert_fail $?

    math::lt -1.1 -1.10
    utest::assert_fail $?

    math::lt -1.1 -1.11
    utest::assert_fail $?

    math::lt -1.1 -1.2
    utest::assert_fail $?
}

function TEST::math::eq() {
    # 测试整数
    math::eq 0 0
    utest::assert $?

    math::eq 0 0.0
    utest::assert $?

    math::eq 1 1
    utest::assert $?

    math::eq 1 2
    utest::assert_fail $?

    # 测试正浮点数
    math::eq 1.0 1
    utest::assert $?

    math::eq 1.1 1.1
    utest::assert $?

    math::eq 1.1 1.10
    utest::assert $?

    math::eq 1.10 1.11
    utest::assert_fail $?

    # 测试负整数
    math::eq -1 -1
    utest::assert $?

    math::eq 0 -0
    utest::assert $?

    math::eq -1 -2
    utest::assert_fail $?

    # 测试负浮点数
    math::eq -1.1 -1.1
    utest::assert $?

    math::eq -1.1 -1.10
    utest::assert $?

    math::eq -1.10 -1.11
    utest::assert_fail $?
}

function TEST::math::ge() {
    # 整数比较
    math::ge 0 0
    utest::assert $?

    math::ge 1 0
    utest::assert $?

    math::ge 1 1
    utest::assert $?

    math::ge 0 1
    utest::assert_fail $?

    # 浮点数比较
    math::ge 0 0.0000
    utest::assert $?

    math::ge 1.1 1.0
    utest::assert $?

    math::ge 1.1 1.1
    utest::assert $?

    math::ge 1.0 1.1
    utest::assert_fail $?

    # 负整数比较
    math::ge 0 -1
    utest::assert $?

    math::ge -1 -2
    utest::assert $?

    math::ge -1 -1
    utest::assert $?

    math::ge -2 -1
    utest::assert_fail $?

    # 负浮点数比较
    math::ge 0.0 -0.000
    utest::assert $?

    math::ge -1.1 -1.2
    utest::assert $?

    math::ge -1.1 -1.1
    utest::assert $?

    math::ge -1.1 -1.10
    utest::assert $?

    math::ge -1.2 -1.1
    utest::assert_fail $?

}

function TEST::math::le() {
    # 整数比较
    math::le 0 0
    utest::assert $?

    math::le 0 1
    utest::assert $?

    math::le 1 1
    utest::assert $?

    math::le 1 0
    utest::assert_fail $?

    # 浮点数比较
    math::le 0 0.0000
    utest::assert $?

    math::le 1.0 1.1
    utest::assert $?

    math::le 1.1 1.1
    utest::assert $?

    math::le 1.1 1.0
    utest::assert_fail $?

    # 负整数比较
    math::le -1 0
    utest::assert $?

    math::le -2 -1
    utest::assert $?

    math::le -1 -1
    utest::assert $?

    math::le -1 -2
    utest::assert_fail $?

    # 负浮点数比较
    math::le 0.0 -0.000
    utest::assert $?

    math::le -1.2 -1.1
    utest::assert $?

    math::le -1.1 -1.1
    utest::assert $?

    math::le -1.10 -1.1
    utest::assert $?

    math::le -1.1 -1.2
    utest::assert_fail $?

}

function TEST::math::floor() {
    local res

    # 正数
    res="$(math::floor 0)"
    utest::assert_equal "$res" "0"

    res="$(math::floor 0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::floor 0.5)"
    utest::assert_equal "$res" "0"

    res="$(math::floor 1.0000)"
    utest::assert_equal "$res" "1"

    res="$(math::floor 1.123)"
    utest::assert_equal "$res" "1"

    res="$(math::floor 1.5)"
    utest::assert_equal "$res" "1"

    res="$(math::floor 1.6)"
    utest::assert_equal "$res" "1"

    # 负数
    res="$(math::floor -0)"
    utest::assert_equal "$res" "0"

    res="$(math::floor -0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::floor -0.5)"
    utest::assert_equal "$res" "-1"

    res="$(math::floor "-1.0000")"
    utest::assert_equal "$res" "-1"

    res="$(math::floor -1.123)"
    utest::assert_equal "$res" "-2"

    res="$(math::floor -1.5)"
    utest::assert_equal "$res" "-2"

    res="$(math::floor -1.6)"
    utest::assert_equal "$res" "-2"
}

function TEST::math::ceil() {
    local res

    # 正数
    res="$(math::ceil 0)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil 0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil 0.5)"
    utest::assert_equal "$res" "1"

    res="$(math::ceil 1.0000)"
    utest::assert_equal "$res" "1"

    res="$(math::ceil 1.123)"
    utest::assert_equal "$res" "2"

    res="$(math::ceil 1.5)"
    utest::assert_equal "$res" "2"

    res="$(math::ceil 1.6)"
    utest::assert_equal "$res" "2"

    # 负数
    res="$(math::ceil -0)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil -0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil -0.5)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil -1.0000)"
    utest::assert_equal "$res" "-1"

    res="$(math::ceil -1.123)"
    utest::assert_equal "$res" "-1"

    res="$(math::ceil -1.5)"
    utest::assert_equal "$res" "-1"

    res="$(math::ceil -1.6)"
    utest::assert_equal "$res" "-1"
}

function TEST::math::round() {
    local res

    # 浮点数需要注意精度的问题
    res="$(math::round 0.499999)"
    utest::assert_equal "$res" "0"

    res="$(math::round 0.4999999)"
    utest::assert_equal "$res" "1"

    # 正整数
    res="$(math::round 0)"
    utest::assert_equal "$res" "0"

    res="$(math::round 3)"
    utest::assert_equal "$res" "3"

    # 正浮点数
    res="$(math::round 0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::round 0.499)"
    utest::assert_equal "$res" "0"

    res="$(math::round 0.5)"
    utest::assert_equal "$res" "1"

    res="$(math::round 0.99999999999999)"
    utest::assert_equal "$res" "1"

    # 负整数
    res="$(math::round -0)"
    utest::assert_equal "$res" "0"

    res="$(math::round -3)"
    utest::assert_equal "$res" "-3"

    # 负浮点数
    res="$(math::round -0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::round -0.4999999999999)"
    utest::assert_equal "$res" "0"

    res="$(math::round -0.5)"
    utest::assert_equal "$res" "0"

    res="$(math::round -0.5000000000001)"
    utest::assert_equal "$res" "-1"

    res="$(math::round -0.9999999999999)"
    utest::assert_equal "$res" "-1"
}

function TEST::math::add() {
    utest::assert_equal "$(math::add 1 1.4 0)" "2"
    utest::assert_equal "$(math::add 1 1.5 0)" "2"
    utest::assert_equal "$(math::add 1 1.5000001 0)" "3"
    utest::assert_equal "$(math::add 1 2)" "3"
    utest::assert_equal "$(math::add 1 1.2222 2)" "2.22"
    utest::assert_equal "$(math::add -3 4.567)" "1.567"
    utest::assert_equal "$(math::add -6 -2.01)" "-8.01"
}

function TEST::math::sub() {
    utest::assert_equal "$(math::sub 1.4 1 0)" "0"
    utest::assert_equal "$(math::sub 3 1.5 0)" "2"
    utest::assert_equal "$(math::sub 3 1.5000001 0)" "1"
    utest::assert_equal "$(math::sub 1 2)" "-1"
    utest::assert_equal "$(math::sub 1 1.2222 2)" "-0.22"
    utest::assert_equal "$(math::sub -3 4.567)" "-7.567"
    utest::assert_equal "$(math::sub -6 -2.01)" "-3.99"
}

function TEST::math::mul() {
    utest::assert_equal "$(math::mul 1 1.4 0)" "1"
    utest::assert_equal "$(math::mul 1 1.5 0)" "2"
    utest::assert_equal "$(math::mul 1 1.5000001 0)" "2"
    utest::assert_equal "$(math::mul 2 0)" "0"
    utest::assert_equal "$(math::mul 1 2)" "2"
    utest::assert_equal "$(math::mul 2 1.2222 2)" "2.44"
    utest::assert_equal "$(math::mul -3 3.33)" "-9.99"
    utest::assert_equal "$(math::mul -1 3.449 2)" "-3.45"
    utest::assert_equal "$(math::mul -3 3.333 2)" "-10.00"
    utest::assert_equal "$(math::mul -3 3.333)" "-9.999"
    utest::assert_equal "$(math::mul -6 -2.01)" "12.06"
}

function TEST::math::div() {
    utest::assert_equal "$(math::div 1 2 0)" "0"
    utest::assert_equal "$(math::div 2 3 0)" "1"
    utest::assert_equal "$(math::div 4 3 0)" "1"
    utest::assert_equal "$(math::div 1 2 2)" "0.50"
    utest::assert_equal "$(math::div 1 3 2)" "0.33"
    utest::assert_equal "$(math::div 1 3 3)" "0.333"
    utest::assert_equal "$(math::div 6 2 2)" "3.00"

    utest::assert_equal "$(math::div 1.5 2)" "0.75"
    utest::assert_equal "$(math::div 1.5 2.0)" "0.75"
    utest::assert_equal "$(math::div 1.5 2.2 2)" "0.68"
    utest::assert_equal "$(math::div 1.5 2.6 2)" "0.58"
    utest::assert_equal "$(math::div 1.5 "$((2 * 3))")" "0.25"
}

function TEST::math::abs() {
    utest::assert_equal "$(math::abs 0)" "0"
    utest::assert_equal "$(math::abs -1)" "1"
    utest::assert_equal "$(math::abs -1)" "1"
    utest::assert_equal "$(math::abs 1.5)" "1.5"
    utest::assert_equal "$(math::abs -1.5)" "1.5"
}

function TEST::math::rand() {
    local res

    utest::assert_equal "$(math::rand 0 0)" "0"
    utest::assert_equal "$(math::rand 1 1)" "1"

    for ((i = 0; i < 100; i++)); do
        res="$(math::rand 1 10)"
        if [[ "$res" -le 10 ]] && [[ "$res" -gt 1 ]]; then
            utest::assert "$SHELL_TRUE"
        else
            utest::assert_fail "$SHELL_FALSE" "$res is not in [1, 10]"
        fi
    done
}

function TEST::math::sqrt() {
    utest::assert_equal "$(math::sqrt 4)" "2"
    utest::assert_equal "$(math::sqrt 8)" "2.82843"
    utest::assert_equal "$(math::sqrt 9)" "3"
    utest::assert_equal "$(math::sqrt 16)" "4"
}

function TEST::math::sin_by_degree() {
    utest::assert_equal "$(math::sin_by_degree 0)" "0"
    utest::assert_equal "$(math::sin_by_degree 30)" "0.5"
    utest::assert_equal "$(math::sin_by_degree 45)" "0.707107"
    utest::assert_equal "$(math::sin_by_degree 60)" "0.866025"
    utest::assert_equal "$(math::sin_by_degree 90)" "1"
}

function TEST::math::cos_by_degree() {
    utest::assert_equal "$(math::cos_by_degree 0)" "1"
    utest::assert_equal "$(math::cos_by_degree 30)" "0.866025"
    utest::assert_equal "$(math::cos_by_degree 45)" "0.707107"
    utest::assert_equal "$(math::cos_by_degree 60)" "0.5"
    utest::assert_equal "$(math::cos_by_degree 90)" "6.12323e-17"
}
