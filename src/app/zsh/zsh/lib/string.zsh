#!/bin/zsh

# 字符串操作相关的工具

source "${0:A:h}/constant.zsh"

function string::trim() {
    local str="$1"
    echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function is_string_true() {
    local data="$1"
    if [ x"$data" = x"y" -o x"$data" = x"Y" ]; then
        return $SHELL_TRUE
    fi

    echo $data | grep -i -E "^yes$" 1>/dev/null
    if [ $? -eq $SHELL_TRUE ]; then
        return $SHELL_TRUE
    fi

    echo $data | grep -i -E "^true$" 1>/dev/null
    if [ $? -eq $SHELL_TRUE ]; then
        return $SHELL_TRUE
    fi

    if [ x"$data" = x"1" ]; then
        return $SHELL_TRUE
    fi

    return $SHELL_FALSE
}

function string::is_false() {
    local data="$1"
    data=$(string::trim "$data")

    if [ "$data" = "n" ] || [ "$data" = "N" ]; then
        return "$SHELL_TRUE"
    fi

    echo "$data" | grep -i -E "^no$" 1>/dev/null
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    echo "$data" | grep -i -E "^false$" 1>/dev/null
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    if [ "$data" = "0" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function string::is_true_or_false() {
    local data="$1"

    if string::is_true "$data" || string::is_false "$data"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function print_yes_no() {
    local boolean="$1"

    if [ -z $boolean ]; then
        echo "no"
        return
    fi

    if [ $boolean -eq $SHELL_TRUE ]; then
        echo "yes"
        return
    fi
    echo "no"
}
