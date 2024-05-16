#!/bin/bash

if [ -n "${SCRIPT_DIR_ecd3403f}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_ecd3403f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_ecd3403f}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_ecd3403f}/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_ecd3403f}/cmd.sh"

function systemctl::is_exists() {
    local unit="$1"
    systemctl list-unit-files | grep -E -q "^$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        ldebug "unit($unit) is not exists"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function systemctl::is_active() {
    local unit="$1"
    # systemctl -q is-active 的退出码如果是 4 表示 unit 不存在，这里还是通过封装函数判断
    if ! systemctl::is_exists "$unit"; then
        return "$SHELL_FALSE"
    fi
    systemctl -q is-active "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function systemctl::is_enabled() {
    local unit="$1"
    # systemctl -q is-enabled 的退出码如果是 4 表示 unit 不存在，这里还是通过封装函数判断
    if ! systemctl::is_exists "$unit"; then
        return "$SHELL_FALSE"
    fi
    systemctl -q is-enabled "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# 重复 enable 不会报错，返回码也是0
# systemctl -q 可以不输出任何信息，但是还是将输出记录到日志，方便排查问题
function systemctl::enable() {
    local unit="$1"
    cmd::run_cmd_with_history sudo systemctl enable "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "systemctl enable $unit failed"
        return "$SHELL_FALSE"
    fi
    linfo "systemctl enable $unit success"
    return "$SHELL_TRUE"
}

# 重复 disable 不会报错，返回码也是0
function systemctl::disable() {
    local unit="$1"
    cmd::run_cmd_with_history sudo systemctl disable "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "systemctl disable $unit failed"
        return "$SHELL_FALSE"
    fi
    linfo "systemctl disable $unit success"
    return "$SHELL_TRUE"
}

# 重复 start 不会报错，返回码也是0
function systemctl::start() {
    local unit="$1"
    cmd::run_cmd_with_history sudo systemctl start "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "systemctl start $unit failed"
        return "$SHELL_FALSE"
    fi
    linfo "systemctl start $unit success"
    return "$SHELL_TRUE"
}

# 重复 stop 不会报错，返回码也是0
function systemctl::stop() {
    local unit="$1"
    cmd::run_cmd_with_history sudo systemctl stop "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "systemctl stop $unit failed"
        return "$SHELL_FALSE"
    fi
    linfo "systemctl stop $unit success"
    return "$SHELL_TRUE"
}

# 重复 restart 不会报错，返回码也是0
function systemctl::restart() {
    local unit="$1"
    cmd::run_cmd_with_history sudo systemctl restart "$unit"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "systemctl restart $unit failed"
        return "$SHELL_FALSE"
    fi
    linfo "systemctl restart $unit success"
    return "$SHELL_TRUE"
}
