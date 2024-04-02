#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_825f52f6="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/print.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/log.sh"

__exit_code_ctrl_c=130

function tui::input_optional() {
    local placeholder="$1"
    local prompt="$2"
    local default="$3"
    local value
    value=$(gum input --placeholder "$placeholder" --prompt "${prompt}[Optional]" --value="${default}")
    local exit_code=$?
    if [ $exit_code -eq "$SHELL_TRUE" ]; then
        echo "$value"
        return "$SHELL_TRUE"
    fi
    lerror "input exit, exit code: ${exit_code}"
    if [ $exit_code -eq ${__exit_code_ctrl_c} ]; then
        exit $exit_code
    fi
    return "$SHELL_FALSE"
}

# 必填项
function tui::input_required() {
    local placeholder="$1"
    local prompt="$2"
    local default="$3"
    local value
    while true; do
        value=$(gum input --placeholder "$placeholder" --prompt "${prompt}[Required]" --value="${default}")
        local exit_code=$?
        if [ $exit_code -eq "$SHELL_TRUE" ]; then
            if [ -z "${value}" ]; then
                println_info "input is required, please input again"
                continue
            else
                break
            fi
        fi
        lerror "input exit, exit code: ${exit_code}"
        if [ $exit_code -eq ${__exit_code_ctrl_c} ]; then
            exit $exit_code
        fi
    done
    echo "$value"
}

function tui::confirm() {
    local title="$1"
    gum confirm "$title"
    local exit_code=$?
    if [ $exit_code -eq "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    fi
    if [ $exit_code -eq "$SHELL_FALSE" ]; then
        return "$SHELL_FALSE"
    fi
    lerror "confirm exit, exit code: ${exit_code}"
    exit $exit_code
}
