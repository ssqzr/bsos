#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_383af515="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_383af515}/../utils/all.sh"

# TODO: 本来想使用 toml 格式的，但是没有找到一个好用的cli工具
function config::_init() {
    if [ -z "${__config_filepath}" ]; then
        __config_filepath="${HOME}/.config/os_install.yml"
        export __config_filepath="${__config_filepath}"
    fi

    # shellcheck source=/dev/null
    source "${SCRIPT_DIR_383af515}/global.sh"
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR_383af515}/app.sh"
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR_383af515}/cache.sh"
}

function config::set_config_filepath() {
    local filepath="$1"
    if [ -z "$filepath" ]; then
        lerror "filepath is empty"
        return "$SHELL_FALSE"
    fi
    filepath=$(realpath "$filepath")

    if [ -d "$filepath" ]; then
        lerror "filepath(${filepath}) is directory"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "${filepath}" ]; then
        touch "${filepath}" || return "$SHELL_FALSE"
    fi

    export __config_filepath="${filepath}"
    return "$SHELL_TRUE"
}

function config::_main() {
    config::_init || return "$SHELL_FALSE"
}

config::_main
