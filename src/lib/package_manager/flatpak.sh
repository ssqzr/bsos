#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28000550="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28000550}/../utils/all.sh"

function package_manager::flatpak::is_installed() {
    local package="$1"
    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    flatpak info "$package" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::flatpak::install() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    if package_manager::flatpak::is_installed "$package"; then
        ldebug "package($package) is already installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_retry_three cmd::run_cmd_with_history --sudo -- flatpak install -y "$package" || return "$SHELL_FALSE"
}

function package_manager::flatpak::uninstall() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    if ! package_manager::flatpak::is_installed "$package"; then
        ldebug "package($package) is not installed."
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history --sudo -- flatpak uninstall -y "$package" || return "$SHELL_FALSE"
}

function package_manager::flatpak::package_description() {
    local package="$1"

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    local description
    description=$(LANG=c flatpak remote-info flathub "$package" | sed -n '2p')
    string::trim "$description" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::flatpak::upgrade() {
    local app="$1"

    if [ -z "$app" ]; then
        cmd::run_cmd_with_history --sudo -- flatpak update -y || return "$SHELL_FALSE"
    else
        cmd::run_cmd_with_history --sudo -- flatpak update -y "$app" || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function package_manager::flatpak::update() {
    # flatpak 不用处理
    return "$SHELL_TRUE"
}
