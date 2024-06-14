#!/bin/bash

if [ -n "${SCRIPT_DIR_c005add3}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_c005add3="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_c005add3}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_c005add3}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_c005add3}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_c005add3}/../parameter.sh"

# 规范化路径
# 不解析链接
# 不关心是否存在
function fs::path::realpath() {
    local filepath="$1"
    local realpath
    realpath=$(realpath -m -s "$filepath")
    echo "$realpath"
    return "$SHELL_TRUE"
}

function fs::path::is_exists() {
    local filepath="$1"
    if [ -e "$filepath" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function fs::path::is_not_exists() {
    ! fs::path::is_exists "$@"
}

function fs::path::is_file() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function fs::path::is_not_file() {
    ! fs::path::is_file "$@"
}

function fs::path::is_directory() {
    local filepath="$1"
    if [ -d "$filepath" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function fs::path::is_not_directory() {
    ! fs::path::is_directory "$@"
}

function fs::path::is_pipe() {
    local filepath="$1"
    if [ -p "$filepath" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function fs::path::is_not_pipe() {
    ! fs::path::is_pipe "$@"
}

function fs::path::basename() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")
    echo "$filename"
    return "$SHELL_TRUE"
}

function fs::path::dirname() {
    local filepath="$1"
    local dirname
    dirname=$(dirname "$filepath")
    echo "$dirname"
    return "$SHELL_TRUE"
}

# 同时指定 --path 和 --parent 和 --name ，优先以 --path 为准
function fs::path::random_path() {
    local path
    local parent
    local name
    local random_name
    local suffix

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        --path=*)
            parameter::parse_string --option="$param" path || return "$SHELL_FALSE"
            ;;
        --parent=*)
            parameter::parse_string --option="$param" parent || return "$SHELL_FALSE"
            ;;
        --name=*)
            parameter::parse_string --option="$param" name || return "$SHELL_FALSE"
            ;;
        --suffix=*)
            parameter::parse_string --option="$param" suffix || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ -v path ]; then
        if string::is_empty "$path"; then
            lerror "random path failed, param path is set empty"
            return "$SHELL_FALSE"
        fi
        path=$(fs::path::realpath "$path") || return "$SHELL_FALSE"
        parent=$(fs::path::dirname "$path") || return "$SHELL_FALSE"
        name=$(fs::path::basename "$path") || return "$SHELL_FALSE"
    else
        if [ ! -v parent ]; then
            lerror "param parent is not set"
            return "$SHELL_FALSE"
        fi
        if [ ! -v name ]; then
            lerror "param name is not set"
            return "$SHELL_FALSE"
        fi
        if string::is_empty "$parent"; then
            lerror "random path failed, param parent is set empty"
            return "$SHELL_FALSE"
        fi
        if string::is_empty "$name"; then
            lerror "random path failed, param name is set empty"
            return "$SHELL_FALSE"
        fi
        parent=$(fs::path::realpath "$parent") || return "$SHELL_FALSE"
    fi

    random_name=$(string::gen_random "$name" "" "$suffix") || return "$SHELL_FALSE"
    path="$parent/$random_name"
    echo "$path"
    return "$SHELL_TRUE"
}
