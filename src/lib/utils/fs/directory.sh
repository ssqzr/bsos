#!/bin/bash

if [ -n "${SCRIPT_DIR_73b980be}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_73b980be="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_73b980be}/path.sh"

function fs::directory::read() {
    local -n files_e8a51292
    local is_sudo_e8a51292
    local password_e8a51292
    local directory_e8a51292
    local param_e8a51292
    local temp_str_e8a51292

    ldebug "params=$*"

    for param_e8a51292 in "$@"; do
        case "$param_e8a51292" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param_e8a51292" is_sudo_e8a51292 || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param_e8a51292" password_e8a51292 || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param_e8a51292"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -R files_e8a51292 ]; then
                files_e8a51292="$param_e8a51292"
                continue
            fi
            if [ ! -v directory_e8a51292 ]; then
                directory_e8a51292="$param_e8a51292"
                continue
            fi
            lerror "unknown parameter $param_e8a51292"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -R files_e8a51292 ]; then
        lerror "read directory failed, param(files-ref) is not set"
        return "$SHELL_FALSE"
    fi

    if [ ! -v directory_e8a51292 ]; then
        lerror "read directory failed, param(directory) is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$directory_e8a51292"; then
        lerror "read directory failed, param(directory) is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$directory_e8a51292"; then
        lerror "read directory failed, directory($directory_e8a51292) is not exists"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_directory "$directory_e8a51292"; then
        lerror "read directory failed, path($directory_e8a51292) is not directory"
        return "$SHELL_FALSE"
    fi

    # temp_str_e8a51292=$(find "${directory_e8a51292}" -maxdepth 1 -mindepth 1 2>&1)
    temp_str_e8a51292=$(cmd::run_cmd_with_history --stdout=cat --sudo="$(string::print_yes_no "$is_sudo_e8a51292")" --password="$password_e8a51292" -- find "{{${directory_e8a51292}}}" -maxdepth 1 -mindepth 1) || return "$SHELL_FALSE"

    array::readarray "${!files_e8a51292}" < <(echo "$temp_str_e8a51292")

    return "$SHELL_TRUE"
}

function fs::directory::create_recursive() {
    local is_sudo
    local password
    local directory
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
            if [ ! -v directory ]; then
                directory="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v directory ]; then
        lerror "create directory failed, param directory is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$directory"; then
        lerror "create directory failed, param directory is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_exists "$directory"; then
        if fs::path::is_directory "$directory"; then
            ldebug "directory($directory) is exists and is directory, create success."
            return "$SHELL_TRUE"
        fi
        lerror "create directory failed, path($directory) is exists but not directory"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mkdir -p "{{$directory}}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "create directory($directory) failed"
        return "$SHELL_FALSE"
    fi

    ldebug "create directory($directory) success"
    return "$SHELL_TRUE"
}

function fs::directory::dirname_create_recursive() {
    local path
    local is_sudo
    local password
    local parent_dir
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
        lerror "create parent directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$path"; then
        lerror "create parent directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    parent_dir="$(fs::path::dirname "$path")"
    if fs::path::is_exists "$parent_dir"; then
        if fs::path::is_directory "$parent_dir"; then
            ldebug "create path($path) parent directory success, it already exists"
            return "$SHELL_TRUE"
        fi
        lerror "create path($path) parent directory failed, parent path is exists but not directory"
        return "$SHELL_FALSE"
    fi

    fs::directory::create_recursive --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$parent_dir"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "create path($path) parent directory failed"
        return "$SHELL_FALSE"
    fi
    ldebug "create path($path) parent directory success"

    return "$SHELL_TRUE"
}

function fs::directory::delete() {
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
        lerror "delete directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$path"; then
        lerror "delete directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$path"; then
        ldebug "delete directory($path) success, it does not exist"
        return "$SHELL_TRUE"
    fi

    if fs::path::is_not_directory "$path"; then
        lerror "delete directory($path) failed, it is not a directory"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- rm -rf "$path"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete directory($path) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "delete directory($path) success"
    return "$SHELL_TRUE"
}

function fs::directory::safe_delete() {
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
        lerror "delete directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$path" ]; then
        lerror "delete directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$path" = "/" ]; then
        lerror "delete directory($path) failed, can not delete / directory"
        return "$SHELL_FALSE"
    fi

    if [ "${path:0-2}" = "/*" ]; then
        lerror "delete directory($path) failed, path endwith /*, it is not safe"
        return "$SHELL_FALSE"
    fi

    fs::directory::delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$path" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function fs::directory::move() {
    local src
    local dst
    local is_sudo
    local password
    local is_force="$SHELL_FALSE"
    local backup_filepath
    local temp_dst_filepath
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
        lerror "move directory failed, param src is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$src"; then
        lerror "move directory failed, param src is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v dst ]; then
        lerror "move directory failed, param dst is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$dst"; then
        lerror "move directory failed, param dst is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$src"; then
        ldebug "move directory($src) failed, it does not exist"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_directory "$src"; then
        lerror "move directory($src) failed, it is not directory"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_exists "$dst"; then
        if [ "$is_force" -ne "$SHELL_TRUE" ]; then
            lerror "move directory($src) to target($dst) failed, target is exists"
            return "$SHELL_FALSE"
        fi
        # 存在，并且指定可以覆盖
        if fs::path::is_not_directory "$dst"; then
            lerror "move directory($src) to target($dst) failed, target is exists and not directory"
            return "$SHELL_FALSE"
        fi
    fi

    fs::directory::dirname_create_recursive --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$dst" || return "$SHELL_FALSE"

    # 先拷贝到临时目录下，然后再移动到目标目录。因为拷贝失败的可能性更大，移动失败的可能性更小
    temp_dst_filepath="$(fs::path::random_path --path="$dst")" || return "$SHELL_FALSE"
    ldebug "copy src($src) to target temp directory($temp_dst_filepath)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cp -r "{{$src}}" "{{$temp_dst_filepath}}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "copy directory($src) to target temp directory($temp_dst_filepath) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "copy directory($src) to target temp directory($temp_dst_filepath) success"

    # 如果目的目录存在，先保存到临时目录
    if fs::path::is_exists "$dst"; then
        backup_filepath="$(fs::path::random_path --path="$dst")" || return "$SHELL_FALSE"

        ldebug "backup directory($dst) to($backup_filepath)"
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$dst}}" "{{$backup_filepath}}" || return "$SHELL_FALSE"
        ldebug "backup directory($dst) to($backup_filepath) success"
    fi

    # 将临时目录移动到目标目录
    ldebug "move target temp directory($temp_dst_filepath) to target($dst)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$temp_dst_filepath}}" "{{$dst}}" || return "$SHELL_FALSE"
    ldebug "move target temp directory($temp_dst_filepath) to target($dst) success"

    # 拷贝成功，删除原目录
    fs::directory::safe_delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$src"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete src directory($src) failed"
        return "$SHELL_FALSE"
    fi

    ldebug "delete src directory($src) success"

    if string::is_not_empty "$backup_filepath"; then
        ldebug "delete target backup directory($backup_filepath)..."
        fs::directory::safe_delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$backup_filepath"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "delete target backup directory($backup_filepath) failed"
            return "$SHELL_FALSE"
        fi
        ldebug "delete target backup directory($backup_filepath) success"
    fi

    linfo "move src directory($src) to target($dst) success"
    return "$SHELL_TRUE"
}

function fs::directory::copy() {
    local src
    local dst
    local is_sudo
    local password
    local is_force="$SHELL_FALSE"
    local backup_filepath
    local temp_dst_filepath
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
        lerror "copy directory failed, param src is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$src"; then
        lerror "copy directory failed, param src is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v dst ]; then
        lerror "copy directory failed, param dst is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$dst"; then
        lerror "copy directory failed, param dst is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$src"; then
        ldebug "copy directory($src) failed, it does not exist"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_directory "$src"; then
        lerror "copy directory($src) failed, it is not directory"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_exists "$dst"; then
        if [ "$is_force" -ne "$SHELL_TRUE" ]; then
            lerror "copy directory($src) to target($dst) failed, target is exists"
            return "$SHELL_FALSE"
        fi
        # 存在，并且指定可以覆盖
        if fs::path::is_not_directory "$dst"; then
            lerror "copy directory($src) to target($dst) failed, target is exists and not directory"
            return "$SHELL_FALSE"
        fi
    fi

    fs::directory::dirname_create_recursive --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$dst" || return "$SHELL_FALSE"

    # 先拷贝到临时目录下，然后再移动到目标目录。因为拷贝失败的可能性更大，移动失败的可能性更小
    temp_dst_filepath="$(fs::path::random_path --path="$dst")" || return "$SHELL_FALSE"
    ldebug "copy directory($src) to target temp directory($temp_dst_filepath)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cp -r "{{$src}}" "{{$temp_dst_filepath}}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "copy directory($src) to target temp directory($temp_dst_filepath) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "copy directory($src) to target temp directory($temp_dst_filepath) success"

    # 如果目的目录存在，先保存到临时目录
    if fs::path::is_exists "$dst"; then
        backup_filepath="$(fs::path::random_path --path="$dst")" || return "$SHELL_FALSE"

        ldebug "backup directory($dst) to($backup_filepath)"
        cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$dst}}" "{{$backup_filepath}}" || return "$SHELL_FALSE"
        ldebug "backup directory($dst) to($backup_filepath) success"
    fi

    # 将临时目录移动到目标目录
    ldebug "move target temp directory($temp_dst_filepath) to target($dst)..."
    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv "{{$temp_dst_filepath}}" "{{$dst}}" || return "$SHELL_FALSE"
    ldebug "move target temp directory($temp_dst_filepath) to target($dst) success"

    if string::is_not_empty "$backup_filepath"; then
        ldebug "delete target backup directory($backup_filepath)..."
        fs::directory::safe_delete --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$backup_filepath"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "delete target backup directory($backup_filepath) failed"
            return "$SHELL_FALSE"
        fi
        ldebug "delete target backup directory($backup_filepath) success"
    fi

    linfo "copy src directory($src) to target($dst) success"
    return "$SHELL_TRUE"
}
