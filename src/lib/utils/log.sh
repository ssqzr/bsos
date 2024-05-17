#!/bin/bash

# 日志库

if [ -n "${SCRIPT_DIR_30e78b31}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_30e78b31="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
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

    export __log_filepath="${log_dir}/bsos/bsos.log"
    log::_create_log_parent_directory
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
    local caller_level="$1"
    local level="$2"
    local message="$3"
    local pid="$$"

    local function_name
    local filename
    local line_num
    local datetime

    ((caller_level += 1))

    function_name=$(get_caller_function_name "${caller_level}")
    filename=$(get_caller_filename "${caller_level}")
    line_num=$(get_caller_file_line_num "${caller_level}")
    datetime="$(get_human_datetime)"

    printf "%s %s [%s] %s:%s [%s] %s\n" "${datetime}" "${level}" "${pid}" "${filename}" "${line_num}" "${function_name}" "${message}" >>"${__log_filepath}"
}

function linfo() {
    local level="info"
    local message
    local caller_level
    local param
    for param in "$@"; do
        case "$param" in
        --caller-level=*)
            caller_level="${param#*=}"
            ;;
        *)
            if [ ! -v message ]; then
                message="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    caller_level=${caller_level:-0}
    ((caller_level += 1))

    log::_log "${caller_level}" $level "${message}"
}

function ldebug() {
    local level="debug"
    local message
    local caller_level
    local param
    for param in "$@"; do
        case "$param" in
        --caller-level=*)
            caller_level="${param#*=}"
            ;;
        *)
            if [ ! -v message ]; then
                message="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    caller_level=${caller_level:-0}
    ((caller_level += 1))

    log::_log "${caller_level}" $level "${message}"
}

function lwarn() {
    local level="warn"
    local message
    local caller_level
    local param
    for param in "$@"; do
        case "$param" in
        --caller-level=*)
            caller_level="${param#*=}"
            ;;
        *)
            if [ ! -v message ]; then
                message="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    caller_level=${caller_level:-0}
    ((caller_level += 1))

    log::_log "${caller_level}" $level "${message}"
}

function lerror() {
    local level="error"
    local message
    local caller_level
    local param
    for param in "$@"; do
        case "$param" in
        --caller-level=*)
            caller_level="${param#*=}"
            ;;
        *)
            if [ ! -v message ]; then
                message="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    caller_level=${caller_level:-0}
    ((caller_level += 1))

    log::_log "${caller_level}" $level "${message}"
}

function lwrite() {
    cat >>"${__log_filepath}"
}

function lexit() {
    local level="error"
    local exit_code
    local caller_level
    local param
    for param in "$@"; do
        case "$param" in
        --caller-level=*)
            caller_level="${param#*=}"
            ;;
        *)
            if [ ! -v exit_code ]; then
                exit_code="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    caller_level=${caller_level:-0}
    ((caller_level += 1))

    log::_log "${caller_level}" $level "script exit with code ${exit_code}"

    exit "${exit_code}"
}

function log::_main() {
    log::_init_log_filepath
}

log::_main
