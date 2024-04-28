#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_383af515="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_383af515}/../utils/all.sh"

if [ -z "${__config_filepath}" ]; then
    __config_filepath="${HOME}/.config/bsos.yml"
    export __config_filepath="${__config_filepath}"
fi

# shellcheck source=/dev/null
source "${SCRIPT_DIR_383af515}/global.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_383af515}/app.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_383af515}/cache.sh"

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
