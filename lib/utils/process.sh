#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_dcaf0b8c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_dcaf0b8c}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dcaf0b8c}/cmd.sh"

function process::is_running() {
    local process_name="$1"
    local pids
    pids=$(pgrep -f "$process_name" | tr '\n' ' ')
    if [ -z "$pids" ]; then
        ldebug "find process($process_name) is not running"
        return "$SHELL_FALSE"
    fi

    ldebug "find process($process_name) is running, pids=$pids"
    return "$SHELL_TRUE"
}

function process::kill_by_pid() {
    local pid="$1"
    local output

    output=$(kill "$pid" 2>&1)
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "kill process($pid) error=$output"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

function process::kill_by_name() {
    local process_name="$1"
    local pids
    pids=$(pgrep -f "$process_name" | tr '\n' ' ')
    if [ -z "$pids" ]; then
        ldebug "find process($process_name) is not running"
        return "$SHELL_TRUE"
    fi

    linfo "find process($process_name) is running, pids=$pids"

    local pid
    for pid in $pids; do
        process::kill_by_pid "$pid" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}
