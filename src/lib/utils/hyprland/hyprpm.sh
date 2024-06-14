#!/bin/bash

if [ -n "${SCRIPT_DIR_35cc3ba9}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_35cc3ba9="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_35cc3ba9}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_35cc3ba9}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_35cc3ba9}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_35cc3ba9}/../cmd.sh"

function hyprland::hyprpm::repository::is_exists() {
    local name="$1"
    hyprpm list | grep -q -E "Repository ${name}"
    if [ $? -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi

    return "$SHELL_FALSE"
}

function hyprland::hyprpm::repository::is_not_exists() {
    ! hyprland::hyprpm::repository::is_exists "$@"
}

function hyprland::hyprpm::repository::remove() {
    local name="$1"

    if hyprland::hyprpm::repository::is_not_exists "$name"; then
        linfo "repository ${name} is not exists, remove success."
        return "${SHELL_TRUE}"
    fi

    cmd::run_cmd_with_history -- printf y '|' hyprpm -v remove "$name"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "repository(${name}) remove failed"
        return "${SHELL_FALSE}"
    fi

    linfo "repository(${name}) remove success"
    return "${SHELL_TRUE}"
}

function hyprland::hyprpm::repository::list() {
    # shellcheck disable=SC2034
    local -n repository_12ec5245="$1"
    local temp_str_12ec5245
    temp_str_12ec5245=$(hyprpm list | grep -o -E "Repository [^:]+" | awk '{print $2}')
    array::readarray repository_12ec5245 < <(echo "${temp_str_12ec5245}")

    return "${SHELL_TRUE}"
}

function hyprland::hyprpm::plugin::enable() {
    local name="$1"

    cmd::run_cmd_with_history -- hyprpm -v enable "$name"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "plugin(${name}) enable failed"
        return "${SHELL_FALSE}"
    fi
    linfo "plugin(${name}) enable success"
    return "${SHELL_TRUE}"
}

function hyprland::hyprpm::clean() {
    # 删除插件
    local repository
    local item
    hyprland::hyprpm::repository::list repository || return "${SHELL_FALSE}"

    for item in "${repository[@]}"; do
        hyprland::hyprpm::repository::remove "${item}" || return "${SHELL_FALSE}"
    done

    linfo "clean all hyprland plugins success"
}

function hyprland::hyprpm::update() {
    cmd::run_cmd_with_history -- hyprpm update -v
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "hyprpm update failed"
        return "${SHELL_FALSE}"
    fi

    linfo "hyprpm update success"
    return "${SHELL_TRUE}"
}

function hyprland::hyprpm::reload() {
    cmd::run_cmd_with_history -- hyprpm reload -v
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "hyprpm reload failed"
        return "${SHELL_FALSE}"
    fi

    linfo "hyprpm reload success"
    return "${SHELL_TRUE}"
}
