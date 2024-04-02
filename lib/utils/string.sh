#!/bin/bash

# 字符串操作相关的工具

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_c5f5ae0d="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_c5f5ae0d}/constant.sh"

function string::is_true() {
    local data="$1"
    if [ "$data" = "y" ] || [ "$data" = "Y" ]; then
        return "$SHELL_TRUE"
    fi

    echo "$data" | grep -i -E "^yes$" 1>/dev/null
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    echo "$data" | grep -i -E "^true$" 1>/dev/null
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    if [ "$data" = "1" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function string::is_false() {
    local data="$1"
    string::is_true "$data"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
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

# 去掉字符串两边的空格
function string::trim() {
    local str="$1"
    echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}
