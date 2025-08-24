#!/bin/bash

if [ -n "${SCRIPT_DIR_2d0164bc}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_2d0164bc="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_2d0164bc}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2d0164bc}/log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2d0164bc}/string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2d0164bc}/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2d0164bc}/cmd.sh"

function mkinitcpio::filepath(){
    echo "/etc/mkinitcpio.conf"
    return "${SHELL_TRUE}"
}



function mkinitcpio::make_config() {
    cmd::run_cmd_with_history --sudo -- mkinitcpio -P || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function mkinitcpio::get_option_list(){
    local -n option_list_2b8f18b9="$1"
    shift
    local option_name_2b8f18b9="$1"
    shift

    local config_filepath_2b8f18b9
    local temp_str_2b8f18b9

    config_filepath_2b8f18b9="$(mkinitcpio::filepath)" || return "${SHELL_FALSE}"

    temp_str_2b8f18b9="$(grep "^${option_name_2b8f18b9}=" "${config_filepath_2b8f18b9}")" || return "${SHELL_FALSE}"
    temp_str_2b8f18b9="${temp_str_2b8f18b9#"${option_name_2b8f18b9}=("}"
    temp_str_2b8f18b9="${temp_str_2b8f18b9%")"}"

    linfo "current mkinitcpio ${option_name_2b8f18b9}=$temp_str_2b8f18b9"

    string::split_with "${!option_list_2b8f18b9}" "$temp_str_2b8f18b9" || return "${SHELL_FALSE}"
}

function mkinitcpio::hooks::list(){
    local -n hooks_array_478ef979="$1"

    mkinitcpio::get_option_list "${!hooks_array_478ef979}" "HOOKS" || return "${SHELL_FALSE}"
}

function mkinitcpio::hooks::add() {
    local module="$1"
    shift
    local index="$1"
    shift

    local config_filepath
    local hooks=()

    if string::is_empty "$module"; then
        lerror "param module is empty"
        return "${SHELL_FALSE}"
    fi

    if string::is_empty "$index"; then
        index="-1"
    fi

    config_filepath="$(mkinitcpio::filepath)" || return "${SHELL_FALSE}"

    mkinitcpio::hooks::list hooks || return "${SHELL_FALSE}"

    if array::is_contain hooks "$module"; then
        linfo "$module hook has already been added, do not add again"
        return "${SHELL_TRUE}"
    fi

    if [ "$index" -eq "-1" ]; then
        linfo "inset $module hook at the end"
        array::rpush hooks "$module" || return "${SHELL_FALSE}"
    else
        linfo "insert $module hook at index=$index"
        array::insert hooks "$index" "$module" || return "${SHELL_FALSE}"
    fi

    cmd::run_cmd_with_history --sudo -- sed -i -e "'s/^HOOKS=(.*)$/HOOKS=(${hooks[*]})/'" "${config_filepath}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function mkinitcpio::hooks::remove() {
    local module="$1"
    local config_filepath
    local hooks=()

    if string::is_empty "$module"; then
        lerror "param module is empty"
        return "${SHELL_FALSE}"
    fi

    config_filepath="$(mkinitcpio::filepath)" || return "${SHELL_FALSE}"
    
    mkinitcpio::hooks::list hooks || return "${SHELL_FALSE}"

    if array::is_not_contain hooks "$module"; then
        linfo "$module hook is not added, do not remove"
        return "${SHELL_TRUE}"
    fi

    array::remove hooks "$module" || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history --sudo -- sed -i -e "'s/^HOOKS=(.*)$/HOOKS=(${hooks[*]})/'" "${config_filepath}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}