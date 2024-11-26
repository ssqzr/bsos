#!/bin/bash

if [ -n "${SCRIPT_DIR_1319e232}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1319e232="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1319e232}/../lib/utils/all.sh" || exit 1

declare __flags=()

function manager::flags::append() {
    local flag="$1"

    array::is_contain __flags "$flag" && return "${SHELL_TRUE}"

    __flags+=("$flag")
    return "${SHELL_TRUE}"
}

function manager::flags::is_exists() {
    local flag="$1"
    array::is_contain __flags "$flag" && return "${SHELL_TRUE}"
    return "${SHELL_FALSE}"
}

function manager::flags::reuse_cache::add() {
    local flag="reuse_cache"
    manager::flags::append "$flag" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function manager::flags::reuse_cache::is_exists() {
    local flag="reuse_cache"
    manager::flags::is_exists "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flags::reuse_cache::is_not_exists() {
    ! manager::flags::reuse_cache::is_exists "$@"
}

function manager::flags::check_loop::add() {
    local flag="check_loop"
    manager::flags::append "$flag" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function manager::flags::check_loop::is_exists() {
    local flag="check_loop"
    manager::flags::is_exists "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flags::check_loop::is_not_exists() {
    ! manager::flags::check_loop::is_exists "$@"
}

function manager::flags::develop::add() {
    local flag="develop"
    manager::flags::append "$flag" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function manager::flags::develop::is_exists() {
    local flag="develop"
    manager::flags::is_exists "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flags::develop::is_not_exists() {
    ! manager::flags::develop::is_exists "$@"
}

function manager::flags::continue_after_guide::add() {
    local flag="continue_after_guide"
    manager::flags::append "$flag" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function manager::flags::continue_after_guide::is_exists() {
    local flag="continue_after_guide"
    manager::flags::is_exists "$flag" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::flags::continue_after_guide::is_not_exists() {
    ! manager::flags::continue_after_guide::is_exists "$@"
}
