#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1839760f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1839760f}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1839760f}/pacman.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1839760f}/pamac.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1839760f}/flatpak.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1839760f}/yay.sh"

# 有时候因为测试kill掉了包管理器，导致锁文件残留。每次都是运行失败查看日志才知道是锁文件残留了。
# 本来想通过 `lsof 锁文件` 来判断是否被占用的，但是系统默认没有安装 lsof
# 也不是很想将 lsof 添加到全局前置安装包中，前置太臃肿也不好
# 这里简单处理
# pacman pamac yay都是使用同一个锁文件
# flatpak 不需要处理，暂时没发现锁的问题
function package_manager::_clean_lock() {
    local pacman_lock_file="/var/lib/pacman/db.lck"

    if [ ! -e "$pacman_lock_file" ]; then
        return "$SHELL_TRUE"
    fi

    lwarn "lock file($pacman_lock_file) exists"

    if process::is_running "pacman"; then
        lerror "pacman is running, can not clean lock file"
        return "$SHELL_FALSE"
    fi

    if process::is_running "pamac"; then
        lerror "pamac is running, can not clean lock file"
        return "$SHELL_FALSE"
    fi

    if process::is_running "yay"; then
        lerror "yay is running, can not clean lock file"
        return "$SHELL_FALSE"
    fi

    lwarn "file($pacman_lock_file) is not in use, clean lock file"

    fs::file::delete --sudo "$pacman_lock_file" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::_run_command() {
    local package_manager="$1"
    local command="$2"
    shift 2
    local params=("$@")

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    if [ -z "$command" ]; then
        lerror "param command is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_clean_lock || return "$SHELL_FALSE"

    ldebug "package_manager=${package_manager} command=${command} params=${params[*]}"
    package_manager::"${package_manager}"::"${command}" "${params[@]}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function package_manager::is_installed() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_run_command "$package_manager" is_installed "$package" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function package_manager::install() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_run_command "$package_manager" install "$package" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function package_manager::uninstall() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_run_command "$package_manager" uninstall "$package" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function package_manager::package_description() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    if [ -z "$package" ]; then
        lerror "param package is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_run_command "$package_manager" package_description "$package" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function package_manager::upgrade() {
    local package_manager="$1"
    shift
    local app="$1"
    shift

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_run_command "$package_manager" upgrade "$app" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function package_manager::upgrade_all_pm() {

    if package_manager::is_installed "pacman" "yay"; then
        package_manager::update "yay" || return "$SHELL_FALSE"
        package_manager::upgrade "yay" || return "$SHELL_FALSE"
    else
        package_manager::update "pacman" || return "$SHELL_FALSE"
        package_manager::upgrade "pacman" || return "$SHELL_FALSE"
    fi

    if package_manager::is_installed "pacman" "flatpak"; then
        package_manager::update "flatpak" || return "$SHELL_FALSE"
        package_manager::upgrade "flatpak" || return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

# 只是更新数据库
function package_manager::update() {
    local package_manager="$1"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        lexit "$CODE_USAGE"
    fi

    package_manager::_run_command "$package_manager" update || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
