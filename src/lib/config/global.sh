#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d8d5b6c2="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_d8d5b6c2}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_d8d5b6c2}/yaml/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_d8d5b6c2}/yaml/map.sh"

if [ -z "${__config_filepath}" ]; then
    lerror "env __config_filepath is empty"
    exit 1
fi

function config::global::has_pre_installed::set_true() {
    config::map::set ".global" "has_pre_installed" "true" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::has_pre_installed::set_false() {
    config::map::set ".global" "has_pre_installed" "false" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::has_pre_installed::get() {
    local value
    value=$(config::map::get ".global" "has_pre_installed" "${__config_filepath}") || return "$SHELL_FALSE"
    if string::is_true "$value"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function config::global::data_root_directory::set() {
    local data_root_directory="$1"
    config::map::set ".global" "data_root_directory" "${data_root_directory}" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::data_root_directory::get() {
    local value
    value=$(config::map::get ".global" "data_root_directory" "${__config_filepath}") || return "$SHELL_FALSE"
    echo "$value"
    return "$SHELL_FALSE"
}
