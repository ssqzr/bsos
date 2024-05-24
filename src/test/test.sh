#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_98e0c032="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

SRC_DIR="$(dirname "${SCRIPT_DIR_98e0c032}")"
SRC_DIR="$(realpath "${SRC_DIR}")"

# shellcheck disable=SC1091
source "${SRC_DIR}/lib/utils/all.sh"

function test_runner::filter_by_file() {
    local -n test_case_b2189f50="$1"
    local filter_b2189f50="$2"
    local files_b2189f50=()
    local temp_str_b2189f50
    local filepath_b2189f50
    local functions_b2189f50
    local function_name_b2189f50

    # 通过文件名过滤
    temp_str_b2189f50=$(find "${SRC_DIR}" -type f -name "*${filter_b2189f50}*")
    readarray -t files_b2189f50 < <(echo "$temp_str_b2189f50")
    for filepath_b2189f50 in "${files_b2189f50[@]}"; do
        if [ -z "$filepath_b2189f50" ]; then
            continue
        fi

        temp_str_b2189f50=$(grep -o -E "TEST::[^(]+" "$filepath_b2189f50")
        readarray -t functions_b2189f50 < <(echo "$temp_str_b2189f50")
        for function_name_b2189f50 in "${functions_b2189f50[@]}"; do
            if [ -z "$function_name_b2189f50" ]; then
                continue
            fi

            test_case_b2189f50+=("$function_name_b2189f50")
        done
    done

    return "$SHELL_TRUE"
}

function test_runner::filter_by_function_name() {
    local -n test_case_fc3910dc="$1"
    local filter_fc3910dc="$2"
    local functions_fc3910dc=()
    local temp_str_fc3910dc
    local function_name_fc3910dc

    # 通过函数名过滤
    temp_str_fc3910dc=$(compgen -A function | grep "^TEST::" | grep -E "$filter_fc3910dc")
    readarray -t functions_fc3910dc < <(echo "$temp_str_fc3910dc")
    for function_name_fc3910dc in "${functions_fc3910dc[@]}"; do
        if [ -z "$function_name_fc3910dc" ]; then
            continue
        fi
        test_case_fc3910dc+=("$function_name_fc3910dc")
    done
    return "$SHELL_TRUE"
}

# https://stackoverflow.com/questions/4471364/how-do-i-list-the-functions-defined-in-my-shell
function test_runner::run() {
    local filter="${1:-TEST::}"
    local temp_array=()
    local temp_str
    local test_case=()

    log::handler::file_handler::register || exit 1
    log::handler::file_handler::set_log_file "${SRC_DIR}/../utest.log" || exit 1

    # 找出所有有测试代码的文件
    temp_str=$(grep "^function TEST::" -rn "${SRC_DIR}" | awk -F ':' '{print $1}')
    if [ $? -ne "$SHELL_TRUE" ]; then
        println_error "not found any test in ${SRC_DIR}"
        return "$SHELL_FALSE"
    fi
    readarray -t temp_array < <(echo "$temp_str")
    array::dedup temp_array
    for temp_str in "${temp_array[@]}"; do
        if [ -z "$temp_str" ]; then
            continue
        fi
        # shellcheck disable=SC1090
        source "$temp_str"
    done

    # 查找所有的测试函数
    test_runner::filter_by_file test_case "$filter"
    test_runner::filter_by_function_name test_case "$filter"

    array::dedup test_case
    array::remove_empty test_case

    # 排序
    temp_str=$(printf "%s\n" "${test_case[@]}" | sort)
    test_case=()
    readarray -t test_case < <(echo "$temp_str")

    # 执行
    for temp_str in "${test_case[@]}"; do
        $temp_str
    done
}

test_runner::run "$@"
