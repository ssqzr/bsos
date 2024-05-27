#!/bin/bash

if [ -n "${SCRIPT_DIR_54c4d7cd}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_54c4d7cd="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#index-FUNCNAME
# 获取调用层级 $level 的函数名
# 针对当前函数当前级数是0，上级是1，上上级是2
# 针对调用者，它期望的是以它为参考点，所以需要屏蔽当前函数自身的层级
# a->b->debug::function::name(1)时   返回a
function debug::function::name() {
    local level="$1"
    ((level += 1))
    local function_name="${FUNCNAME[${level}]}"
    echo "${function_name}"
}

function debug::function::filepath() {
    local level="${1:-0}"
    ((level += 1))
    local filepath=${BASH_SOURCE[${level}]}
    filepath="$(realpath -s "${filepath}")"
    echo "$filepath"
    return "$SHELL_FALSE"
}

# 获取调用者的调用者的所在文件名
# a->b->debug::function::filename   返回a函数所在的文件名
function debug::function::filename() {
    local level="${1:-0}"
    local filename

    ((level += 1))
    filename="$(debug::function::filepath "${level}")"
    filename=$(basename "${filename}")
    echo "$filename"
}

# 获取调用者的调用者的所在文件里的行数
# a->b->debug::function::line_number   返回a函数里调用b所在的文件里的行数
# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#index-BASH_005fLINENO
# ${BASH_LINENO[0]} 是上级函数的行号
# 当前行号是 $LINENO
function debug::function::line_number() {
    local level="$1"
    local line_num="${BASH_LINENO[${level}]}"
    echo "$line_num"
}

# 获取调用的堆栈
function debug::function::call_stack() {
    local ignore_level="$1"
    if [ -z "$ignore_level" ]; then
        ignore_level=0
    fi
    ((ignore_level += 1))

    local frame

    local name
    for name in "${FUNCNAME[@]:${ignore_level}}"; do
        if [ "$frame" = "" ]; then
            frame="${name}"
            continue
        fi
        frame="${name}->${frame}"
    done
    echo "$frame"
}

# 不使用 grep ，尽可能对外部依赖少
function debug::function::is_exists() {
    local name="$1"
    local all_functions=()
    local temp_str

    temp_str="$(compgen -A function)"
    readarray -t all_functions < <(echo "$temp_str")
    for temp_str in "${all_functions[@]}"; do
        if [ "$temp_str" == "$name" ]; then
            return "$SHELL_TRUE"
        fi
    done
    return "$SHELL_FALSE"
}

function debug::function::is_not_exists() {
    local name="$1"
    debug::function::is_exists "$name" || return "$SHELL_TRUE"
    return "$SHELL_FALSE"
}
