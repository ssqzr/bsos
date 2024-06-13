#!/bin/bash

if [ -n "${SCRIPT_DIR_28e227a8}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28e227a8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../fs/fs.sh"

# 判断是否可以连接到Hyprland
function hyprland::hyprctl::is_can_connect() {
    hyprland::hyprctl::version::tag >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprland::hyprctl::reload() {
    cmd::run_cmd_with_history -- hyprctl reload || return "$SHELL_FALSE"

    linfo "reload hyprland config success."

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::version::tag() {
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

function hyprland::hyprctl::getoption() {
    local option="$1"
    hyprctl -j getoption "$option"
}

function hyprland::hyprctl::getoption::decoration::rounding() {
    hyprland::hyprctl::getoption decoration:rounding | yq '.int' || return "$SHELL_FALSE"
}

function hyprland::hyprctl::monitors() {
    local value
    value=$(hyprctl -j monitors) || return "$SHELL_FALSE"
    echo "$value"
    return "$SHELL_TRUE"
}
