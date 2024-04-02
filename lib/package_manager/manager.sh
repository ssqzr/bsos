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

__default_package_manager="yay"

# 有时候因为测试kill掉了包管理器，导致锁文件残留。每次都是运行失败查看日志才知道是锁文件残留了。
# 本来想通过 `lsof 锁文件` 来判断是否被占用的，但是系统默认没有安装 lsof
# 也不是很想将 lsof 添加到全局前置安装包中，前置太臃肿也不好
# 这里简单处理
# pacman pamac yay都是使用同一个锁文件
function package_manager::_clear_lock() {
    local pacman_lock_file="/var/lib/pacman/db.lck"

    if [ ! -e "$pacman_lock_file" ]; then
        return "$SHELL_TRUE"
    fi

    lwarn "lock file($pacman_lock_file) exists"

    if process::is_running "pacman"; then
        lerror "pacman is running, can not clear lock file"
        return "$SHELL_FALSE"
    fi

    if process::is_running "pamac"; then
        lerror "pamac is running, can not clear lock file"
        return "$SHELL_FALSE"
    fi

    if process::is_running "yay"; then
        lerror "yay is running, can not clear lock file"
        return "$SHELL_FALSE"
    fi

    lwarn "file($pacman_lock_file) is not in use, clear lock file"

    cmd::run_cmd_with_history sudo rm -f "$pacman_lock_file" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::is_installed() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        return "$SHELL_FALSE"
    fi
    if [ -z "$package" ]; then
        lerror "param package is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$package_manager" == "default" ]; then
        package_manager="${__default_package_manager}"
    fi

    local func_name="package_manager::${package_manager}::is_installed"
    $func_name "$package" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::install() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        return "$SHELL_FALSE"
    fi
    if [ -z "$package" ]; then
        lerror "param package is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$package_manager" == "default" ]; then
        package_manager="${__default_package_manager}"
    fi

    if [ "$package_manager" != "flatpak" ] && ! package_manager::_clear_lock; then
        lerror "clear lock file failed, can not install package($package)"
        return "$SHELL_FALSE"
    fi

    local func_name="package_manager::${package_manager}::install"
    $func_name "$package" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::uninstall() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        return "$SHELL_FALSE"
    fi
    if [ -z "$package" ]; then
        lerror "param package is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$package_manager" == "default" ]; then
        package_manager="${__default_package_manager}"
    fi

    if [ "$package_manager" != "flatpak" ] && ! package_manager::_clear_lock; then
        lerror "clear lock file failed, can not uninstall package($package)"
        return "$SHELL_FALSE"
    fi

    local func_name="package_manager::${package_manager}::uninstall"
    $func_name "$package" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::package_description() {
    local package_manager="$1"
    local package="$2"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        return "$SHELL_FALSE"
    fi
    if [ -z "$package" ]; then
        lerror "param package is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$package_manager" == "default" ]; then
        package_manager="${__default_package_manager}"
    fi

    local func_name="package_manager::${package_manager}::package_description"
    $func_name "$package" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function package_manager::upgrade() {
    local package_manager="$1"

    if [ -z "$package_manager" ]; then
        lerror "param package_manager is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$package_manager" == "default" ]; then
        package_manager="${__default_package_manager}"
    fi

    if [ "$package_manager" != "flatpak" ] && ! package_manager::_clear_lock; then
        lerror "clear lock file failed, can not upgrade package($package)"
        return "$SHELL_FALSE"
    fi

    "package_manager::${package_manager}::upgrade" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
