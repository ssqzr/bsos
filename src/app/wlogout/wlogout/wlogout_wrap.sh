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

function wlogout_wrap::log_dir() {
    local log_dir="$HOME/.cache/wlogout/log"
    echo "$log_dir"
}

function wlogout_wrap::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(wlogout_wrap::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_DEBUG" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function wlogout_wrap::layout_filepath() {
    echo "${SCRIPT_DIR_37160405}/layout"
}

function wlogout_wrap::style_filepath() {
    echo "${SCRIPT_DIR_37160405}/style.css"
}

function wlogout_wrap::font_size() {
    local focused_monitor_width
    local focused_monitor_height
    local focused_monitor
    local font_size

    focused_monitor=$(hyprland::hyprctl::monitors | cfg::array::filter_by_key_value --type="json" "focused" "true" | cfg::array::first) || return "$SHELL_FALSE"
    if string::is_empty "$focused_monitor"; then
        lerror "get focused monitor failed"
        return "$SHELL_FALSE"
    fi
    focused_monitor_width=$(cfg::map::get --type="json" "width" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_height=$(cfg::map::get --type="json" "height" "$focused_monitor") || return "$SHELL_FALSE"
    if [ "$focused_monitor_width" -ge "$focused_monitor_height" ]; then
        font_size=$((focused_monitor_height * 4 / 100))
    else
        font_size=$((focused_monitor_width * 4 / 100))
    fi

    linfo "font_size=${font_size}"

    export FONT_SIZE="${font_size}"
    return "$SHELL_TRUE"
}

function wlogout_wrap::button_color() {
    # 检测 GTK 颜色方案，设置按钮的颜色
    local gtk_color_scheme_mode
    local button_color
    gtk_color_scheme_mode=$(gsettings::color_scheme_mode)
    if [ "$gtk_color_scheme_mode" == "dark" ]; then
        button_color="white"
    else
        button_color="black"
    fi
    linfo "button_color=${button_color}"
    export BUTTON_COLOR="$button_color"
}

function wlogout_wrap::button_lock_image_filepath() {
    local color
    local lock_image_filepath
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        lock_image_filepath="${SCRIPT_DIR_37160405}/icons/lock_${color}.png"
    else
        lock_image_filepath="$HOME/.config/wlogout/icons/lock_${color}.png"
    fi
    linfo "lock_image_filepath=${lock_image_filepath}"
    export LOCK_IMAGE_FILEPATH="$lock_image_filepath"
}

function wlogout_wrap::button_logout_image_filepath() {
    local color
    local logout_image_filepath
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        logout_image_filepath="${SCRIPT_DIR_37160405}/icons/logout_${color}.png"
    else
        logout_image_filepath="$HOME/.config/wlogout/icons/logout_${color}.png"
    fi
    linfo "logout_image_filepath=${logout_image_filepath}"
    export LOGOUT_IMAGE_FILEPATH="$logout_image_filepath"
}

function wlogout_wrap::button_shutdown_image_filepath() {
    local color
    local shutdown_image_filepath
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        shutdown_image_filepath="${SCRIPT_DIR_37160405}/icons/shutdown_${color}.png"
    else
        shutdown_image_filepath="$HOME/.config/wlogout/icons/shutdown_${color}.png"
    fi
    linfo "shutdown_image_filepath=${shutdown_image_filepath}"
    export SHUTDOWN_IMAGE_FILEPATH="$shutdown_image_filepath"
}

function wlogout_wrap::button_reboot_image_filepath() {
    local color
    local reboot_image_filepath
    color=$(wlogout_wrap::button_color)
    if $is_develop_mode; then
        reboot_image_filepath="${SCRIPT_DIR_37160405}/icons/reboot_${color}.png"
    else
        reboot_image_filepath="$HOME/.config/wlogout/icons/reboot_${color}.png"
    fi
    linfo "reboot_image_filepath=${reboot_image_filepath}"
    export REBOOT_IMAGE_FILEPATH="$reboot_image_filepath"
}

function wlogout_wrap::button_radius() {
    local hyprland_rounding
    local active_radius
    local button_radius

    hyprland_rounding=$(hyprland::hyprctl::getoption::decoration::rounding)

    # eval hypr border radius
    active_radius=$((hyprland_rounding * 5))
    button_radius=$((hyprland_rounding * 8))

    linfo "active_radius=${active_radius}"
    linfo "button_radius=${button_radius}"

    export ACTIVE_RADIUS="$active_radius"
    export BUTTON_RADIUS="$button_radius"
}

function wlogout_wrap::margin() {
    local focused_monitor_width
    local focused_monitor_height
    local focused_monitor_scale_persent
    local temp
    local focused_monitor
    local x_margin
    local y_margin
    local x_scale_margin
    local y_scale_margin

    focused_monitor=$(hyprland::hyprctl::monitors | cfg::array::filter_by_key_value --type="json" "focused" "true" | cfg::array::first) || return "$SHELL_FALSE"
    if string::is_empty "$focused_monitor"; then
        lerror "get focused monitor failed"
        return "$SHELL_FALSE"
    fi

    focused_monitor_width=$(cfg::map::get --type="json" "width" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_height=$(cfg::map::get --type="json" "height" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_transform=$(cfg::map::get --type="json" "transform" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_scale_persent=$(cfg::map::get --type="json" "scale" "$focused_monitor") || return "$SHELL_FALSE"

    linfo "focused_monitor_width=${focused_monitor_width}"
    linfo "focused_monitor_height=${focused_monitor_height}"
    linfo "focused_monitor_transform=${focused_monitor_transform}"
    linfo "focused_monitor_scale_persent=${focused_monitor_scale_persent}"

    focused_monitor_scale_persent=$(awk "BEGIN{printf \"%u\n\",(${focused_monitor_scale_persent}*100)}")
    linfo "focused_monitor_scale_persent=${focused_monitor_scale_persent}"

    # https://wiki.hyprland.org/Configuring/Monitors/#rotating
    local transform_90deg=(1 3 5 7)
    if array::is_contain transform_90deg "$focused_monitor_transform"; then
        temp=$focused_monitor_width
        focused_monitor_width=$focused_monitor_height
        focused_monitor_height=$temp
    fi

    if [ "$focused_monitor_width" -ge "$focused_monitor_height" ]; then
        # 垂直方向的margin
        y_margin=$((focused_monitor_height * 100 / focused_monitor_scale_persent / 4))
        # 水平方向的margin
        x_margin=$((focused_monitor_width * 100 / focused_monitor_scale_persent / 2 - y_margin))
        # 缩放后的垂直方向的margin，放大后margin缩小20%，也就是以前的 80%
        y_scale_margin=$((y_margin * 8 / 10))
        # 缩放后的水平方向的margin，放大后缩小的margin是垂直方向缩小的margin一样
        x_scale_margin=$((x_margin - y_margin * 2 / 10))
    else
        x_margin=$((focused_monitor_width * 100 / focused_monitor_scale_persent / 4))
        y_margin=$((focused_monitor_height * 100 / focused_monitor_scale_persent / 2 - x_margin))
        x_scale_margin=$((x_margin * 8 / 10))
        y_scale_margin=$((y_margin - x_margin * 2 / 10))
    fi

    linfo "x_margin=${x_margin}"
    linfo "y_margin=${y_margin}"
    linfo "x_scale_margin=${x_scale_margin}"
    linfo "y_scale_margin=${y_scale_margin}"

    export X_MARGIN="$x_margin"
    export Y_MARGIN="$y_margin"
    export X_SCALE_MARGIN="$x_scale_margin"
    export Y_SCALE_MARGIN="$y_scale_margin"
}

function wlogout_wrap::main() {
    local layout_filepath
    local style_filepath
    local style

    wlogout_wrap::set_log || return "$SHELL_FALSE"

    layout_filepath="$(wlogout_wrap::layout_filepath)"
    style_filepath="$(wlogout_wrap::style_filepath)"

    linfo "layout_filepath=$layout_filepath"
    linfo "style_filepath=$style_filepath"

    if [ ! -f "$layout_filepath" ]; then
        lerror "layout file($layout_filepath) not exists."
        return "$SHELL_FALSE"
    fi

    if [ ! -f "$style_filepath" ]; then
        lerror "style file($style_filepath) not exists."
        return "$SHELL_FALSE"
    fi

    wlogout_wrap::font_size || return "$SHELL_FALSE"
    wlogout_wrap::button_color || return "$SHELL_FALSE"
    wlogout_wrap::button_radius || return "$SHELL_FALSE"
    wlogout_wrap::margin || return "$SHELL_FALSE"

    style=$(envsubst <"$style_filepath") || return "$SHELL_FALSE"

    wlogout -b 2 -c 0 -r 0 -m 0 --layout "$layout_filepath" --css <(echo "$style") --protocol layer-shell
    return "$SHELL_TRUE"
}

wlogout_wrap::main "$@"
