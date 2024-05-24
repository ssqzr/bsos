#!/bin/bash

if [ -n "${SCRIPT_DIR_09c3f3fc}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_09c3f3fc="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_09c3f3fc}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_09c3f3fc}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_09c3f3fc}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_09c3f3fc}/../utest.sh" || exit 1

function log::utils::create_dir_recursive() {
    local dir="$1"
    if [ -z "$dir" ]; then
        return "$SHELL_FALSE"
    fi

    mkdir -p "$dir" >/dev/null 2>&1
    if [ $? -ne "$SHELL_TRUE" ]; then
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function log::utils::create_parent_directory() {
    local filepath="$1"
    local parent_dir
    parent_dir="$(dirname "${filepath}")" || return "$SHELL_FALSE"
    log::utils::create_dir_recursive "$parent_dir" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
