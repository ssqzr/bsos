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

function printf_style() {
    local display_mode="$1"
    local foreground="$2"
    local background="$3"
    local format="$4"
    local params=("${@:5}")

    # if [ -z "$display_mode" ]; then
    #     display_mode="${P_DISPLAY_MODE_DEFAULT}"
    # fi

    if [ -n "$foreground" ]; then
        foreground=";${foreground}"
    fi

    if [ -n "$background" ]; then
        background=";${background}"
    fi

    # https://linuxize.com/post/bash-printf-command/
    # shellcheck disable=SC2059
    # 一些函数返回字符串时一般是输出到标准输出，所以这里不能打印到标准输出，只能打印到标准错误输出
    printf "\e[${display_mode}${foreground}${background}m$format\e[0m" "${params[@]}" >&2
}

# 前景色是黑色
function printf_black() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_BLACK}" "" "$@"
}

function println_black() {
    printf_black "$1\n" "${@:2}"
}

# 前景色是红色
function printf_red() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_RED}" "" "$@"
}

function println_red() {
    printf_red "$1\n" "${@:2}"
}

# 前景色是绿色
function printf_green() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_GREEN}" "" "$@"
}

function println_green() {
    printf_green "$1\n" "${@:2}"
}

# 前景色是黄色
function printf_yellow() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_YELLOW}" "" "$@"
}

function println_yellow() {
    printf_yellow "$1\n" "${@:2}"
}

# 前景色是蓝色
function printf_blue() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_BLUE}" "" "$@"
}

function println_blue() {
    printf_blue "$1\n" "${@:2}"
}

# 前景色是紫色
function printf_purple() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_PURPLE}" "" "$@"
}
function println_purple() {
    printf_purple "$1\n" "${@:2}"
}

# 前景色是深绿
function printf_dark_green() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_DARK_GREEN}" "" "$@"
}

function println_dark_green() {
    printf_dark_green "$1\n" "${@:2}"
}

# 前景色是白色
function printf_white() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_WHITE}" "" "$@"
}

function println_white() {
    printf_white "$1\n" "${@:2}"
}

################################################## 下面是和日志功能相关的函数 ##############################################
function printf_debug() {
    printf_style "" "${P_FOREGROUND_WHITE}" "" "$@"
}

function println_debug() {
    printf_debug "$1\n" "${@:2}"
}

function printf_info() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_WHITE}" "" "$@"
}

function println_info() {
    printf_info "$1\n" "${@:2}"
}

function printf_warn() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT};${P_DISPLAY_MODE_BLINK}" "${P_FOREGROUND_YELLOW}" "" "$@"
}

function println_warn() {
    printf_warn "$1\n" "${@:2}"
}

function printf_success() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_GREEN}" "" "$@"
}

function println_success() {
    printf_success "$1\n" "${@:2}"
}

function print_error() {
    printf_style "${P_DISPLAY_MODE_HIGHLIGHT}" "${P_FOREGROUND_RED}" "" "$@"
}

function println_error() {
    print_error "$1\n" "${@:2}"
}
