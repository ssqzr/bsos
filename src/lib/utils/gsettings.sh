#!/bin/bash

if [ -n "${SCRIPT_DIR_d7eac859}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d7eac859="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_d7eac859}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_d7eac859}/log.sh"

# 可能的值为：
# 1. default
# 2. xxx-dark
# 3. xxx-light
function gsettings::color_scheme() {
    gsettings get org.gnome.desktop.interface color-scheme | sed "s/'//g"
}

# 返回值为 dark 或 light 或 ""
function gsettings::color_scheme_mode() {
    local color_scheme
    local color_scheme_mode
    color_scheme="$(gsettings::color_scheme)" || return "$SHELL_FALSE"
    color_scheme_mode=$(echo "$color_scheme" | awk -F '-' '{print $2}') || return "$SHELL_FALSE"
    echo "$color_scheme_mode"
}
