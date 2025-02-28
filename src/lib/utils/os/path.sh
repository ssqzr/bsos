#!/bin/bash

if [ -n "${SCRIPT_DIR_15412e91}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_15412e91="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_15412e91}/../constant.sh"

# 获取临时的临时目录，重启后可能丢失
function os::path::temp_temp_base_dir() {
    # /tmp 和 /var/tmp 的区别： https://unix.stackexchange.com/a/30504
    echo "/tmp"
}

# 获取持久的临时目录，重启后不会丢失
function os::path::permanent_temp_base_dir() {
    # /tmp 和 /var/tmp 的区别： https://unix.stackexchange.com/a/30504
    echo "/var/tmp"
}
