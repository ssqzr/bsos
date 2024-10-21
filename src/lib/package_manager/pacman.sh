#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_f4b9a5da="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_f4b9a5da}/../utils/all.sh"

function package_manager::pacman::is_installed() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    pacman -Q "$package" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::pacman::install() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    if package_manager::pacman::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_retry_three cmd::run_cmd_with_history -- sudo pacman -S --needed --noconfirm "$package" || return "$SHELL_FALSE"
}

function package_manager::pacman::uninstall() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    if ! package_manager::pacman::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history -- sudo pacman -Rc --noconfirm "$@" || return "$SHELL_FALSE"
}

function package_manager::pacman::package_description() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    local description
    description=$(LANG=c pacman -Si "$package" | grep Description | awk -F ':' '{print $2}')
    string::trim "$description" || return "$SHELL_FALSE"
}

function package_manager::pacman::upgrade() {
    local app="$1"

    if [ -z "$app" ]; then
        cmd::run_cmd_with_history -- sudo pacman -Su --noconfirm || return "$SHELL_FALSE"
    else
        cmd::run_cmd_with_history -- sudo pacman -S --needed --noconfirm "$app" || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function package_manager::pacman::update() {
    cmd::run_cmd_with_history -- sudo pacman -Sy --noconfirm || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
