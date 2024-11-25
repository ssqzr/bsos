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
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../process.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../os.sh"

function hyprland::hyprctl::instance::all() {
    # shellcheck disable=SC2034
    local -n instances_d2d9c003="$1"
    shift

    local temp_d2d9c003

    # FIXME: 当 /run/user/1000/hypr 目录不存在时，执行 hyprctl 会出错
    # https://github.com/hyprwm/Hyprland/issues/8579
    temp_d2d9c003=$(hyprctl instances -j 2> >(lwrite)) || return "$SHELL_FALSE"
    temp_d2d9c003=$(echo "${temp_d2d9c003}" | grep instance | awk -F '"' '{print $4}')

    array::readarray instances_d2d9c003 <<<"${temp_d2d9c003}"

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::pid() {
    local instance="$1"

    local pid

    pid="$(hyprctl instances -j)" || return "$SHELL_FALSE"
    pid=$(echo "${pid}" | yq ".[] | select(.instance == \"${instance}\") | .pid") || return "$SHELL_FALSE"

    echo "$pid"

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::all_by_username() {
    # shellcheck disable=SC2034
    local -n instances_22de1eba="$1"
    shift
    local username_22de1eba="$1"
    shift

    local all_22de1eba=()
    local temp_22de1eba
    local pid_22de1eba
    local process_username_22de1eba

    hyprland::hyprctl::instance::all all_22de1eba || return "$SHELL_FALSE"

    instances_22de1eba=()
    for temp_22de1eba in "${all_22de1eba[@]}"; do
        pid_22de1eba=$(hyprland::hyprctl::instance::pid "$temp_22de1eba") || return "$SHELL_FALSE"
        process_username_22de1eba=$(process::get_username "$pid_22de1eba") || return "$SHELL_FALSE"
        if [ "$process_username_22de1eba" == "$username_22de1eba" ]; then
            instances_22de1eba+=("$temp_22de1eba")
        fi
    done

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::version() {
    local instance="$1"
    shift

    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    local temp_str
    temp_str=$(hyprctl -j version "${instance_params[@]}") || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland version failed, instance=${instance}, err=${temp_str}"
        return "$SHELL_FALSE"
    fi
    echo "$temp_str"
    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::version::tag() {
    local instance="$1"
    shift

    local tag
    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    tag=$(hyprctl -j version "${instance_params[@]}") || return "$SHELL_FALSE"
    tag=$(echo "$tag" | yq '.tag') || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland version tag failed, instance=${instance}, err=${tag}"
        return "$SHELL_FALSE"
    fi
    echo "$tag"
    return "$SHELL_TRUE"
}

# instance 为空获取当前实例
function hyprland::hyprctl::instance::is_can_connect() {
    local instance="$1"

    hyprland::hyprctl::instance::version "$instance" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::is_not_can_connect() {
    ! hyprland::hyprctl::instance::is_can_connect "$@"
}

function hyprland::hyprctl::instance::reload() {
    local instance="$1"
    shift

    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl reload "${instance_params[@]}" || return "$SHELL_FALSE"

    linfo "reload hyprland config success. instance=${instance}"

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::autoreload::disable() {
    local instance="$1"
    shift

    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl keyword "misc:disable_autoreload" true "${instance_params[@]}" || return "$SHELL_FALSE"

    linfo "disable hyprland config autoreload success. instance=${instance}"

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::autoreload::enable() {
    local instance="$1"
    shift

    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl keyword "misc:disable_autoreload" false "${instance_params[@]}" || return "$SHELL_FALSE"

    linfo "disable hyprland config autoreload success. instance=${instance}"

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::getoption() {
    local option="$1"
    shift
    local instance="$1"
    shift

    local temp
    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    temp=$(hyprctl -j getoption "$option" "${instance_params[@]}")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland option failed, instance=${instance}, option=${option}, err=${temp}"
        return "$SHELL_FALSE"
    fi
    echo "$temp"
    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::monitors() {
    local instance="$1"

    local value
    local instance_params=()

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    value=$(hyprctl -j monitors "${instance_params[@]}") || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland monitors failed, instance=${instance}, err=${value}"
        return "$SHELL_FALSE"
    fi

    echo "$value"

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::self::caller() {
    local caller="$1"
    shift

    local instances
    local instance

    hyprland::hyprctl::instance::all_by_username instances "$(os::user::name)" || return "$SHELL_FALSE"

    if array::is_empty instances; then
        linfo "hyprland self caller(${caller}) failed, no instance to call."
        return "$SHELL_FALSE"
    fi

    for instance in "${instances[@]}"; do
        "hyprland::hyprctl::instance::${caller}" "$@" "$instance" || return "$SHELL_FALSE"
        linfo "hyprland self ${caller} success. instance=${instance}"
    done

    linfo "hyprland self ${caller} all instance success."

    return "$SHELL_TRUE"
}

function hyprland::hyprctl::self::caller_first() {
    local caller="$1"
    shift

    local instances
    local instance

    hyprland::hyprctl::instance::all_by_username instances "$(os::user::name)" || return "$SHELL_FALSE"

    if array::is_empty instances; then
        linfo "hyprland self caller_first(${caller}) failed, no instance to call."
        return "$SHELL_FALSE"
    fi

    for instance in "${instances[@]}"; do
        "hyprland::hyprctl::instance::${caller}" "$@" "$instance" || return "$SHELL_FALSE"
        linfo "hyprland self caller_first(${caller}) success. instance=${instance}"
        return "$SHELL_TRUE"
    done

    return "$SHELL_TRUE"
}
