#!/bin/bash

if [ -n "${SCRIPT_DIR_be9d7ae3}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_be9d7ae3="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_be9d7ae3}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_be9d7ae3}/../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_be9d7ae3}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_be9d7ae3}/../parameter.sh"

declare __valid_type=("json")

for type in "${__valid_type[@]}"; do
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR_be9d7ae3}/${type}/trait.sh"
done

function cfg::_check_type() {
    local type="$1"
    shift

    if array::is_not_contain __valid_type "$type"; then
        lerror "invalid config type: $type"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

########################################### map 相关 API ###########################################

function cfg::map::get() {
    local type="json"
    local key
    local data
    local param

    if fs::path::is_pipe "/dev/stdin"; then
        data="$(</dev/stdin)"
    fi

    for param in "$@"; do
        case "$param" in
        --type=*)
            parameter::parse_string --default=json --option="$param" type || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "invalid option: $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v key ]; then
                key="$param"
                continue
            fi

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v type ]; then
        lerror "param type is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$type"; then
        lerror "param type is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v key ]; then
        lerror "param key is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$key"; then
        lerror "param key is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$data"; then
        lerror "param data is empty"
        return "$SHELL_FALSE"
    fi

    cfg::_check_type "$type" || return "$SHELL_FALSE"

    "cfg::trait::$type::map::get" "$key" "$data" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

########################################### array 相关 API ###########################################

function cfg::array::length() {
    local type="json"
    local data
    local param

    if fs::path::is_pipe "/dev/stdin"; then
        data="$(</dev/stdin)"
    fi

    for param in "$@"; do
        case "$param" in
        --type=*)
            parameter::parse_string --default=json --option="$param" type || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "invalid option: $param"
            return "$SHELL_FALSE"
            ;;
        *)

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v type ]; then
        lerror "param type is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$type"; then
        lerror "param type is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$data"; then
        lerror "param data is empty"
        return "$SHELL_FALSE"
    fi

    cfg::_check_type "$type" || return "$SHELL_FALSE"

    "cfg::trait::$type::array::length" "$data" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function cfg::array::first() {
    local type="json"
    local data
    local param

    if fs::path::is_pipe "/dev/stdin"; then
        data="$(</dev/stdin)"
    fi

    for param in "$@"; do
        case "$param" in
        --type=*)
            parameter::parse_string --default=json --option="$param" type || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "invalid option: $param"
            return "$SHELL_FALSE"
            ;;
        *)

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v type ]; then
        lerror "param type is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$type"; then
        lerror "param type is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$data"; then
        lerror "param data is empty"
        return "$SHELL_FALSE"
    fi

    cfg::_check_type "$type" || return "$SHELL_FALSE"

    "cfg::trait::$type::array::first" "$data" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function cfg::array::last() {
    local type="json"
    local data
    local param

    if fs::path::is_pipe "/dev/stdin"; then
        data="$(</dev/stdin)"
    fi

    for param in "$@"; do
        case "$param" in
        --type=*)
            parameter::parse_string --default=json --option="$param" type || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "invalid option: $param"
            return "$SHELL_FALSE"
            ;;
        *)

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v type ]; then
        lerror "param type is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$type"; then
        lerror "param type is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$data"; then
        lerror "param data is empty"
        return "$SHELL_FALSE"
    fi

    cfg::_check_type "$type" || return "$SHELL_FALSE"

    "cfg::trait::$type::array::last" "$data" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function cfg::array::get() {
    local type="json"
    local index
    local data
    local param

    if fs::path::is_pipe "/dev/stdin"; then
        data="$(</dev/stdin)"
    fi

    for param in "$@"; do
        case "$param" in
        --type=*)
            parameter::parse_string --default=json --option="$param" type || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "invalid option: $param"
            return "$SHELL_FALSE"
            ;;
        *)

            if [ ! -v index ]; then
                index="$param"
                continue
            fi

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v type ]; then
        lerror "param type is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$type"; then
        lerror "param type is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v index ]; then
        lerror "param index is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$index"; then
        lerror "param index is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$data"; then
        lerror "param data is empty"
        return "$SHELL_FALSE"
    fi

    cfg::_check_type "$type" || return "$SHELL_FALSE"

    "cfg::trait::$type::array::get" "$index" "$data" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function cfg::array::filter_by_key_value() {
    local type="json"
    local key
    local value
    local data
    local param

    if fs::path::is_pipe "/dev/stdin"; then
        data="$(</dev/stdin)"
    fi

    for param in "$@"; do
        case "$param" in
        --type=*)
            parameter::parse_string --default=json --option="$param" type || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "invalid option: $param"
            return "$SHELL_FALSE"
            ;;
        *)

            if [ ! -v key ]; then
                key="$param"
                continue
            fi

            if [ ! -v value ]; then
                value="$param"
                continue
            fi

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v type ]; then
        lerror "param type is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$type"; then
        lerror "param type is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v key ]; then
        lerror "param key is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$key"; then
        lerror "param key is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v value ]; then
        lerror "param value is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$value"; then
        lerror "param value is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v data ]; then
        lerror "param data is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$data"; then
        lerror "param data is empty"
        return "$SHELL_FALSE"
    fi

    cfg::_check_type "$type" || return "$SHELL_FALSE"

    "cfg::trait::$type::array::filter_by_key_value" "$key" "$value" "$data" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
