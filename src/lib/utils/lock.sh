#!/bin/bash

if [ -n "${SCRIPT_DIR_3c32deac}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_3c32deac="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_3c32deac}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_3c32deac}/log/log.sh"

function lock::lock() {
    local filepath="$1"
    shift

    exec 99<>"$filepath"
    flock -n 99
    if [ $? -ne "$SHELL_TRUE" ]; then
        linfo "${0##*/} already running, exit."
        return "${SHELL_FALSE}"
    fi
    echo "$$" >&99
}

function lock::unlock() {
    local filepath="$1"
    shift

    exec 99<>"$filepath"
    flock -u 99
}

# 应该使用 trap 注册信号来清理锁文件
# 例如 trap lock::clean "xxx" EXIT
function lock::clean() {
    local filepath="$1"
    shift

    rm -f "$filepath"
}
