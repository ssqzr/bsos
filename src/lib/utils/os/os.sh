#!/bin/bash

# 和系统规范相关的工具函数

# 1. 依赖应该尽可能的少

if [ -n "${SCRIPT_DIR_58234bf8}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_58234bf8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_58234bf8}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_58234bf8}/path.sh"

function os::is_vmware() {
    lspci | grep -q "VMware PCI"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function os::is_vm() {
    os::is_vmware && return "$SHELL_TRUE"
    return "$SHELL_FALSE"
}

function os::is_not_vm() {
    os::is_vm && return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function os::nodename() {
    uname -n
}

function os::user::name() {
    id -un
}

function os::user::group() {
    id -gn
}

function os::user::is_root() {
    if [ "$(id -u)" -eq 0 ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function os::user::is_not_root() {
    ! os::user::is_root
}
