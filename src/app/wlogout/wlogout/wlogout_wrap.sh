#!/bin/bash

# 整体的布局是：
# 1. 两行两列
# 2. 垂直方向居中
# 3. 水平方向居中
# 4. 整体显示是正方形
# 5. 整体的宽度和高度是显示的宽度和高度较小者的一半，注意并不是屏幕的宽度和高度的较小者，因为屏幕可能旋转90度
#     如果显示的宽度大于高度，那么就是高度的一半
#     如果显示而高度大于宽度，那么就是宽度的一半

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_37160405="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
is_develop_mode=false
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_37160405%%\/app\/wlogout*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_37160405}" ]; then
    # 方便开发
    is_develop_mode=true
fi
if $is_develop_mode; then
    # 方便开发
    source_filepath="$src_dir/lib/utils/all.sh"
else
    source_filepath="$HOME/.bash_lib/utils/all.sh"
    if [ ! -e "$source_filepath" ]; then
        echo "path $source_filepath not exist"
        exit 1
    fi
fi
# shellcheck disable=SC1090
source "$source_filepath" || exit 1

# Check if wlogout is already running
if pgrep -x "wlogout" >/dev/null; then
    pkill -x "wlogout"
    exit 0
fi

function wlogout_wrap::layout_filepath() {
    echo "${SCRIPT_DIR_37160405}/layout"
}

function wlogout_wrap::style_filepath() {
    echo "${SCRIPT_DIR_37160405}/style.css"
}

# function wlogout_wrap::env() {

# }

function wlogout_wrap::font_size() {
    local focused_monitor_width
    local focused_monitor_height
    focused_monitor_width=$(hyprland::hyprctl::monitors::focused::option "width")
    focused_monitor_height=$(hyprland::hyprctl::monitors::focused::option "height")
    if [ "$focused_monitor_width" -ge "$focused_monitor_height" ]; then
        export font_size=$((focused_monitor_height * 4 / 100))
    else
        export font_size=$((focused_monitor_width * 4 / 100))
    fi
}

function wlogout_wrap::button_color() {
    # 检测 GTK 颜色方案，设置按钮的颜色
    local gtk_color_scheme_mode
    gtk_color_scheme_mode=$(gsettings::color_scheme_mode)
    if [ "$gtk_color_scheme_mode" == "dark" ]; then
        export button_color="white"
    else
        export button_color="black"
    fi
}

function wlogout_wrap::button_lock_image_filepath() {
    local color
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        export lock_image_filepath="${SCRIPT_DIR_37160405}/icons/lock_${color}.png"
    else
        export lock_image_filepath="$HOME/.config/wlogout/icons/lock_${color}.png"
    fi
}

function wlogout_wrap::button_logout_image_filepath() {
    local color
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        export logout_image_filepath="${SCRIPT_DIR_37160405}/icons/logout_${color}.png"
    else
        export logout_image_filepath="$HOME/.config/wlogout/icons/logout_${color}.png"
    fi
}

function wlogout_wrap::button_shutdown_image_filepath() {
    local color
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        export shutdown_image_filepath="${SCRIPT_DIR_37160405}/icons/shutdown_${color}.png"
    else
        export shutdown_image_filepath="$HOME/.config/wlogout/icons/shutdown_${color}.png"
    fi
}

function wlogout_wrap::button_reboot_image_filepath() {
    local color
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        export reboot_image_filepath="${SCRIPT_DIR_37160405}/icons/reboot_${color}.png"
    else
        export reboot_image_filepath="$HOME/.config/wlogout/icons/reboot_${color}.png"
    fi
}

function wlogout_wrap::button_radius() {
    local hyprland_rounding
    hyprland_rounding=$(hyprland::hyprctl::getoption::decoration::rounding)

    # eval hypr border radius
    export active_radius=$((hyprland_rounding * 5))
    export button_radius=$((hyprland_rounding * 8))
}

function wlogout_wrap::margin() {
    local focused_monitor_width
    local focused_monitor_height
    local focused_monitor_scale_persent
    local temp
    focused_monitor_width=$(hyprland::hyprctl::monitors::focused::option "width")
    focused_monitor_height=$(hyprland::hyprctl::monitors::focused::option "height")
    focused_monitor_transform=$(hyprland::hyprctl::monitors::focused::option "transform")
    focused_monitor_scale_persent=$(hyprland::hyprctl::monitors::focused::option "scale" | sed 's/\.//')

    # https://wiki.hyprland.org/Configuring/Monitors/#rotating
    local transform_90deg=(1 3 5 7)
    if array::is_contain transform_90deg "$focused_monitor_transform"; then
        temp=$focused_monitor_width
        focused_monitor_width=$focused_monitor_height
        focused_monitor_height=$temp
    fi

    if [ "$focused_monitor_width" -ge "$focused_monitor_height" ]; then
        # 垂直方向的margin
        export y_margin=$((focused_monitor_height * 100 / focused_monitor_scale_persent / 4))
        # 水平方向的margin
        export x_margin=$((focused_monitor_width * 100 / focused_monitor_scale_persent / 2 - y_margin))
        # 缩放后的垂直方向的margin，放大后margin缩小20%，也就是以前的 80%
        export y_scale_margin=$((y_margin * 8 / 10))
        # 缩放后的水平方向的margin，放大后缩小的margin是垂直方向缩小的margin一样
        export x_scale_margin=$((x_margin - y_margin * 2 / 10))
    else
        export x_margin=$((focused_monitor_width * 100 / focused_monitor_scale_persent / 4))
        export y_margin=$((focused_monitor_height * 100 / focused_monitor_scale_persent / 2 - x_margin))
        export x_scale_margin=$((x_margin * 8 / 10))
        export y_scale_margin=$((y_margin - x_margin * 2 / 10))
    fi
}

function wlogout_wrap::main() {
    local layout_filepath
    local style_filepath
    layout_filepath="$(wlogout_wrap::layout_filepath)"
    style_filepath="$(wlogout_wrap::style_filepath)"

    if [ ! -f "$layout_filepath" ]; then
        lerror "layout file($layout_filepath) not exists."
        return "$SHELL_FALSE"
    fi

    if [ ! -f "$style_filepath" ]; then
        lerror "style file($style_filepath) not exists."
        return "$SHELL_FALSE"
    fi

    wlogout_wrap::font_size
    wlogout_wrap::button_color
    wlogout_wrap::button_radius
    wlogout_wrap::margin

    local style
    style=$(envsubst <"$style_filepath")

    wlogout -b 2 -c 0 -r 0 -m 0 --layout "$layout_filepath" --css <(echo "$style") --protocol layer-shell
    return "$SHELL_TRUE"
}

wlogout_wrap::main "$@"
