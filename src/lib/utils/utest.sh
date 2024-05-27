#!/bin/bash

if [ -n "${SCRIPT_DIR_00577440}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_00577440="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_00577440}/debug.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_00577440}/print.sh"

declare UTEST_RESULT_FAILED="failed"
declare UTEST_RESULT_SUCCESS="success"

function utest::printf_result() {
    local result="$1"
    case "$result" in
    "$UTEST_RESULT_FAILED")
        printf_error --format="%-10s" "$result"
        ;;
    "$UTEST_RESULT_SUCCESS")
        printf_success --format="%-10s" "$result"
        ;;
    *)
        printf_info --format="%-10s" "$result"
        ;;
    esac
}

function utest::printf_function() {
    local filename
    local line_num
    local function_name
    filename=$(debug::function::filename 2)
    line_num=$(debug::function::line_number 2)
    function_name=$(debug::function::name 2)
    printf_info --format="%-100s" "$filename:$line_num -> $function_name"
}

function utest::assert_equal() {
    local left="$1"
    local right="$2"

    utest::printf_function

    if [ "$left" != "$right" ]; then
        utest::printf_result "$UTEST_RESULT_FAILED"
        println_info ""
        printf_error --format="%11s" "left: "
        println_error "$left"
        printf_error --format="%11s" "right: "
        println_error "$right"
        return "$SHELL_FALSE"
    fi

    utest::printf_result "$UTEST_RESULT_SUCCESS"
    println_info ""

    return "$SHELL_TRUE"
}

function utest::assert() {
    local is_true="$1"
    local message="$2"

    utest::printf_function

    if [ "$is_true" != "$SHELL_TRUE" ]; then
        utest::printf_result "$UTEST_RESULT_FAILED"
        println_error "$message"
        return "$SHELL_FALSE"
    fi

    utest::printf_result "$UTEST_RESULT_SUCCESS"
    println_info ""
    return "$SHELL_TRUE"
}

function utest::assert_fail() {
    local is_false="$1"
    local message="$2"

    utest::printf_function

    if [ "$is_false" = "$SHELL_TRUE" ]; then
        utest::printf_result "$UTEST_RESULT_FAILED"
        println_error "$message"
        return "$SHELL_FALSE"
    fi

    utest::printf_result "$UTEST_RESULT_SUCCESS"
    println_info ""
    return "$SHELL_TRUE"
}
