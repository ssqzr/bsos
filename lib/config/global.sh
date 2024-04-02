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

function config::global::map::get() {
    local key="$1"
    local value
    value=$(config::map::get ".global" "${key}" "${__config_filepath}") || return "$SHELL_FALSE"
    echo "$value"
}

function config::global::map::set() {
    local key="$1"
    local value="$2"
    config::map::set ".global" "${key}" "${value}" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::has_pre_installed::set_true() {
    config::global::map::set "has_pre_installed" "true" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::has_pre_installed::set_false() {
    config::global::map::set "has_pre_installed" "false" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::has_pre_installed::get() {
    local value
    value=$(config::global::map::get "has_pre_installed") || return "$SHELL_FALSE"
    if string::is_true "$value"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function config::global::pre_install_apps::clear() {
    config::array::clear ".global.pre_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::pre_install_apps::rpush_unique() {
    local app="$1"
    config::array::rpush_unique ".global.pre_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::pre_install_apps::is_contain() {
    local app="$1"
    config::array::is_contain ".global.pre_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::global::installed_apps::clear() {
    config::array::clear ".global.installed_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::installed_apps::rpush() {
    local app="$1"
    config::array::rpush ".global.installed_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::installed_apps::rpop() {
    config::array::rpop ".global.installed_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::installed_apps::last() {
    config::array::last ".global.installed_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::installed_apps::remove() {
    local app="$1"
    config::array::remove ".global.installed_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::get() {
    config::array::get ".global.top_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::clear() {
    config::array::clear ".global.top_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::lpush() {
    local app="$1"
    config::array::lpush ".global.top_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::rpush() {
    local app="$1"
    config::array::rpush ".global.top_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::lpop() {
    config::array::lpop ".global.top_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::rpop() {
    config::array::rpop ".global.top_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::first() {
    config::array::first ".global.top_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::last() {
    config::array::last ".global.top_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::global::top_install_apps::remove() {
    local app="$1"
    config::array::remove ".global.top_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}
