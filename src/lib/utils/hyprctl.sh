#!/bin/bash

if [ -n "${SCRIPT_DIR_28e227a8}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28e227a8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/fs/fs.sh"

# 判断是否可以连接到Hyprland
function hyprctl::is_can_connect() {
    hyprctl::version::tag >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprctl::reload() {
    cmd::run_cmd_with_history -- hyprctl reload || return "$SHELL_FALSE"

    linfo "reload hyprland config success."

    return "$SHELL_TRUE"
}

function hyprctl::config::add() {
    local filepath="$1"
    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local filename

    if string::is_empty "$filepath"; then
        lerror "filepath is empty"
        return "$SHELL_FALSE"
    fi
    if fs::path::is_not_exists "$filepath"; then
        lerror "filepath($filepath) not exist"
        return "$SHELL_FALSE"
    fi

    filename=$(fs::path::basename "$filepath")

    fs::file::copy --force "$filepath" "${xdg_config_home}/hypr/conf.d/$filename" || return "$SHELL_FALSE"

    if hyprctl::is_can_connect; then
        hyprctl::reload || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function hyprctl::config::remove() {
    local filename="$1"
    if string::is_empty "$filename"; then
        lerror "filename is empty"
        return "$SHELL_FALSE"
    fi
    file::remove_file_dir --force "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/conf.d/$filename" || return "$SHELL_FALSE"

    if hyprctl::is_can_connect; then
        hyprctl::reload || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

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
