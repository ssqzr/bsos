#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_f4b9a5da="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_f4b9a5da}/../utils/all.sh"

function pacman::is_installed() {
    local package="$1"
    pacman -Q "$package" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::pacman::install() {
    local package="$1"

    if pacman::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    local install_cmd="pacman -S --needed --noconfirm"

    cmd::run_cmd_with_history sudo "$install_cmd" "$package" || return "$SHELL_FALSE"
}

function package_manager::pacman::uninstall() {
    local package="$1"

    if ! pacman::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    local remove_cmd="pacman -R --noconfirm"

    cmd::run_cmd_with_history sudo "$remove_cmd" "$@" || return "$SHELL_FALSE"
}

function package_manager::pacman::package_description() {
    local name="$1"
    local description
    description=$(LANG=c pacman -Si "$name" | grep Description | awk -F ':' '{print $2}')
    string::trim "$description" || return "$SHELL_FALSE"
}

function package_manager::pacman::upgrade() {
    cmd::run_cmd_with_history sudo pacman -Syu --noconfirm || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
