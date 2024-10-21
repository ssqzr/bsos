#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_6dc1efee="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_6dc1efee}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6dc1efee}/pacman.sh"

function package_manager::pamac::is_installed() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::pacman::is_installed "$package" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::pamac::install() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    if package_manager::pamac::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_retry_three cmd::run_cmd_with_history -- pamac install --no-confirm "$package" || return "$SHELL_FALSE"
}

function package_manager::pamac::uninstall() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    if ! package_manager::pamac::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history -- pamac remove --cascade --no-confirm "$package" || return "$SHELL_FALSE"
}

function package_manager::pamac::package_description() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    local description
    description=$(LANG=c pamac info "$package" | grep Description | awk -F ':' '{print $2}')
    string::trim "$description" || return "$SHELL_FALSE"
}

function package_manager::pamac::upgrade() {
    local app="$1"

    if [ -z "$app" ]; then
        cmd::run_cmd_with_history -- pamac upgrade --no-refresh --no-confirm --aur || return "$SHELL_FALSE"
    else
        cmd::run_cmd_with_history -- pamac upgrade --no-refresh --no-confirm "$app" || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function package_manager::pamac::update() {
    # pamac 没有单独更新数据库的命令，pamac 的 update 和 upgrade 命令是一样的
    # cmd::run_cmd_with_history -- pamac update --no-confirm --download-only || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
