#!/bin/bash

if [ -n "${SCRIPT_DIR_1d735f60}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_1d735f60="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_1d735f60}/string.sh"

function file::read_dir() {
    local -n files_e8a51292
    # FIXME: 没有实现sudo的逻辑，处理完去掉 shellcheck 的注释
    # shellcheck disable=SC2034
    local is_sudo_e8a51292
    # shellcheck disable=SC2034
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

    if [ -z "$directory_e8a51292" ]; then
        lerror "read directory failed, param(directory) is empty"
        return "$SHELL_FALSE"
    fi

    temp_str_e8a51292=$(find "${directory_e8a51292}" -maxdepth 1 -mindepth 1 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "read directory failed, call find to list files failed,output=${temp_str_e8a51292}"
        return "$SHELL_FALSE"
    fi

    readarray -t "${!files_e8a51292}" < <(echo "$temp_str_e8a51292")

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
    local -n backup_filepath_03e0288a
    local path_03e0288a
    local is_sudo_03e0288a
    local password_03e0288a

    local filename_03e0288a
    local current_dir_03e0288a
    local dst_filepath_03e0288a

    local param_03e0288a

    ldebug "params=$*"

    for param_03e0288a in "$@"; do
        case "$param_03e0288a" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param_03e0288a" is_sudo_03e0288a || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param_03e0288a" password_03e0288a || return "$SHELL_FALSE"
            ;;
        --target-filepath=*)
            backup_filepath_03e0288a="$param_03e0288a"
            ;;
        -*)
            lerror "unknown parameter $param_03e0288a"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v path_03e0288a ]; then
                path_03e0288a="$param_03e0288a"
                continue
            fi
            lerror "unknown parameter $param_03e0288a"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v path_03e0288a ]; then
        lerror "backup file or directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$path_03e0288a" ]; then
        lerror "backup file or directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    current_dir_03e0288a="$(dirname "$path_03e0288a")"
    filename_03e0288a="$(basename "$path_03e0288a")"

    filename_03e0288a=$(string::gen_random "$filename_03e0288a" "" "") || return "$SHELL_FALSE"

    dst_filepath_03e0288a="${current_dir_03e0288a}/${filename_03e0288a}"

    if [ -e "$dst_filepath_03e0288a" ]; then
        lerror "backup file($path_03e0288a) failed, target file or directory($dst_filepath_03e0288a) exists"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo_03e0288a")" --password="$password_03e0288a" -- cp -rf "$path_03e0288a" "$dst_filepath_03e0288a" || return "$SHELL_FALSE"

    if [ -R backup_filepath_03e0288a ]; then
        backup_filepath_03e0288a="$dst_filepath_03e0288a"
    fi
    return "$SHELL_TRUE"
}

# 移动文件或者目录
# 如果没有制定 --target-filepath 和 --target-directory 和 --target-filename ，则会在同目录下移动到随机文件
# 如果没有制定 --target-filepath 和 --target-directory ，指定了 --target-filename ，则会在同目录下移动到 --target-filename 指定的文件名
# 如果指定了 --target-filepath ，那么 --target-directory 和 --target-filename 会被忽略
function file::mv_file_dir() {
    local -n result_388c1ebe
    local path_388c1ebe
    local is_sudo_388c1ebe
    local password_388c1ebe
    local target_dir_388c1ebe
    local target_filename
    local current_dir_388c1ebe
    local current_filename
    local target_filepath_388c1ebe

    local param_388c1ebe

    ldebug "params=$*"

    for param_388c1ebe in "$@"; do
        case "$param_388c1ebe" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param_388c1ebe" is_sudo_388c1ebe || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param_388c1ebe" password_388c1ebe || return "$SHELL_FALSE"
            ;;
        --target-filepath=*)
            parameter::parse_string --option="$param_388c1ebe" result_388c1ebe || return "$SHELL_FALSE"
            ;;
        --target-filename=*)
            parameter::parse_string --option="$param_388c1ebe" target_filename || return "$SHELL_FALSE"
            ;;
        --target-directory=*)
            parameter::parse_string --option="$param_388c1ebe" target_dir_388c1ebe || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown parameter $param_388c1ebe"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v path_388c1ebe ]; then
                path_388c1ebe="$param_388c1ebe"
                continue
            fi
            lerror "unknown parameter $param_388c1ebe"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v path_388c1ebe ]; then
        lerror "move file or directory failed, param path is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$path_388c1ebe" ]; then
        lerror "move file or directory failed, param path is empty"
        return "$SHELL_FALSE"
    fi

    current_dir_388c1ebe="$(dirname "$path_388c1ebe")"
    current_filename="$(basename "$path_388c1ebe")"

    if [ -R result_388c1ebe ]; then
        target_filepath_388c1ebe="$result_388c1ebe"
    fi

    if [ -z "$target_filepath_388c1ebe" ]; then
        if [ -z "$target_dir_388c1ebe" ] && [ -z "$target_filename" ]; then
            # 没有指定 --target-filename 也没有指定 --target-directory
            target_dir_388c1ebe="$current_dir_388c1ebe"
            target_filename=$(string::gen_random "$current_filename" "" "") || return "$SHELL_FALSE"
            target_filepath_388c1ebe="${target_dir_388c1ebe}/${target_filename}"
        elif [ -z "$target_filename" ]; then
            # 没有指定 --target-filename
            target_filename="$current_filename"
            if [ "$current_dir_388c1ebe" == "$target_dir_388c1ebe" ]; then
                # 同目录
                target_filename=$(string::gen_random "$current_filename" "" "") || return "$SHELL_FALSE"
            fi
            target_filepath_388c1ebe="${target_dir_388c1ebe}/${target_filename}"
        elif [ -z "$target_dir_388c1ebe" ]; then
            # 没有指定 --target-directory
            target_dir_388c1ebe="$current_dir_388c1ebe"
            target_filepath_388c1ebe="${target_dir_388c1ebe}/${target_filename}"
        else
            # 指定 --target-filename 指定 --target-directory
            target_filepath_388c1ebe="${target_dir_388c1ebe}/${target_filename}"
        fi
    fi

    if [ -e "$target_filepath_388c1ebe" ]; then
        lerror "mv file($path_388c1ebe) to dst($target_filepath_388c1ebe) failed, target file or directory($target_filepath_388c1ebe) exists"
        return "$SHELL_FALSE"
    fi

    # 创建父级目录
    file::create_parent_dir_recursive --sudo="$(string::print_yes_no "$is_sudo_388c1ebe")" --password="$password_388c1ebe" "$target_filepath_388c1ebe" || return "$SHELL_FALSE"

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo_388c1ebe")" --password="$password_388c1ebe" -- mv -f "$path_388c1ebe" "${target_filepath_388c1ebe}" || return "$SHELL_FALSE"

    if [ -R result_388c1ebe ] && [ -z "${result_388c1ebe}" ]; then
        result_388c1ebe="${target_filepath_388c1ebe}"
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
