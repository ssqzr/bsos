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

    if string::is_starts_with "$filepath" "~"; then
        filepath="${HOME}${filepath:1}"
    fi

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
# 构造一个具有随机字符串的路径
# 说明：
#   1. 指定 --path 将忽略 --parent 和 --name 参数
# 可选参数：
#   --path                          string              根据现有的路径来构造
#   --parent                        string              指定父级路径
#   --name                          string              指定基础文件名
#   --suffix                        string              指定后缀
# 位置参数：
# 标准输出： 构造的路径
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
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

    while true; do
        random_name=$(string::gen_random "$name" "" "$suffix") || return "$SHELL_FALSE"
        path="$parent/$random_name"
        if fs::path::is_not_exists "$path";then
            break
        fi
    done
    
    echo "$path"
    return "$SHELL_TRUE"
}


function fs::path::relative_path(){
    local base_path="$1"
    shift
    local path="$1"
    shift

    local relative_path

    if string::is_empty "${base_path}";then
        lerror "param base_path is required and can not empty"
        return "${SHELL_FALSE}"
    fi

    if string::is_empty "${path}";then
        lerror "param path is required and can not empty"
        return "${SHELL_FALSE}"
    fi

    base_path="$(fs::path::realpath "${base_path}")" || return "${SHELL_FALSE}"
    path="$(fs::path::realpath "${path}")" || return "${SHELL_FALSE}"

    if string::is_not_starts_with "${path}" "${base_path}";then
        lerror "base_path(${base_path}) is not base directory of path(${path})"
        return "${SHELL_FALSE}"
    fi

    relative_path="${path#"${base_path}"}"

    if string::is_starts_with "${relative_path}" "/";then
        relative_path="${relative_path:1}"
    fi

    echo "$relative_path"
    return "${SHELL_TRUE}"
}


function fs::path::join(){
    local base_path="$1"
    shift
    local relative_path="$1"
    shift

    local path

    if string::is_empty "${base_path}";then
        lerror "param base_path is required and can not empty"
        return "${SHELL_FALSE}"
    fi

    base_path="$(fs::path::realpath "${base_path}")" || return "${SHELL_FALSE}"

    path="${base_path}/${relative_path}"
    path="$(fs::path::realpath "${path}")" || return "${SHELL_FALSE}"

    echo "$path"
    return "${SHELL_TRUE}"
}

################################################### 下面是测试代码 ###################################################

function TEST::fs::path::realpath() {
    # 测试相对路径
    utest::assert_equal "$(fs::path::realpath "a/b/c")" "${PWD}/a/b/c"
    utest::assert_equal "$(fs::path::realpath "../../")" "$(dirname "$(dirname "$PWD")")"

    # 测试 . 和 ..
    utest::assert_equal "$(fs::path::realpath "/a/././b/c/d/../..")" "/a/b"
    utest::assert_equal "$(fs::path::realpath "/a/././b/c/d/./.")" "/a/b/c/d"

    # 测试 ~
    utest::assert_equal "$(fs::path::realpath $'~/a/b/c')" "${HOME}/a/b/c"

}


function TEST::fs::path::relative_path() {
    local relative_path
    utest::assert_equal "$(fs::path::relative_path "/a/b/c" "/a/b/c/d/e/f")" "d/e/f"
    utest::assert_equal "$(fs::path::relative_path "/a/b/c/" "/a/b/c/d/e/f")" "d/e/f"

    utest::assert_equal "$(fs::path::relative_path "/a/b/c" "/a/b/c")" ""
    utest::assert_equal "$(fs::path::relative_path "/a/b/c/" "/a/b/c")" ""
    utest::assert_equal "$(fs::path::relative_path "/a/b/c" "/a/b/c/")" ""

    relative_path="$(fs::path::relative_path "/a/b/c" "/a/b/d/e/f")"
    utest::assert_fail $?

    relative_path="$(fs::path::relative_path "/a/b/c" "/a/b/d/e/f/")"
    utest::assert_fail $?
}


function TEST::fs::path::join() {
    
    utest::assert_equal "$(fs::path::join "/a/b/c/" "")" "/a/b/c"
    utest::assert_equal "$(fs::path::join "/a/b/c/" "./")" "/a/b/c"
    utest::assert_equal "$(fs::path::join "/a/b/c/" "../")" "/a/b"

    utest::assert_equal "$(fs::path::join "/a/b/c" "/d/e/f")" "/a/b/c/d/e/f"
    utest::assert_equal "$(fs::path::join "/a/b/c/" "/d/e/f")" "/a/b/c/d/e/f"
    utest::assert_equal "$(fs::path::join "/a/b/c" "d/e/f")" "/a/b/c/d/e/f"
    utest::assert_equal "$(fs::path::join "/a/b/c/" "/d/e/f")" "/a/b/c/d/e/f"
}
