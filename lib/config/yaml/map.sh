#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_2a55cfdf="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_2a55cfdf}/../../utils/all.sh"

function config::map::get() {
    local path="$1"
    local key="$2"
    local filepath="$3"
    local value
    value=$(yq "${path}.[\"${key}\"]" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get map value failed, path=${path}, key: ${key}, filepath=${filepath}, err=${value}"
        return "$SHELL_FALSE"
    fi

    if [ "$value" == "null" ]; then
        value=""
    fi
    echo "${value}"
}

function config::map::set() {
    local path="$1"
    local key="$2"
    local value="$3"
    local filepath="$4"
    local output
    output=$(VAL="${value}" yq -i "${path}.[\"${key}\"] = strenv(VAL)" "${filepath}" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "set map value failed, path=${path}, key: ${key}, value=${value}, filepath=${filepath}, err=${output}"
        return "$SHELL_FALSE"
    fi
}
