#!/bin/bash

if [ -n "${SCRIPT_DIR_2bf33118}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_2bf33118="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_2bf33118}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2bf33118}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2bf33118}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_2bf33118}/../fs/fs.sh"

function zsh::config::filepath() {
    local index="$1"
    shift
    local filename="$1"
    shift

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

    if string::is_empty "$index"; then
        lerror "get zsh config failed, index is empty"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$filename"; then
        lerror "get zsh config failed, filename is empty"
        return "$SHELL_FALSE"
    fi

    echo "${xdg_config_home}/zsh/zshrc.d/${index}-${filename}"
}

function zsh::config::add() {
    local index="$1"
    shift
    local filepath="$1"
    shift

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local filename
    local dst

    if string::is_empty "$index"; then
        lerror "add zsh config failed, index is empty"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$filepath"; then
        lerror "add zsh config failed, filepath is empty"
        return "$SHELL_FALSE"
    fi

    if fs::path::is_not_exists "$filepath"; then
        lerror "add zsh config failed, filepath($filepath) not exists"
        return "$SHELL_FALSE"
    fi

    filename=$(fs::path::basename "$filepath") || return "$SHELL_FALSE"
    dst=$(zsh::config::filepath "$index" "$filename") || return "$SHELL_FALSE"

    fs::file::copy --force "${filepath}" "${dst}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function zsh::config::remove() {
    local index="$1"
    shift
    local filename="$1"
    shift

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local filepath

    if string::is_empty "$index"; then
        lerror "remove zsh config failed, index is empty"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$filename"; then
        lerror "remove zsh config failed, filename is empty"
        return "$SHELL_FALSE"
    fi

    filepath=$(zsh::config::filepath "$index" "$filename") || return "$SHELL_FALSE"

    fs::file::delete "${filepath}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
