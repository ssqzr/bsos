#!/bin/bash

if [ -n "${SCRIPT_DIR_dc1ea0de}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_dc1ea0de="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_dc1ea0de}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dc1ea0de}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dc1ea0de}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dc1ea0de}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dc1ea0de}/../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dc1ea0de}/path.sh"

function fs::file::size_byte() {
    local path
    local is_sudo
    local password
    local param

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v path ]; then
                path="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v path ]; then
        lerror "get file size failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$path"; then
        lerror "get file size failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$path"; then
        lerror "get file($path) size failed, it is not exists"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_file "$path"; then
        lerror "get file($path) size failed, it is not file"
        return "$SHELL_FALSE"
    fi

    stat -c "%s" "$path"
    return "$SHELL_TRUE"
}

function fs::file::delete() {
    local path
    local is_sudo
    local password
    local param

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v path ]; then
                path="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v path ]; then
        lerror "delete file failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$path"; then
        lerror "delete file failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$path"; then
        ldebug "delete file($path) success, it does not exist"
        return "$SHELL_TRUE"
    fi

    if fs::path::is_not_file "$path"; then
        lerror "delete file($path) failed, it is not file"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- rm -f "{{$path}}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete file($path) failed"
        return "$SHELL_FALSE"
    fi

    ldebug "delete file($path) success"
    return "$SHELL_TRUE"
}

function fs::file::move() {
    local src
    local dst
    local is_sudo
    local password
    local is_force="$SHELL_FALSE"
    local backup_filepath
    local temp_dst_filepath
    local temp_str
    local param

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        --force | --force=*)
            parameter::parse_bool --default=y --option="$param" is_force || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v src ]; then
                src="$param"
                continue
            fi

            if [ ! -v dst ]; then
                dst="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v src ]; then
        lerror "move file failed, param src is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$src"; then
        lerror "move file failed, param src is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v dst ]; then
        lerror "move file failed, param dst is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$dst"; then
        lerror "move file failed, param dst is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$src"; then
        ldebug "move file($src) failed, it does not exist"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_file "$src"; then
        lerror "move file($src) failed, it is not file"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_exists "$dst"; then
        if [ "$is_force" -ne "$SHELL_TRUE" ]; then
            lerror "move file($src) to target($dst) failed, target is exists"
            return "$SHELL_FALSE"
        fi
        # 存在，并且指定可以覆盖
        if fs::path::is_not_file "$dst"; then
            lerror "move file($src) to target($dst) failed, target is exists and not file"
            return "$SHELL_FALSE"
        fi
    fi

    temp_str="$(fs::path::dirname "$dst")" || return "$SHELL_FALSE"
    if fs::path::is_not_exists "$temp_str"; then
        ldebug "dst($dst) parent directory is not exists, create it..."
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mkdir -p "{{$temp_str}}" || return "$SHELL_FALSE"
        ldebug "create dst($dst) parent directory success"
    fi

    # 先拷贝到临时目录下，然后再移动到目标文件。因为拷贝失败的可能性更大，移动失败的可能性更小
    temp_dst_filepath="$(fs::path::random_path --path="$dst")" || return "$SHELL_FALSE"
    ldebug "copy src($src) to target temp file($temp_dst_filepath)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cp "{{$src}}" "{{$temp_dst_filepath}}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "copy file($src) to target temp file($temp_dst_filepath) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "copy src($src) to target temp file($temp_dst_filepath) success"

    # 如果目的文件存在，先保存到临时文件
    if fs::path::is_exists "$dst"; then
        backup_filepath="$(fs::path::random_path --path="$dst" --suffix="-backup")" || return "$SHELL_FALSE"

        ldebug "backup file($dst) to($backup_filepath)"
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$dst}}" "{{$backup_filepath}}" || return "$SHELL_FALSE"
        ldebug "backup file($dst) to($backup_filepath) success"
    fi

    # 将临时文件移动到目标文件
    ldebug "move target temp file($temp_dst_filepath) to target($dst)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$temp_dst_filepath}}" "{{$dst}}" || return "$SHELL_FALSE"
    ldebug "move target temp file($temp_dst_filepath) to target($dst) success"

    # 拷贝成功，删除原文件
    fs::file::delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$src"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete src file($src) failed"
        return "$SHELL_FALSE"
    fi

    ldebug "delete src file($src) success"

    if string::is_not_empty "$backup_filepath"; then
        ldebug "delete target backup file($backup_filepath)..."
        fs::file::delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$backup_filepath"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "delete target backup file($backup_filepath) failed"
            return "$SHELL_FALSE"
        fi
        ldebug "delete target backup file($backup_filepath) success"
    fi

    linfo "move src file($src) to target($dst) success"
    return "$SHELL_TRUE"
}

function fs::file::copy() {
    local src
    local dst
    local is_sudo
    local password
    local is_force="$SHELL_FALSE"
    local backup_filepath
    local temp_dst_filepath
    local temp_str
    local param

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        --force | --force=*)
            parameter::parse_bool --default=y --option="$param" is_force || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v src ]; then
                src="$param"
                continue
            fi

            if [ ! -v dst ]; then
                dst="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v src ]; then
        lerror "copy file failed, param src is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$src"; then
        lerror "copy file failed, param src is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v dst ]; then
        lerror "copy file failed, param dst is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$dst"; then
        lerror "copy file failed, param dst is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$src"; then
        ldebug "copy file($src) failed, it does not exist"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_file "$src"; then
        lerror "copy file($src) failed, it is not file"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_exists "$dst"; then
        if [ "$is_force" -ne "$SHELL_TRUE" ]; then
            lerror "copy file($src) to target($dst) failed, target is exists"
            return "$SHELL_FALSE"
        fi
        # 存在，并且指定可以覆盖
        if fs::path::is_not_file "$dst"; then
            lerror "copy file($src) to target($dst) failed, target is exists and not file"
            return "$SHELL_FALSE"
        fi
    fi

    temp_str="$(fs::path::dirname "$dst")" || return "$SHELL_FALSE"
    if fs::path::is_not_exists "$temp_str"; then
        ldebug "dst($dst) parent directory is not exists, create it..."
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mkdir -p "{{$temp_str}}" || return "$SHELL_FALSE"
        ldebug "create dst($dst) parent directory success"
    fi

    # 先拷贝到临时目录下，然后再移动到目标文件。因为拷贝失败的可能性更大，移动失败的可能性更小
    temp_dst_filepath="$(fs::path::random_path --path="$dst")" || return "$SHELL_FALSE"
    ldebug "copy src($src) to target temp file($temp_dst_filepath)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cp "{{$src}}" "{{$temp_dst_filepath}}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "copy file($src) to target temp file($temp_dst_filepath) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "copy src($src) to target temp file($temp_dst_filepath) success"

    # 如果目的文件存在，先保存到临时文件
    if fs::path::is_exists "$dst"; then
        backup_filepath="$(fs::path::random_path --path="$dst" --suffix="-backup")" || return "$SHELL_FALSE"

        ldebug "backup file($dst) to($backup_filepath)"
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$dst}}" "{{$backup_filepath}}" || return "$SHELL_FALSE"
        ldebug "backup file($dst) to($backup_filepath) success"
    fi

    # 将临时文件移动到目标文件
    ldebug "move target temp file($temp_dst_filepath) to target($dst)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$temp_dst_filepath}}" "{{$dst}}" || return "$SHELL_FALSE"
    ldebug "move target temp file($temp_dst_filepath) to target($dst) success"

    if string::is_not_empty "$backup_filepath"; then
        ldebug "delete target backup file($backup_filepath)..."
        fs::file::delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$backup_filepath"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "delete target backup file($backup_filepath) failed"
            return "$SHELL_FALSE"
        fi
        ldebug "delete target backup file($backup_filepath) success"
    fi

    linfo "copy src file($src) to target($dst) success"
    return "$SHELL_TRUE"
}

function fs::file::read() {
    local filepath
    local is_sudo
    local password
    local param

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v filepath ]; then
                filepath="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v filepath ]; then
        lerror "param filepath is required"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$filepath"; then
        lerror "file($filepath) is not exists"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_file "$filepath"; then
        lerror "file($filepath) is not a file"
        return "$SHELL_FALSE"
    fi

    # 这个实现不了 sudo
    # data="$(</dev/stdin)"

    cmd::run_cmd_with_history --stdout=cat --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cat "$filepath" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function fs::file::write() {
    local filepath
    local is_sudo
    local password
    local data
    local param
    local is_force="${SHELL_FALSE}"
    local temp

    ldebug "params=$*"

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        --force | --force=*)
            parameter::parse_bool --default=y --option="$param" is_force || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v filepath ]; then
                filepath="$param"
                continue
            fi

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v filepath ]; then
        lerror "param filepath is required"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is required"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_exists "$filepath"; then
        if [ "$is_force" -ne "$SHELL_TRUE" ]; then
            lerror "write file($filepath) failed, it is exists"
            return "$SHELL_FALSE"
        fi
        # 存在，并且指定可以覆盖
        if fs::path::is_not_file "$filepath"; then
            lerror "file($filepath) is not a file"
            return "$SHELL_FALSE"
        fi
    fi

    temp="$(fs::path::dirname "$filepath")" || return "$SHELL_FALSE"
    if fs::path::is_not_exists "$temp"; then
        ldebug "file($filepath) parent directory is not exists, create it..."
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mkdir -p "{{$temp}}" || return "$SHELL_FALSE"
        ldebug "create file($filepath) parent directory success"
    fi

    cmd::run_cmd_with_history --stdout=cat --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- echo "${data}" ">>" "$filepath" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
