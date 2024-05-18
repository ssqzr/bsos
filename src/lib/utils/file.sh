#!/bin/bash

if [ -n "${SCRIPT_DIR_1d735f60}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1d735f60="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/string.sh"

function file::read_dir() {
    local -n _e8a51292_files
    local is_sudo
    local password
    local directory
    local param
    local _f2dfb4d4_temp_str

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
            if [ ! -R _e8a51292_files ]; then
                _e8a51292_files="$param"
                continue
            fi
            if [ ! -v directory ]; then
                directory="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -R _e8a51292_files ]; then
        lerror "read directory failed, param(files-ref) is not set"
        return "$SHELL_FALSE"
    fi

    if [ ! -v directory ]; then
        lerror "read directory failed, param(directory) is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$directory" ]; then
        lerror "read directory failed, param(directory) is empty"
        return "$SHELL_FALSE"
    fi

    _f2dfb4d4_temp_str=$(find "${directory}" -maxdepth 1 -mindepth 1 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "read directory failed, call find to list files failed,output=${_f2dfb4d4_temp_str}"
        return "$SHELL_FALSE"
    fi

    readarray -t "${!_e8a51292_files}" < <(echo "$_f2dfb4d4_temp_str")

    return "$SHELL_TRUE"
}

# 遍历创建目录，上层目录也会创建
function file::create_dir_recursive() {
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

    if [ -z "$directory" ]; then
        lerror "create directory failed, param directory is empty"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mkdir -p "$directory"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "create directory($directory) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "create directory($directory) success"
    return "$SHELL_TRUE"
}

function file::create_parent_dir_recursive() {
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

    if [ -z "$path" ]; then
        lerror "create parent directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    parent_dir="$(dirname "$path")"
    if [ -e "$parent_dir" ]; then
        ldebug "create parent directory($parent_dir) success, it already exists"
        return "$SHELL_TRUE"
    fi

    file::create_dir_recursive --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$parent_dir"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "create parent directory($parent_dir) failed, path=$path"
        return "$SHELL_FALSE"
    fi
    ldebug "create parent directory($parent_dir) success"

    return "$SHELL_TRUE"
}

# 安全的删除文件或者目录，会有如下限制：
# - 避免删除系统的根目录
function file::safe_delete_file_dir() {
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
        lerror "delete file or directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$path" ]; then
        lerror "delete file or directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$path" = "/" ]; then
        lerror "can not delete / directory"
        return "$SHELL_FALSE"
    fi

    if [ "${path:0-2}" = "/*" ]; then
        lerror "can not delete directory($path), it is not safe"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$path" ]; then
        ldebug "delete file or directory($path) success, it does not exist"
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- rm -rf "$path"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "delete file or directory($path) failed"
        return "$SHELL_FALSE"
    fi
    ldebug "delete file or directory($path) success"
    return "$SHELL_TRUE"
}

# 在同目录下备份文件或者目录
function file::backup_file_dir_in_same_dir() {
    local -n _03e0288a_backup_filepath
    local path
    local is_sudo
    local password

    local filename
    local current_dir
    local dst_filepath

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
        --target-filepath=*)
            _03e0288a_backup_filepath="$param"
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
        lerror "backup file or directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$path" ]; then
        lerror "backup file or directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    current_dir="$(dirname "$path")"
    filename="$(basename "$path")"

    filename=$(string::gen_random "$filename" "" "") || return "$SHELL_FALSE"

    dst_filepath="${current_dir}/${filename}"

    if [ -e "$dst_filepath" ]; then
        lerror "backup file($path) failed, target file or directory($dst_filepath) exists"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cp -rf "$path" "$dst_filepath" || return "$SHELL_FALSE"

    if [ -R _03e0288a_backup_filepath ]; then
        _03e0288a_backup_filepath="$dst_filepath"
    fi
    return "$SHELL_TRUE"
}

# 移动文件或者目录
# 如果没有制定 --target-filepath 和 --target-directory 和 --target-filename ，则会在同目录下移动到随机文件
# 如果没有制定 --target-filepath 和 --target-directory ，指定了 --target-filename ，则会在同目录下移动到 --target-filename 指定的文件名
# 如果指定了 --target-filepath ，那么 --target-directory 和 --target-filename 会被忽略
function file::mv_file_dir() {
    local -n _548aad8f_target_filepath
    local path
    local is_sudo
    local password
    local target_dir
    local target_filename
    local current_dir
    local current_filename
    local target_filepath

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
        --target-filepath=*)
            parameter::parse_string --option="$param" _548aad8f_target_filepath || return "$SHELL_FALSE"
            ;;
        --target-filename=*)
            parameter::parse_string --option="$param" target_filename || return "$SHELL_FALSE"
            ;;
        --target-directory=*)
            parameter::parse_string --option="$param" target_dir || return "$SHELL_FALSE"
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
        lerror "move file or directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$path" ]; then
        lerror "move file or directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    current_dir="$(dirname "$path")"
    current_filename="$(basename "$path")"

    if [ -R _548aad8f_target_filepath ]; then
        target_filepath="$_548aad8f_target_filepath"
    fi

    if [ -z "$target_filepath" ]; then
        if [ -z "$target_dir" ] && [ -z "$target_filename" ]; then
            # 没有指定 --target-filename 也没有指定 --target-directory
            target_dir="$current_dir"
            target_filename=$(string::gen_random "$current_filename" "" "") || return "$SHELL_FALSE"
            target_filepath="${target_dir}/${target_filename}"
        elif [ -z "$target_filename" ]; then
            # 没有指定 --target-filename
            target_filename="$current_filename"
            if [ "$current_dir" == "$target_dir" ]; then
                # 同目录
                target_filename=$(string::gen_random "$current_filename" "" "") || return "$SHELL_FALSE"
            fi
            target_filepath="${target_dir}/${target_filename}"
        elif [ -z "$target_dir" ]; then
            # 没有指定 --target-directory
            target_dir="$current_dir"
            target_filepath="${target_dir}/${target_filename}"
        else
            # 指定 --target-filename 指定 --target-directory
            target_filepath="${target_dir}/${target_filename}"
        fi
    fi

    if [ -e "$target_filepath" ]; then
        lerror "mv file($path) to dst($target_filepath) failed, target file or directory($target_filepath) exists"
        return "$SHELL_FALSE"
    fi

    # 创建父级目录
    file::create_parent_dir_recursive --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$target_filepath" || return "$SHELL_FALSE"

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- mv -f "$path" "${target_filepath}" || return "$SHELL_FALSE"

    if [ -R _548aad8f_target_filepath ] && [ -z "${_548aad8f_target_filepath}" ]; then
        _548aad8f_target_filepath="${target_filepath}"
    fi

    return "$SHELL_TRUE"
}

# 复制文件或者目录
# 参数说明：
# -f, --force 是否覆盖已经存在的文件
# -t, --create-target-directory 是否自动创建父级目录
# <src> 原文件或目录
# <dst> 目标文件或目录
function file::copy_file_dir() {
    local src
    local dst
    local is_sudo="$SHELL_FALSE"
    local password=""
    # 是否覆盖已经存在的文件
    local is_force="$SHELL_FALSE"

    local backup_filepath
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

    if [ ! -v dst ]; then
        lerror "copy file failed, param dst is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$src" ]; then
        lerror "copy file failed, param src is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$dst" ]; then
        lerror "copy file failed, param dst is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$src" ]; then
        lerror "src file($src) not exists"
        return "$SHELL_FALSE"
    fi

    if [ -e "$dst" ]; then
        if [ "$is_force" -ne "$SHELL_TRUE" ]; then
            # 目标文件已经存在，并且选择不覆盖
            ldebug "copy file failed, dst file exists, param limit not overwrite destination file, src=$src, dst=$dst"
            return "$SHELL_FALSE"
        fi
        if [ -d "$dst" ] && [ -f "$src" ]; then
            # 可以覆盖，并且目标文件存在，但是原文件是文件，而目的是目录
            lerror "copy file failed, src is file, dst exists and is directory, src=$src, dst=$dst"
            return "$SHELL_FALSE"
        elif [ -f "$dst" ] && [ -d "$src" ]; then
            # 可以覆盖，并且目标文件存在，但是原文件是目录，而目的是文件
            lerror "copy file failed, src is directory, dst exists and is file, src=$src, dst=$dst"
            return "$SHELL_FALSE"
        fi
        ldebug "dst exists, param allow overwrite dst file, will overwrite it, dst=$dst"
    fi

    # 创建父级目录
    file::create_parent_dir_recursive --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "$dst" || return "$SHELL_FALSE"

    # 先备份旧的目的文件
    if [ -e "$dst" ]; then
        file::mv_file_dir --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" --target-filepath=backup_filepath "$dst" || return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- cp -rf "$src" "$dst"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "copy file failed, src=$src, dst=$dst"
        # 恢复备份的文件
        if [ -n "${backup_filepath}" ] && [ -e "${backup_filepath}" ]; then
            file::mv_file_dir --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" --target-filepath=dst "${backup_filepath}"
            if [ $? -ne "$SHELL_TRUE" ]; then
                lerror "restore backup file failed, backup_filepath=$backup_filepath, dst=$dst"
            fi
        fi
        return "$SHELL_FALSE"
    fi

    # 删除备份的文件
    if [ -n "${backup_filepath}" ] && [ -e "${backup_filepath}" ]; then
        file::safe_delete_file_dir --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" "${backup_filepath}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "delete backup file failed, backup_filepath=$backup_filepath"
        fi
    fi

    linfo "copy file success, src=$src, dst=$dst"
    return "$SHELL_TRUE"
}
