#!/bin/bash

if [ -n "${SCRIPT_DIR_bafe0778}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_bafe0778="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_bafe0778}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_bafe0778}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_bafe0778}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_bafe0778}/disk.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_bafe0778}/partition.sh"

function storage::_init() {
    local tools=("parted" "lsblk" "fdisk")
    local temp_str

    for temp_str in "${tools[@]}"; do
        which "$temp_str" >/dev/null 2>&1
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "$temp_str command not found"
            lexit "$CODE_COMMAND_NOT_FOUND"
        fi
    done

    return "${SHELL_TRUE}"
}

function storage::_main() {
    # FIXME: 不能在 source 引用的时候检测，source 的时候未必满足条件，依赖可能会在程序运行后进行安装
    # 还没想好最佳的解决办法，先不进行检测
    # storage::_init || return "${SHELL_FALSE}"
    return "$SHELL_TRUE"
}

storage::_main
