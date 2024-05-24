#!/bin/bash

# shellcheck disable=SC2034

# 用于交互输出时可以输出好看的文字

if [ -n "${SCRIPT_DIR_3cad49c8}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_3cad49c8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_3cad49c8}/constant.sh"

# https://en.wikipedia.org/wiki/ANSI_escape_code
# https://docs.rockylinux.org/gemstones/string_color/
# https://chrisyeh96.github.io/2020/03/28/terminal-colors.html

# 前景色：黑色
P_FOREGROUND_BLACK=30
# 前景色：红色
P_FOREGROUND_RED=31
# 前景色：绿色
P_FOREGROUND_GREEN=32
# 前景色：黄色
P_FOREGROUND_YELLOW=33
# 前景色：蓝色
P_FOREGROUND_BLUE=34
# 前景色：紫色
P_FOREGROUND_PURPLE=35
# 前景色：深绿
P_FOREGROUND_DARK_GREEN=36
# 前景色：白色
P_FOREGROUND_WHITE=37

# 背景色：黑色
P_BACKGROUND_BLACK=40
# 背景色：红色
P_BACKGROUND_RED=41
# 背景色：绿色
P_BACKGROUND_GREEN=42
# 背景色：黄色
P_BACKGROUND_YELLOW=43
# 背景色：蓝色
P_BACKGROUND_BLUE=44
# 背景色：紫色
P_BACKGROUND_PURPLE=45
# 背景色：深绿
P_BACKGROUND_DARK_GREEN=46
# 背景色：白色
P_BACKGROUND_WHITE=47

# 终端默认模式，相当于重置
P_DISPLAY_MODE_DEFAULT=0
# 高亮
P_DISPLAY_MODE_HIGHLIGHT=1
# 强调
P_DISPLAY_MODE_UNDERLINE=4
# 闪烁
P_DISPLAY_MODE_BLINK=5
# 反转
P_DISPLAY_MODE_REVERSE=7
# 隐藏
P_DISPLAY_MODE_HIDE=8

function get_tty() {
    # 当前进程的标准输入是命名管道时，$(tty) 获取不到 tty 。返回 "not a tty"
    # 因为 tty 命令获取的是标准输入关联的终端

    local tty_filepath

    if tty -s; then
        tty_filepath="$(tty)"
    elif [ -n "$BASHPID" ]; then
        tty_filepath="$(ps hotty "$BASHPID")"
        if [ -z "$tty_filepath" ] || [ "$tty_filepath" == "?" ]; then
            tty_filepath=""
        else
            tty_filepath="/dev/${tty_filepath}"
        fi
    fi

    # 尝试获取父脚本进程的 tty
    if [ -z "$tty_filepath" ]; then
        tty_filepath="$(ps hotty "$$")"
        if [ -z "$tty_filepath" ] || [ "$tty_filepath" == "?" ]; then
            tty_filepath=""
        else
            tty_filepath="/dev/${tty_filepath}"
        fi
    fi

    echo "$tty_filepath"
    return "$SHELL_TRUE"
}

# 参数说明
# 必选参数
# 可选参数
#   --stream=STREAM             输出流，默认是 stdout
#   --display-mode=MODE         显示模式，默认是 ${P_DISPLAY_MODE_DEFAULT} ，即默认模式
#   --foreground=FOREGROUND     前景色，默认不会设置。
#   --background=BACKGROUND     背景色，默认不会设置。
#   --format=FORMAT             输出格式，例如： %s。具体参考： man printf
# 位置参数
#   message-params              消息参数
function printf_style() {
    local display_mode
    local foreground
    local background
    local format

    local other_params=()
    local stream
    local printf_format
    local tty_filepath

    local param
    for param in "$@"; do
        case "$param" in
        --stream=*)
            stream="${param#*=}"
            ;;
        --display-mode=*)
            display_mode="${param#*=}"
            ;;
        --foreground=*)
            foreground="${param#*=}"
            ;;
        --background=*)
            background="${param#*=}"
            ;;
        --format=*)
            format="${param#*=}"
            ;;
        -*)
            printf "unknown option %s" "$param" >&2
            return "$SHELL_FALSE"
            ;;
        *)
            other_params+=("$param")
            ;;
        esac
    done

    stream="${stream:-stdout}"
    display_mode="${display_mode:-${P_DISPLAY_MODE_DEFAULT}}"
    format="${format:-%s}"

    if [ -n "$foreground" ]; then
        foreground=";${foreground}"
    fi

    if [ -n "$background" ]; then
        background=";${background}"
    fi

    printf_format="\e[${display_mode}${foreground}${background}m$format\e[${P_DISPLAY_MODE_DEFAULT}m"

    case "$stream" in
    stdout)
        # https://linuxize.com/post/bash-printf-command/
        # shellcheck disable=SC2059
        # 一些函数返回字符串时一般是输出到标准输出，所以这里不能打印到标准输出和标准错误，输出到当前的 tty
        printf "${printf_format}" "${other_params[@]}" >&1
        ;;
    stderr)
        # shellcheck disable=SC2059
        printf "${printf_format}" "${other_params[@]}" >&2
        ;;
    tty)
        tty_filepath="$(get_tty)"
        if [ -z "$tty_filepath" ]; then
            # shellcheck disable=SC2059
            printf "${printf_format}" "${other_params[@]}" >&2
        else
            # shellcheck disable=SC2059
            printf "${printf_format}" "${other_params[@]}" >"$tty_filepath"
        fi
        ;;
    *)
        # 文件路径
        # shellcheck disable=SC2059
        printf "${printf_format}" "${other_params[@]}" >>"$stream"
        ;;
    esac

    return "$SHELL_TRUE"
}

function _println_wrap() {
    local name
    local options=()
    local other_params=()
    local message_format="%s"

    local param
    for param in "$@"; do
        case "$param" in
        --name=*)
            name="${param#*=}"
            ;;
        -*)
            options+=("$param")
            ;;
        *)
            other_params+=("$param")
            ;;
        esac
    done

    if [ "${#other_params[@]}" -gt 1 ]; then
        message_format="${other_params[0]}"
        other_params=("${other_params[@]:1}")
    fi

    "printf_${name}" "${options[@]}" --format="${message_format}\n" "${other_params[@]}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 前景色是黑色
function printf_black() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_BLACK}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_black() {
    _println_wrap --name="black" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是红色
function printf_red() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_RED}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_red() {
    _println_wrap --name="red" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是绿色
function printf_green() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_GREEN}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_green() {
    _println_wrap --name="green" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是黄色
function printf_yellow() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_YELLOW}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_yellow() {
    _println_wrap --name="yellow" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是蓝色
function printf_blue() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_BLUE}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_blue() {
    _println_wrap --name="blue" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是紫色
function printf_purple() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_PURPLE}" --background="$P_BACKGROUND_BLACK" "$@"
}
function println_purple() {
    _println_wrap --name="purple" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是深绿
function printf_dark_green() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_DARK_GREEN}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_dark_green() {
    _println_wrap --name="dark_green" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 前景色是白色
function printf_white() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_WHITE}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_white() {
    _println_wrap --name="white" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

################################################## 下面是和日志功能相关的函数 ##############################################
function printf_debug() {
    printf_style --foreground="${P_FOREGROUND_WHITE}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_debug() {
    _println_wrap --name="debug" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function printf_info() {
    printf_style --display-mode="${P_DISPLAY_MODE_DEFAULT}" "$@"
}

function println_info() {
    _println_wrap --name="info" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function printf_warn() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT};${P_DISPLAY_MODE_BLINK}" --foreground="${P_FOREGROUND_YELLOW}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_warn() {
    _println_wrap --name="warn" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function printf_success() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_GREEN}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_success() {
    _println_wrap --name="success" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function printf_error() {
    printf_style --display-mode="${P_DISPLAY_MODE_HIGHLIGHT}" --foreground="${P_FOREGROUND_RED}" --background="$P_BACKGROUND_BLACK" "$@"
}

function println_error() {
    _println_wrap --name="error" "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}
