#!/bin/bash

if [ -n "${SCRIPT_DIR_7848df84}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_7848df84="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_7848df84}/constant.sh"

function float::div() {
    local dividend="$1"
    shift
    local divisor="$1"
    shift
    local accuracy="$1"
    shift

    local result

    accuracy="${accuracy:-2}"

    if [ "$divisor" = "0" ]; then
        lerror "the divisor cannot be 0"
        return "$SHELL_FALSE"
    fi

    result=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${dividend} / ${divisor})}")

    echo "$result"
    return "$SHELL_TRUE"
}

function TEST::float::div() {
    utest::assert_equal "$(float::div 1 2)" "0.50"
    utest::assert_equal "$(float::div 1 3)" "0.33"
    utest::assert_equal "$(float::div 1 3 3)" "0.333"
    utest::assert_equal "$(float::div 6 2)" "3.00"

    utest::assert_equal "$(float::div 1.5 2)" "0.75"
    utest::assert_equal "$(float::div 1.5 2.0)" "0.75"
    utest::assert_equal "$(float::div 1.5 2.2)" "0.68"
    utest::assert_equal "$(float::div 1.5 2.6)" "0.58"
    utest::assert_equal "$(float::div 1.5 "$((2 * 3))")" "0.25"
}
