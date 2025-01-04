#!/bin/bash

if [ -n "${SCRIPT_DIR_dcaf0b8c}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_dcaf0b8c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_dcaf0b8c}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_dcaf0b8c}/cmd.sh"

function process::is_running() {
    local process_name="$1"
    local lines
    lines=$(pgrep -a -x "$process_name")
    if [ -z "$lines" ]; then
        ldebug "find process($process_name) is not running"
        return "$SHELL_FALSE"
    fi

    ldebug "find process($process_name) is running, output lines: $lines"
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
    process::is_running "$process_name"
    if [ $? -eq "$SHELL_FALSE" ]; then
        ldebug "process($process_name) is not running"
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history -- pkill -x "$process_name" || return "$SHELL_FALSE"
    linfo "kill process($process_name) success"
    return "$SHELL_TRUE"
}

function process::get_username() {
    local pid="$1"

    ps -o uname= -p "$pid"

    return "$SHELL_TRUE"
}
