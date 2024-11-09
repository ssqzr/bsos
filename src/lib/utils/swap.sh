#!/bin/bash

if [ -n "${SCRIPT_DIR_a19558a7}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_a19558a7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_a19558a7}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a19558a7}/log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a19558a7}/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a19558a7}/cmd.sh"

function swap::all() {
    # shellcheck disable=SC2034
    local -n swaps_3ce2202a="$1"
    shift
    local temp_str
    temp_str=$(swapon --show=NAME --noheadings) || return "${SHELL_FALSE}"
    array::readarray swaps_3ce2202a <<<"$temp_str"
    return "${SHELL_TRUE}"
}

function swap::is_enabled() {
    local temp_str
    temp_str=$(swapon --show=NAME --noheadings) || return "${SHELL_FALSE}"
    if string::is_empty "${temp_str}"; then
        return "${SHELL_FALSE}"
    fi
    return "${SHELL_TRUE}"
}

function swap::is_exists() {
    local name="$1"
    shift

    swapon --show=NAME --noheadings | grep -wq "${name}"
    if [ "${?}" -ne "${SHELL_TRUE}" ]; then
        return "${SHELL_FALSE}"
    fi
    return "${SHELL_TRUE}"
}

function swap::is_not_exists() {
    ! swap::is_exists "$@"
}

function swap::size_byte() {
    local name="$1"
    shift

    local size_byte

    if swap::is_not_exists "${name}"; then
        lerror "swap ${name} is not exists"
        return "${SHELL_FALSE}"
    fi

    size_byte=$(swapon --show=NAME,SIZE --noheadings | grep -w "${name}" | awk '{print $2}')
    size_byte=$(string::trim "${size_byte}") || return "${SHELL_FALSE}"

    echo "${size_byte}"
    return "${SHELL_TRUE}"
}

function swap::type() {
    local name="$1"
    shift

    local swap_type

    if swap::is_not_exists "${name}"; then
        lerror "swap ${name} is not exists"
        return "${SHELL_FALSE}"
    fi

    swap_type=$(swapon --show=NAME,TYPE --noheadings | grep -w "${name}" | awk '{print $2}')
    swap_type=$(string::trim "${swap_type}") || return "${SHELL_FALSE}"

    echo "${swap_type}"
    return "${SHELL_TRUE}"
}

function swap::swapon() {
    local name="$1"
    shift

    cmd::run_cmd_with_history --sudo -- swapon "${name}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function swap::swapoff() {
    local name="$1"
    shift

    cmd::run_cmd_with_history --sudo -- swapoff "${name}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function swap::make_swapfile() {
    local filepath="$1"
    shift
    local size_byte="$1"
    shift

    # -U clear 的解释：UUID 适用于分区，而不是文件，所以创建 swap 文件不需要 UUID
    cmd::run_cmd_with_history --sudo -- mkswap -U clear --size "${size_byte}" --file "${filepath}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}
