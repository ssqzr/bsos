#!/bin/bash

if [ -n "${SCRIPT_DIR_79b5ebff}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_79b5ebff="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_79b5ebff}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_79b5ebff}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_79b5ebff}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_79b5ebff}/../array.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_79b5ebff}/../string.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_79b5ebff}/../utest.sh" || exit 1

declare -i LOG_LEVEL_DEBUG=10
declare -i LOG_LEVEL_INFO=20
declare -i LOG_LEVEL_WARN=30
declare -i LOG_LEVEL_ERROR=40
declare -i LOG_LEVEL_SUCCESS=41

declare __log_level_backup=""

function log::level::signal::USR1() {
    local current_name
    local set_name

    println_info "SIGUSR1 received"

    current_name="$(log::level::level_name "${__log_level}")"
    if [ -z "${__log_level_backup}" ]; then
        set_name="$(log::level::level_name "${LOG_LEVEL_DEBUG}")"
        println_info "set log level from ${current_name} to ${set_name}"
        __log_level_backup="${__log_level}"
        log::level::set "$LOG_LEVEL_DEBUG"
        if [ $? -ne "$SHELL_TRUE" ]; then
            __log_level_backup=""
            return "$SHELL_FALSE"
        fi
    else
        set_name="$(log::level::level_name "${__log_level_backup}")"
        println_info "restore log level from ${current_name} to ${set_name}"
        log::level::set "${__log_level_backup}" || return "$SHELL_FALSE"
        __log_level_backup=""
    fi
    return "$SHELL_TRUE"
}

function log::level::_init() {
    if [ -z "${__log_level}" ]; then
        export __log_level="${LOG_LEVEL_INFO}"
    fi
    trap 'log::level::signal::USR1' USR1
}

function log::level::set() {
    local level="$1"
    if [ -z "$level" ]; then
        println_error --stream=stderr "invalid level: is empty"
        return "$SHELL_FALSE"
    fi
    if string::is_not_integer "$level"; then
        println_error --stream=stderr "invalid level: ${level} is not integer"
        return "$SHELL_FALSE"
    fi

    export __log_level="$level"
}

function log::level::is_pass() {
    local level="$1"
    if [ -z "$level" ]; then
        println_error --stream=stderr "invalid level: is empty"
        return "$SHELL_FALSE"
    fi
    if string::is_not_integer "$level"; then
        println_error --stream=stderr "invalid level: ${level} is not integer"
        return "$SHELL_FALSE"
    fi
    if [ "$level" -ge "$__log_level" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function log::level::is_not_pass() {
    local level="$1"
    log::level::is_pass "$level" || return "$SHELL_TRUE"
    return "$SHELL_FALSE"
}

function log::level::level_name() {
    local level="$1"
    local name

    if [ -z "$level" ]; then
        println_error --stream=stderr "invalid level: is empty"
        return "$SHELL_FALSE"
    fi
    if string::is_not_integer "$level"; then
        println_error --stream=stderr "invalid level: ${level} is not integer"
        return "$SHELL_FALSE"
    fi
    case "$level" in
    "$LOG_LEVEL_DEBUG")
        name="debug"
        ;;
    "$LOG_LEVEL_INFO")
        name="info"
        ;;
    "$LOG_LEVEL_WARN")
        name="warn"
        ;;
    "$LOG_LEVEL_ERROR")
        name="error"
        ;;
    "$LOG_LEVEL_SUCCESS")
        name="success"
        ;;
    *)
        println_error --stream=stderr "invalid level: ${level}"
        return "$SHELL_FALSE"
        ;;
    esac

    echo "$name"

    return "$SHELL_TRUE"
}

function log::level::_main() {
    log::level::_init || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

log::level::_main
