#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28e227a8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/string.sh"

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
