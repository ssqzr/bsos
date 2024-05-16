#!/bin/bash

if [ -n "${SCRIPT_DIR_58234bf8}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_58234bf8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_58234bf8}/constant.sh"

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
