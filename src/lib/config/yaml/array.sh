#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_4295d696="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_4295d696}/../../utils/all.sh"

function config::array::length() {
    local path="$1"
    local filepath="$2"
    local length
    # 即使路径不存在，也会返回0，路径不存在并不是异常
    length=$(yq "${path} | length" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "config get array length failed, path=${path}, filepath=${filepath}, err=${length}"
        return "$SHELL_FALSE"
    fi
    echo "$length"
    return "$SHELL_TRUE"
}

function config::array::first() {
    local path="$1"
    local filepath="$2"
    local value
    local length
    length=$(config::array::length "$path" "${filepath}") || return "$SHELL_FALSE"

    if [ "$length" == "0" ]; then
        # 没有元素了
        return "$SHELL_TRUE"
    fi

    value=$(yq "${path}.[0]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array get first value failed, path=${path}, filepath=${filepath}, err=${value}"
        return "$SHELL_FALSE"
    fi
    if [ "$value" == "null" ]; then
        value=""
    fi
    echo "$value"
}

function config::array::last() {
    local path="$1"
    local filepath="$2"
    local value
    local length
    length=$(config::array::length "$path" "${filepath}") || return "$SHELL_FALSE"

    if [ "$length" == "0" ]; then
        # 没有元素了
        return "$SHELL_TRUE"
    fi

    value=$(yq "${path}.[-1]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array get last value failed, path=${path}, filepath=${filepath}, err=${value}"
        return "$SHELL_FALSE"
    fi
    if [ "$value" == "null" ]; then
        value=""
    fi
    echo "$value"
}

function config::array::is_contain() {
    local path="$1"
    local value="$2"
    local filepath="$3"
    local output
    output=$(VAL="${value}" yq "${path}[] | select(. == strenv(VAL))" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array is_contain failed, path=${path}, value=${value}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi

    if [ -n "$output" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function config::array::lpush() {
    local path="$1"
    local value="$2"
    local filepath="$3"
    local output
    output=$(VAL="${value}" yq -i "${path} |= [strenv(VAL)] + .[0:]" "${filepath}" 2>&1)

    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array lpush failed, path=${path}, value=${value}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
}

function config::array::rpush() {
    local path="$1"
    local value="$2"
    local filepath="$3"
    local output
    output=$(VAL="${value}" yq -i "${path} += [strenv(VAL)]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "array rpush failed, path=${path}, value=${value}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
}

function config::array::lpush_unique() {
    local path="$1"
    local value="$2"
    local filepath="$3"
    if config::array::is_contain "$path" "$value" "${filepath}"; then
        return "$SHELL_TRUE"
    fi
    config::array::lpush "$path" "$value" "${filepath}" || return "$SHELL_FALSE"
}

function config::array::rpush_unique() {
    local path="$1"
    local value="$2"
    local filepath="$3"
    if config::array::is_contain "$path" "$value" "${filepath}"; then
        return "$SHELL_TRUE"
    fi
    config::array::rpush "$path" "$value" "${filepath}" || return "$SHELL_FALSE"
}

function config::array::lpop() {
    local path="$1"
    local filepath="$2"
    local value
    local output
    local length
    length=$(config::array::length "$path" "${filepath}") || return "$SHELL_FALSE"

    if [ "$length" == "0" ]; then
        # 没有元素了
        return "$SHELL_TRUE"
    fi

    value=$(yq "${path}.[0]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "lpop array get first item failed, path=${path}, filepath=${filepath}, err=${value}"
        return "$SHELL_FALSE"
    fi
    # 删除第一个元素
    output=$(yq -i "del(${path}[0])" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "lpop array failed, path=${path}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
    if [ "$value" == "null" ]; then
        value=""
    fi

    echo "${value}"
}

function config::array::rpop() {
    local path="$1"
    local filepath="$2"
    local value
    local output

    local length
    length=$(config::array::length "$path" "${filepath}") || return "$SHELL_FALSE"

    if [ "$length" == "0" ]; then
        # 没有元素了
        return "$SHELL_TRUE"
    fi

    value=$(yq "${path}.[-1]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "rpop array get last item failed, path=${path}, filepath=${filepath}, err=${value}"
        return "$SHELL_FALSE"
    fi
    # 删除最后一个元素
    output=$(yq -i "del(${path}[-1])" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "rpop array failed, path=${path}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
    if [ "$value" == "null" ]; then
        value=""
    fi

    echo "${value}"
}

# 如果有多个重复的元素，都会被删除
function config::array::remove() {
    local path="$1"
    local value="$2"
    local filepath="$3"
    local output
    output=$(VAL="${value}" yq -i "del( ${path}[] | select(. == strenv(VAL)) )" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "remove array item failed, path=${path}, value=${value}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
}

# 去重
function config::array::dedup() {
    local path="$1"
    local filepath="$2"
    local output
    output=$(yq -i "${path} |= unique" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "unique array failed, path=${path}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
}

function config::array::get() {
    local path="$1"
    local filepath="$2"
    local value
    value=$(yq "${path}[]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "config get array failed, path=${path}, filepath=${filepath}, err=${value}"
        return "$SHELL_FALSE"
    fi
    if [ "$value" == "null" ]; then
        value=""
    fi
    echo "${value}"
}

# 清空列表
function config::array::clean() {
    local path="$1"
    local filepath="$2"
    local output
    output=$(yq -i "${path} = []" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "config clean array failed, path=${path}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function config::array::set() {
    local path_43639596="$1"
    local -n array_43639596=$2
    local filepath_43639596="$3"

    # FIXME: 分多次就导致原子性的问题。
    # 如果一次性添加所有元素，特殊字符不知道怎么处理
    local item_43639596
    for item_43639596 in "${array_43639596[@]}"; do
        config::array::rpush "${path_43639596}" "${item_43639596}" "${filepath_43639596}" || return "$SHELL_FALSE"
    done
    return $?
}
