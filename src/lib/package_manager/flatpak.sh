#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28000550="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28000550}/../utils/all.sh"

function package_manager::flatpak::is_installed() {
    local package="$1"
    flatpak info "$package" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::flatpak::install() {
    local package="$1"

    if package_manager::flatpak::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history sudo flatpak install -y "$package" || return "$SHELL_FALSE"
}

function package_manager::flatpak::uninstall() {
    local package="$1"
    if ! package_manager::flatpak::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history sudo flatpak uninstall -y "$package" || return "$SHELL_FALSE"
}

function package_manager::flatpak::package_description() {
    local name="$1"
    local description
    description=$(LANG=c flatpak remote-info flathub "$name" | sed -n '2p')
    string::trim "$description" || return "$SHELL_FALSE"
}

function package_manager::flatpak::upgrade() {
    cmd::run_cmd_with_history sudo flatpak update -y || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
