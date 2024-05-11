#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1319e232="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1319e232}/../lib/utils/all.sh" || exit 1

function manager::flags::append() {
    local -n _1142f83e_flags="$1"
    local flag="$2"
    echo "${_1142f83e_flags}" | grep -q "$flag"
    if [ $? -ne "$SHELL_TRUE" ]; then
        _1142f83e_flags+="|$flag"
    fi
    return "${SHELL_TRUE}"
}

function manager::flags::is_exists() {
    local flags="$1"
    local flag="$2"
    echo "${flags}" | grep -q "$flag"
    if [ $? -ne "$SHELL_TRUE" ]; then
        return "${SHELL_FALSE}"
    fi
    return "${SHELL_TRUE}"
}

function manager::flags::reuse_cache::add() {
    local -n _0921d972_flags="$1"
    local flag="reuse_cache"
    manager::flags::append "${!_0921d972_flags}" "$flag"
    return "${SHELL_TRUE}"
}

function manager::flags::reuse_cache::is_exists() {
    local flags="$1"
    local flag="reuse_cache"
    manager::flags::is_exists "$flags" "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flags::check_loop::add() {
    local -n _6053aede_flags="$1"
    local flag="check_loop"
    manager::flags::append "${!_6053aede_flags}" "$flag"
    return "${SHELL_TRUE}"
}

function manager::flags::check_loop::is_exists() {
    local flags="$1"
    local flag="check_loop"
    manager::flags::is_exists "$flags" "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flags::develop::add() {
    local -n _d001771b_flags="$1"
    local flag="develop"
    manager::flags::append "${!_d001771b_flags}" "$flag"
    return "${SHELL_TRUE}"
}

function manager::flags::develop::is_exists() {
    local flags="$1"
    local flag="develop"
    manager::flags::is_exists "$flags" "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
