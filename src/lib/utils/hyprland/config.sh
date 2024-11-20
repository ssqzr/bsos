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

function hyprland::config::filepath() {
    local index="$1"
    shift
    local filename="$1"
    shift

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

    if string::is_empty "$index"; then
        lerror "get hyprland config failed, index is empty"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$filename"; then
        lerror "get hyprland config failed, filename is empty"
        return "$SHELL_FALSE"
    fi

    echo "${xdg_config_home}/hypr/conf.d/${index}-${filename}"
}

function hyprland::config::add() {
    local index="$1"
    shift
    local filepath="$1"
    shift

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local filename
    local dst

    if string::is_empty "$index"; then
        lerror "add hyprland config failed, index is empty"
        return "$SHELL_FALSE"
    fi
    if string::is_empty "$filepath"; then
        lerror "add hyprland config failed, filepath is empty"
        return "$SHELL_FALSE"
    fi
    if fs::path::is_not_exists "$filepath"; then
        lerror "add hyprland config failed, filepath($filepath) not exist"
        return "$SHELL_FALSE"
    fi

    filename=$(fs::path::basename "$filepath") || return "$SHELL_FALSE"
    dst=$(hyprland::config::filepath "$index" "$filename") || return "$SHELL_FALSE"

    fs::file::copy --force "$filepath" "${dst}" || return "$SHELL_FALSE"

    if hyprland::hyprctl::self::caller "is_can_connect"; then
        hyprland::hyprctl::self::caller "reload" || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function hyprland::config::remove() {
    local index="$1"
    shift
    local filename="$1"
    shift

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local filepath

    if string::is_empty "$index"; then
        lerror "remove hyprland config failed, index is empty"
        return "$SHELL_FALSE"
    fi
    if string::is_empty "$filename"; then
        lerror "remove hyprland config failed, filename is empty"
        return "$SHELL_FALSE"
    fi

    filepath=$(hyprland::config::filepath "$index" "$filename") || return "$SHELL_FALSE"
    fs::file::delete "${filepath}" || return "$SHELL_FALSE"

    if hyprland::hyprctl::self::caller "is_can_connect"; then
        hyprland::hyprctl::self::caller "reload" || return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}
