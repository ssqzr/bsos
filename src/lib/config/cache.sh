#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_e85fa6af="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e85fa6af}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_e85fa6af}/yaml/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_e85fa6af}/yaml/map.sh"

if [ -z "${__config_filepath}" ]; then
    lerror "env __config_filepath is empty"
    exit 1
fi

function config::cache::delete() {
    config::map::delete_key "." "cache" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::is_exists() {
    config::map::has_key "." "cache" "${__config_filepath}"
}

################################################### global 相关 ############################################

function config::cache::has_pre_installed::set_true() {
    config::map::set ".cache" "has_pre_installed" "true" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::has_pre_installed::set_false() {
    config::map::set ".cache" "has_pre_installed" "false" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::has_pre_installed::get() {
    local value
    value=$(config::map::get ".cache" "has_pre_installed") || return "$SHELL_FALSE"
    if string::is_true "$value"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function config::cache::pre_install_apps::clean() {
    config::array::clean ".cache.pre_install_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::pre_install_apps::rpush_unique() {
    local app="$1"
    config::array::rpush_unique ".cache.pre_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::pre_install_apps::is_contain() {
    local app="$1"
    config::array::is_contain ".cache.pre_install_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::installed_apps::clean() {
    config::array::clean ".cache.installed_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::installed_apps::is_contain() {
    local app="$1"
    config::array::is_contain ".cache.installed_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::installed_apps::rpush() {
    local app="$1"
    config::array::rpush ".cache.installed_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::uninstalled_apps::clean() {
    config::array::clean ".cache.uninstalled_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::uninstalled_apps::is_contain() {
    local app="$1"
    config::array::is_contain ".cache.uninstalled_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::uninstalled_apps::rpush() {
    local app="$1"
    config::array::rpush ".cache.uninstalled_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::top_apps::get() {
    config::array::get ".cache.top_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::top_apps::clean() {
    config::array::clean ".cache.top_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::top_apps::rpush() {
    local app="$1"
    config::array::rpush ".cache.top_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

################################################### APP 相关 ############################################

function config::cache::app::dependencies::is_exists() {
    local pm_app="$1"
    config::map::has_key ".cache.apps.[\"${pm_app}\"]" "dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::delete() {
    local pm_app="$1"
    config::map::delete_key ".cache.apps.[\"${pm_app}\"]" "dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::clean() {
    local pm_app="$1"
    config::array::clean ".cache.apps.[\"${pm_app}\"].dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::is_contain() {
    local pm_app="$1"
    local dependency="$2"
    config::array::is_contain ".cache.apps.[\"${pm_app}\"].dependencies" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::rpush_unique() {
    local pm_app="$1"
    local dependency="$2"
    config::array::rpush_unique ".cache.apps.[\"${pm_app}\"].dependencies" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::get() {
    local pm_app="$1"
    config::array::get ".cache.apps.[\"${pm_app}\"].dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::as_dependencies::is_exists() {
    local pm_app="$1"
    config::map::has_key ".cache.apps.[\"${pm_app}\"]" "as_dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::as_dependencies::delete() {
    local pm_app="$1"
    config::map::delete_key ".cache.apps.[\"${pm_app}\"]" "as_dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::as_dependencies::clean() {
    local pm_app="$1"
    config::array::clean ".cache.apps.[\"${pm_app}\"].as_dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::as_dependencies::is_contain() {
    local pm_app="$1"
    local dependency="$2"
    config::array::is_contain ".cache.apps.[\"${pm_app}\"].as_dependencies" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::as_dependencies::rpush_unique() {
    local pm_app="$1"
    local dependency="$2"
    config::array::rpush_unique ".cache.apps.[\"${pm_app}\"].as_dependencies" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::as_dependencies::get() {
    local pm_app="$1"
    config::array::get ".cache.apps.[\"${pm_app}\"].as_dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
