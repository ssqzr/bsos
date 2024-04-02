#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_e71f95ee="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e71f95ee}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_e71f95ee}/yaml/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_e71f95ee}/yaml/map.sh"

if [ -z "${__config_filepath}" ]; then
    lerror "env __config_filepath is empty"
    exit 1
fi

function config::app::map::get() {
    local app_name="$1"
    local key="$2"
    local value

    value=$(config::map::get ".apps.[\"${app_name}\"]" "${key}" "${__config_filepath}") || return "$SHELL_FALSE"
    echo "$value"
}

function config::app::map::set() {
    local app_name="$1"
    local key="$2"
    local value="$3"
    config::map::set ".apps.[\"${app_name}\"]" "${key}" "${value}" "${__config_filepath}" || return "$SHELL_FALSE"
}

# is_configed 标记是否已经配置了，也就是运行了安装向导
function config::app::is_configed::set_true() {
    local app_name="$1"
    config::app::map::set "$app_name" "is_configed" "true" || return "$SHELL_FALSE"
}

function config::app::is_configed::set_false() {
    local app_name="$1"
    config::app::map::set "$app_name" "is_configed" "false" || return "$SHELL_FALSE"
}

function config::app::is_configed::get() {
    local app_name="$1"
    local value
    value=$(config::app::map::get "$app_name" "is_configed") || return "$SHELL_FALSE"
    if string::is_true "$value"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}
