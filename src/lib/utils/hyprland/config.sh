#!/bin/bash

if [ -n "${SCRIPT_DIR_a1329057}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_a1329057="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_a1329057}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a1329057}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a1329057}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a1329057}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_a1329057}/../fs/fs.sh"

function hyprland::config::add() {
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

    if hyprland::hyprctl::is_can_connect; then
        hyprland::hyprctl::reload || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function hyprland::config::remove() {
    local filename="$1"
    if string::is_empty "$filename"; then
        lerror "filename is empty"
        return "$SHELL_FALSE"
    fi
    fs::file::delete "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/conf.d/$filename" || return "$SHELL_FALSE"

    if hyprland::hyprctl::is_can_connect; then
        hyprland::hyprctl::reload || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}
