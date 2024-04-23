#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28e227a8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/string.sh"

function hyprctl::version::tag() {
    local tag
    local temp_str
    temp_str=$(hyprctl -j version)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland version failed, err=${temp_str}"
        return "$SHELL_FALSE"
    fi
    tag=$(echo "$temp_str" | yq '.tag' 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland version tag failed, err=${tag}"
        return "$SHELL_FALSE"
    fi
    echo "$tag"
    return "$SHELL_TRUE"
}

# 判断是否可以连接到Hyprland
function hyprctl::is_can_connect() {
    hyprctl::version::tag >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprctl::decoration::rounding::value() {
    hyprctl -j getoption decoration:rounding | yq '.int' || return "$SHELL_FALSE"
}

function hyprctl::decoration::rounding::is_set() {
    local is_set
    is_set=$(hyprctl -j getoption decoration:rounding | yq '.set') || return "$SHELL_FALSE"
    string::is_true "$is_set"
}

function hyprctl::monitors::focused::option() {
    local name="$1"
    local value
    value=$(hyprctl -j monitors | yq ".[] | select(.focused==true) | .${name}") || return "$SHELL_FALSE"
    echo "$value"
    return "$SHELL_TRUE"
}
