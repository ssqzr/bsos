#!/bin/bash

# 日志库

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_30e78b31="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_30e78b31}/debug.sh" || exit 1

function log::_init_log_filepath() {
    if [ -n "${__log_filepath}" ]; then
        return "$SHELL_TRUE"
    fi
    local log_dir="${XDG_CACHE_HOME}"
    if [ -z "${log_dir}" ]; then
        log_dir="${HOME}/.cache"
    fi

    export __log_filepath="${log_dir}/lzw/lzw.log"
}

function log::_create_dir_recursive() {
    local dir="$1"
    if [ -z "$dir" ]; then
        return "$SHELL_FALSE"
    fi

    mkdir -p "$dir" >/dev/null 2>&1
    if [ $? -ne "$SHELL_TRUE" ]; then
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function log::_create_log_parent_directory() {
    local parent_dir
    parent_dir="$(dirname "${__log_filepath}")"
    log::_create_dir_recursive "$parent_dir"
}

# 路径不支持~
# realpath命令也不支持~，例如~/xxxx
function log::set_log_file() {
    local filepath="$1"
    # 转成绝对路径
    filepath="$(realpath "${filepath}")"
    if [ -z "$filepath" ]; then
        return
    fi
    __log_filepath="${filepath}"
    log::_create_log_parent_directory
}

function log::_log() {
    local level="$1"
    local message="$2"
    local pid="$$"

    local function_name
    local filename
    local line_num
    local datetime

    function_name=$(get_caller_function_name 2)
    filename=$(get_caller_filename 2)
    line_num=$(get_caller_file_line_num 2)
    datetime="$(get_human_datetime)"

    log::_create_log_parent_directory

    echo "${datetime} ${level} [${pid}] ${filename}:${line_num} [${function_name}] ${message}" >>"${__log_filepath}"
}

function linfo() {
    local message="$1"
    local level="info"
    log::_log $level "${message}"
}

function ldebug() {
    local message="$1"
    local level="debug"
    log::_log $level "${message}"
}

function lwarn() {
    local message="$1"
    local level="warn"
    log::_log $level "${message}"
}

function lerror() {
    local message="$1"
    local level="error"
    log::_log $level "${message}"
}

function lwrite() {
    cat >>"${__log_filepath}"
}

function log::_main() {
    log::_init_log_filepath
}

log::_main
