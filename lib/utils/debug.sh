#!/bin/bash

# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#index-FUNCNAME
# 获取调用层级 $level 的函数名
# 针对当前函数当前级数是0，上级是1，上上级是2
# 针对调用者，它期望的是以它为参考点，所以需要屏蔽当前函数自身的层级
# a->b->get_caller_function_name(1)时   返回a
function get_caller_function_name() {
    local level="$1"
    ((level += 1))
    local function_name="${FUNCNAME[${level}]}"
    echo "${function_name}"
}

# 获取调用者的调用者的所在文件名
# a->b->get_caller_filename   返回a函数所在的文件名
function get_caller_filename() {
    local level="$1"
    ((level += 1))
    local filepath=${BASH_SOURCE[${level}]}
    filepath=$(basename "${filepath}")
    echo "$filepath"
}

# 获取调用者的调用者的所在文件里的行数
# a->b->get_caller_file_line_num   返回a函数里调用b所在的文件里的行数
# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#index-BASH_005fLINENO
# ${BASH_LINENO[0]} 是上级函数的行号
# 当前行号是 $LINENO
function get_caller_file_line_num() {
    local level="$1"
    local line_num="${BASH_LINENO[${level}]}"
    echo "$line_num"
}

# 获取调用的堆栈
function get_caller_frame() {
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

# 获取时间
function get_human_datetime() {
    local datetime
    datetime="$(date '+%Y/%m/%d %H:%M:%S')"
    echo "$datetime"
}
