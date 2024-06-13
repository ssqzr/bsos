#!/bin/bash

if [ -n "${SCRIPT_DIR_1b05c547}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1b05c547="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1b05c547}/../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1b05c547}/../../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1b05c547}/../../string.sh"

function cfg::trait::json::init() {
    which yq >/dev/null 2>&1
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "yq not found"
        lexit "$CODE_COMMAND_NOT_FOUND"
    fi
    return "${SHELL_TRUE}"
}

function cfg::trait::json::map::get() {
    local key="$1"
    shift
    local data="$1"
    shift

    echo "$data" | VAL="${key}" yq ".[strenv(VAL)]" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function cfg::trait::json::array::length() {
    local data="$1"
    shift
    local length

    length=$(echo "$data" | yq ". | length" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get array length failed, err=${length}, data=${data}"
        return "$SHELL_FALSE"
    fi
    echo "$length"
    return "$SHELL_TRUE"
}

function cfg::trait::json::array::first() {
    local data="$1"
    shift

    local length
    local res

    length=$(cfg::trait::json::array::length "$data") || return "$SHELL_FALSE"

    if [ "$length" == "0" ]; then
        # 没有元素了
        return "$SHELL_TRUE"
    fi

    res=$(echo "$data" | yq ".[0]" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array get first item failed, err=${res}, data=${data}"
        return "$SHELL_FALSE"
    fi
    echo "$res"

    return "${SHELL_TRUE}"
}

function cfg::trait::json::array::last() {
    local data="$1"
    shift

    local length
    local res

    length=$(cfg::trait::json::array::length "$data") || return "$SHELL_FALSE"

    if [ "$length" == "0" ]; then
        # 没有元素了
        return "$SHELL_TRUE"
    fi

    res=$(echo "$data" | yq ".[-1]" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array get last item failed, err=${res}, data=${data}"
        return "$SHELL_FALSE"
    fi

    echo "$res"

    return "${SHELL_TRUE}"
}

function cfg::trait::json::array::index() {
    local index="$1"
    shift
    local data="$1"
    shift

    local length
    local res

    length=$(cfg::trait::json::array::length "$data") || return "$SHELL_FALSE"

    if [ "$index" -lt "0" ]; then
        lerror "index is less than 0"
        return "$SHELL_FALSE"
    fi

    if [ "$index" -ge "$length" ]; then
        lerror "index is out of range, index=${index}, length=${length}"
        return "$SHELL_FALSE"
    fi

    if [ "$length" == "0" ]; then
        # 没有元素了
        lerror "array is empty"
        return "$SHELL_FALSE"
    fi

    res=$(echo "$data" | yq ".[${index}]" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array get index item failed, err=${res}, index=${index}, data=${data}"
        return "$SHELL_FALSE"
    fi

    echo "$res"

    return "${SHELL_TRUE}"
}

function cfg::trait::json::array::filter_by_key_value() {
    local key="$1"
    shift
    local value="$1"
    shift
    local data="$1"
    shift

    local res

    res=$(echo "$data" | KEY="${key}" VALUE="${value}" yq "filter(.[strenv(KEY)] == strenv(VALUE))" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array filter item by key and value failed, err=${res}, key=${key}, value=${value}, data=${data}"
        return "$SHELL_FALSE"
    fi

    echo "$res"

    return "${SHELL_TRUE}"
}

cfg::trait::json::init
