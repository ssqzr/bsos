#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_6dc1efee="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_6dc1efee}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_6dc1efee}/pacman.sh"

function package_manager::pamac::is_installed() {
    local package="$1"
    pacman::is_installed "$package" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::pamac::install() {
    local package="$1"

    if package_manager::pamac::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history pamac install --no-confirm "$package" || return "$SHELL_FALSE"
}

function package_manager::pamac::uninstall() {
    local package="$1"

    if ! package_manager::pamac::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history pamac remove --cascade --no-confirm "$package" || return "$SHELL_FALSE"
}

function package_manager::pamac::package_description() {
    local name="$1"
    local description
    description=$(LANG=c pamac info "$name" | grep Description | awk -F ':' '{print $2}')
    string::trim "$description" || return "$SHELL_FALSE"
}

function package_manager::pamac::upgrade() {
    cmd::run_cmd_with_history pamac upgrade --no-confirm --aur || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
