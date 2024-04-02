#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_00577440="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_00577440}/debug.sh"

function unit_test::assert_equal() {
    local left="$1"
    local right="$2"
    local caller_frame
    caller_frame=$(get_caller_frame 1)

    if [ "$left" != "$right" ]; then
        printf_info "$caller_frame"
        println_error " failed"
        println_error "left: $left, right: $right"
        return "$SHELL_FALSE"
    fi
    printf_info "$caller_frame"
    println_success " success"

    return "$SHELL_TRUE"
}

function unit_test::assert() {
    local left="$1"
    local caller_frame
    caller_frame=$(get_caller_frame 1)

    if [ "$left" != "$SHELL_TRUE" ]; then
        printf_info "$caller_frame"
        println_error " failed, assert failed"
        return "$SHELL_FALSE"
    fi

    printf_info "$caller_frame"
    println_success " success"
    return "$SHELL_TRUE"
}

function unit_test::assert_fail() {
    local left="$1"
    local caller_frame
    caller_frame=$(get_caller_frame 1)

    if [ "$left" = "$SHELL_TRUE" ]; then
        printf_info "$caller_frame"
        println_error " failed, assert failed"
        return "$SHELL_FALSE"
    fi

    printf_info "$caller_frame"
    println_success " success"
    return "$SHELL_TRUE"
}
