#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1d735f60="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/log.sh"

# 遍历创建目录，上层目录也会创建
function file::create_dir_recursive() {
    local directory="$1"
    if [ -z "$directory" ]; then
        lerror "create directory failed, param directory is empty"
        return "$SHELL_FALSE"
    fi

    local stderr
    stderr=$(mkdir -p "$directory" 2>&1 >/dev/null)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "create directory($directory) failed, err=${stderr}"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# 删除文件
function file::delete_file() {
    local filepath="$1"
    if [ -z "$filepath" ]; then
        lerror "delete file failed, param filepath is empty"
        return "$SHELL_FALSE"
    fi
    local stderr
    stderr=$(rm -f "$filepath" 2>&1 >/dev/null)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete file($filepath) failed, err=${stderr}"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# 安全的删除目录，会有如下限制：
# - 避免删除系统的根目录
function file::delete_dir_safe() {
    local directory="$1"
    if [ -z "$directory" ]; then
        lerror "delete directory failed, param directory is empty"
        return "$SHELL_FALSE"
    fi
    if [ "$directory" = "/" ]; then
        lerror "can not delete / directory"
        return "$SHELL_FALSE"
    fi

    if [ "${directory:0-2}" = "/*" ]; then
        lerror "can not delete directory($directory), it is not safe"
        return "$SHELL_FALSE"
    fi

    local stderr
    stderr=$(rm -rf "$directory" 2>&1 >/dev/null)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete directory($directory) failed, err=${stderr}"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}
