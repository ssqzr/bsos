#!/bin/bash

if [ -n "${SCRIPT_DIR_825f52f6}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_825f52f6="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/print.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_825f52f6}/array.sh"

__exit_code_ctrl_c=130

# A function that prompts the user for confirmation with a customizable prompt and default value.
#
# Parameters:
#   - $1: The prompt message to display to the user.
#   - $2: The default value for the confirmation. Defaults to "y" if not provided.
#
# Returns:
#   - If the user confirms, the function returns with the exit code "$SHELL_TRUE".
#   - If the user denies, the function returns with the exit code "$SHELL_FALSE".
#   - If the user does not provide a valid input, the function displays an error message and prompts again.
#   - If the user interrupts the input by pressing Ctrl+C, the function returns with the exit code 130.
function tui::builtin::confirm() {
    local prompt="$1"
    local default="$2"
    local result
    local default_prompt

    if [ -z "$default" ]; then
        default="y"
    fi

    if string::is_true "$default"; then
        default_prompt="[Y/n]"
    else
        default_prompt="[y/N]"
    fi

    while true; do
        printf_blue "${prompt} ${default_prompt} "
        # 超时的退出码是1，Ctrl+C的退出码是130
        read -t 5 -r -e -n 1 result
        if [ $? -eq 130 ]; then
            lerror "quite input, exit"
            return 130
        fi
        linfo "get input result=${result}"
        if [ -z "$result" ]; then
            result="$default"
            break
        fi
        if string::is_bool "$result"; then
            break
        fi
        println_error "input invalid, please input y or n."
    done
    if string::is_true "$result"; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
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
    return "${exit_code}"
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
        return "${exit_code}"
    done
    echo "$value"
}

function tui::search_select() {
    local -n options_14bd9c66="$1"
    # shellcheck disable=SC2034
    local -n res_14bd9c66="$2"
    local multi_14bd9c66="$3"
    local title_14bd9c66="$4"

    local temp_str_14bd9c66
    local exit_code_14bd9c66
    local fzf_options_14bd9c66=()
    if [ "${multi_14bd9c66}" = "multi" ]; then
        fzf_options_14bd9c66+=("--multi")
    elif string::is_num "${multi_14bd9c66}"; then
        fzf_options_14bd9c66+=("--multi=${multi_14bd9c66}")
    fi
    fzf_options_14bd9c66+=("--prompt='${title_14bd9c66}'")
    fzf_options_14bd9c66+=("--height 40%")
    fzf_options_14bd9c66+=("--cycle")
    fzf_options_14bd9c66+=('--pointer="->"')
    fzf_options_14bd9c66+=("--bind alt-i:up")
    fzf_options_14bd9c66+=("--bind alt-k:down")
    fzf_options_14bd9c66+=("--bind alt-j:backward-char")
    fzf_options_14bd9c66+=("--bind alt-l:forward-char")
    fzf_options_14bd9c66+=("--bind alt-h:beginning-of-line")
    fzf_options_14bd9c66+=("--bind alt-';':end-of-line")
    fzf_options_14bd9c66+=("--ansi")
    fzf_options_14bd9c66+=("--highlight-line")
    temp_str_14bd9c66=$(printf '%s\n' "${options_14bd9c66[@]}" | FZF_DEFAULT_OPTS="${fzf_options_14bd9c66[*]}" fzf)
    # fzf 程序 Ctrl+C 或者 ESC 退出码是 130
    exit_code_14bd9c66=$?
    if [ "$exit_code_14bd9c66" -ne "${SHELL_TRUE}" ]; then
        lerror "select exit, exit code: ${exit_code_14bd9c66}"
        return "${exit_code_14bd9c66}"
    fi
    array::readarray res_14bd9c66 < <(echo "${temp_str_14bd9c66}")
    return "$SHELL_TRUE"
}

function tui::search_select_one() {
    local -n options_ca9824e0="$1"
    local title_ca9824e0="$2"
    local res_ca9824e0=()
    tui::search_select "${!options_ca9824e0}" res_ca9824e0 "1" "$title_ca9824e0" || return "$SHELL_FALSE"
    echo "${res_ca9824e0[0]}"
    return "$SHELL_TRUE"
}
