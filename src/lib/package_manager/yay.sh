#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b21bf293="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_b21bf293}/../utils/all.sh"

function package_manager::yay::is_installed() {
    local package="$1"
    yay -Q "$package" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::yay::install() {
    local package="$1"

    if package_manager::yay::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    local install_cmd="yay -S --needed --noconfirm"

    cmd::run_cmd_retry_three cmd::run_cmd_with_history "$install_cmd" "$package" || return "$SHELL_FALSE"
}

function package_manager::yay::uninstall() {
    local package="$1"

    if ! package_manager::yay::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    local remove_cmd="yay -Rc --unneeded --noconfirm"

    cmd::run_cmd_with_history "$remove_cmd" "$@" || return "$SHELL_FALSE"
}

function package_manager::yay::package_description() {
    local name="$1"
    local description
    description=$(LANG=c yay -Si "$name" | grep Description | awk -F ':' '{print $2}')
    string::trim "$description" || return "$SHELL_FALSE"
}

function package_manager::yay::upgrade() {
    cmd::run_cmd_with_history yay -Syu --noconfirm || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
