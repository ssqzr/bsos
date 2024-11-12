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

# 全局变量
declare __button_count=6
declare __column_count=6
declare __row_count=1
# 按钮的半径
declare __button_cycle_radius
# 中心圆的半径
declare __cycle_radius_in_center
# 按钮半径缩放比例
declare __button_radius_scale=0.8
# 中心圆和按钮总共占屏幕宽度或者高度的百分比
declare __length_percent=85
# 记录所有按钮的圆心的坐标
declare __buttons_center_of_cycle_xy=()
# 记录所有按钮的 margin 的配置
declare __buttons_margin=()

# 当前聚焦显示器的视口的宽度和高度，需要考虑屏幕旋转
declare __focused_monitor_viewport_width=0
declare __focused_monitor_viewport_height=0

declare __button_color
declare __font_size

# 图片路径
declare __lock_image_filepath
declare __logout_image_filepath
declare __shutdown_image_filepath
declare __reboot_image_filepath
declare __suspend_image_filepath
declare __hibernate_image_filepath

function wlogout_wrap::log_dir() {
    local log_dir="$HOME/.cache/wlogout/log"
    echo "$log_dir"
}

function wlogout_wrap::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(wlogout_wrap::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    log::level::set "$LOG_LEVEL_INFO" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function wlogout_wrap::layout_filepath() {
    echo "${SCRIPT_DIR_37160405}/layout"
}

function wlogout_wrap::style_filepath() {
    echo "${SCRIPT_DIR_37160405}/style.css"
}

function wlogout_wrap::init_monitor_info() {
    local focused_monitor_width
    local focused_monitor_height
    # 屏幕缩放的比例
    local focused_monitor_scale
    local temp
    local focused_monitor

    focused_monitor=$(hyprland::hyprctl::monitors | cfg::array::filter_by_key_value --type="json" "focused" "true" | cfg::array::first) || return "$SHELL_FALSE"
    if string::is_empty "$focused_monitor"; then
        lerror "get focused monitor failed"
        return "$SHELL_FALSE"
    fi

    focused_monitor_width=$(cfg::map::get --type="json" "width" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_height=$(cfg::map::get --type="json" "height" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_transform=$(cfg::map::get --type="json" "transform" "$focused_monitor") || return "$SHELL_FALSE"
    focused_monitor_scale=$(cfg::map::get --type="json" "scale" "$focused_monitor") || return "$SHELL_FALSE"

    ldebug "focused_monitor_width=${focused_monitor_width}"
    ldebug "focused_monitor_height=${focused_monitor_height}"
    ldebug "focused_monitor_transform=${focused_monitor_transform}"
    ldebug "focused_monitor_scale=${focused_monitor_scale}"

    # https://wiki.hyprland.org/Configuring/Monitors/#rotating
    local transform_90deg=(1 3 5 7)
    if array::is_contain transform_90deg "$focused_monitor_transform"; then
        # 旋转90度，宽高互换
        # focused_monitor_scale 可能为小数
        __focused_monitor_viewport_height=$(math::div "$focused_monitor_width" "$focused_monitor_scale" 0)
        __focused_monitor_viewport_width=$(math::div "$focused_monitor_height" "$focused_monitor_scale" 0)
    else
        __focused_monitor_viewport_width=$(math::div "$focused_monitor_width" "$focused_monitor_scale" 0)
        __focused_monitor_viewport_height=$(math::div "$focused_monitor_height" "$focused_monitor_scale" 0)
    fi

    ldebug "__focused_monitor_viewport_width=${__focused_monitor_viewport_width}"
    ldebug "__focused_monitor_viewport_height=${__focused_monitor_viewport_height}"
}

function wlogout_wrap::font_size() {
    if [ "${__focused_monitor_viewport_width}" -ge "${__focused_monitor_viewport_height}" ]; then
        __font_size=$((__focused_monitor_viewport_height * 4 / 100))
    else
        __font_size=$((__focused_monitor_viewport_width * 4 / 100))
    fi

    ldebug "font_size=${__font_size}"

    return "$SHELL_TRUE"
}

function wlogout_wrap::button_color() {
    # 检测 GTK 颜色方案，设置按钮的颜色
    local gtk_color_scheme_mode
    gtk_color_scheme_mode=$(gsettings::color_scheme_mode)
    if [ "$gtk_color_scheme_mode" == "dark" ]; then
        __button_color="white"
    else
        __button_color="black"
    fi
    ldebug "button_color=${__button_color}"
}

function wlogout_wrap::button_image_filepath() {
    if $is_develop_mode; then
        __lock_image_filepath="${SCRIPT_DIR_37160405}/icons/lock_${__button_color}.png"
        __logout_image_filepath="${SCRIPT_DIR_37160405}/icons/logout_${__button_color}.png"
        __shutdown_image_filepath="${SCRIPT_DIR_37160405}/icons/shutdown_${__button_color}.png"
        __reboot_image_filepath="${SCRIPT_DIR_37160405}/icons/reboot_${__button_color}.png"
        __suspend_image_filepath="${SCRIPT_DIR_37160405}/icons/suspend_${__button_color}.png"
        __hibernate_image_filepath="${SCRIPT_DIR_37160405}/icons/hibernate_${__button_color}.png"
    else
        __lock_image_filepath="$HOME/.config/wlogout/icons/lock_${__button_color}.png"
        __logout_image_filepath="$HOME/.config/wlogout/icons/logout_${__button_color}.png"
        __shutdown_image_filepath="$HOME/.config/wlogout/icons/shutdown_${__button_color}.png"
        __reboot_image_filepath="$HOME/.config/wlogout/icons/reboot_${__button_color}.png"
        __suspend_image_filepath="$HOME/.config/wlogout/icons/suspend_${__button_color}.png"
        __hibernate_image_filepath="$HOME/.config/wlogout/icons/hibernate_${__button_color}.png"
    fi
    ldebug "lock_image_filepath=${__lock_image_filepath}"
    ldebug "logout_image_filepath=${__logout_image_filepath}"
    ldebug "shutdown_image_filepath=${__shutdown_image_filepath}"
    ldebug "reboot_image_filepath=${__reboot_image_filepath}"
    ldebug "suspend_image_filepath=${__suspend_image_filepath}"
    ldebug "hibernate_image_filepath=${__hibernate_image_filepath}"
}

# 计算中心圆和按钮的半径
# 按钮圆的半径最大是中心圆的一半，不然多个按钮会重叠
function wlogout_wrap::init_cycle_radius() {
    local max_length
    local max_radius

    max_length=$((__focused_monitor_viewport_width > __focused_monitor_viewport_height ? __focused_monitor_viewport_height : __focused_monitor_viewport_width))

    max_length=$((max_length * __length_percent / 100))

    # 中心圆的直径 + 按钮的直径 = max_length
    # 按钮圆的半径最大是中心圆的一半，不然多个按钮会重叠
    __cycle_radius_in_center=$((max_length / 3))
    # 聚焦按钮时半径会变大，所以按照最大情况进行计算
    max_radius=$((__cycle_radius_in_center / 2))
    # 默认的按钮的半径是聚焦时的 4/5
    __button_cycle_radius=$(math::mul "${max_radius}" "${__button_radius_scale}" 0)

    ldebug "center_cycle_radius=${__cycle_radius_in_center}"
    ldebug "button_cycle_radius=${__button_cycle_radius}"
}

# 计算所有按钮圆的圆心的坐标
# 6个按钮，所以每两个相邻的按钮圆心到中心圆的夹角是60度
# 原点是屏幕的左上角
function wlogout_wrap::init_button_cycle_origin_xy() {
    local center_cycle_x
    local center_cycle_y

    # 以中心圆为原点，计算按钮的圆心到x轴正向的夹角
    local current_degree
    local index
    local temp_degree
    local x_relative_to_center
    local y_relative_to_center
    local x
    local y

    local temp

    center_cycle_x=$((__focused_monitor_viewport_width / 2))
    center_cycle_y=$((__focused_monitor_viewport_height / 2))

    for ((index = 0; index < __button_count; index++)); do
        if [ -z "$current_degree" ]; then
            # 第一个夹角从0-60度随机生成
            current_degree=$(math::rand 0 60) || return "$SHELL_FALSE"
        else
            current_degree=$((current_degree + 60))
        fi
        # 计算按钮的圆心的坐标
        if [ "${current_degree}" -ge 0 ] && [ "${current_degree}" -lt 90 ]; then
            x_relative_to_center=$(math::cos_by_degree "${current_degree}") || return "$SHELL_FALSE"
            x_relative_to_center=$(math::mul "${x_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"
            y_relative_to_center=$(math::sin_by_degree "${current_degree}") || return "$SHELL_FALSE"
            y_relative_to_center=$(math::mul "${y_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"

            x=$(math::add "$center_cycle_x" "$x_relative_to_center" 0) || return "$SHELL_FALSE"
            y=$(math::sub "$center_cycle_y" "${y_relative_to_center}" 0) || return "$SHELL_FALSE"
            array::rpush __buttons_center_of_cycle_xy "${x},${y}"
        elif [ "${current_degree}" -ge 90 ] && [ "${current_degree}" -lt 180 ]; then
            x_relative_to_center=$(math::cos_by_degree $((180 - current_degree))) || return "$SHELL_FALSE"
            x_relative_to_center=$(math::mul "${x_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"
            y_relative_to_center=$(math::sin_by_degree $((180 - current_degree))) || return "$SHELL_FALSE"
            y_relative_to_center=$(math::mul "${y_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"

            x=$(math::sub "$center_cycle_x" "$x_relative_to_center" 0)
            y=$(math::sub "$center_cycle_y" "$y_relative_to_center" 0)
            array::rpush __buttons_center_of_cycle_xy "${x},${y}"
        elif [ "${current_degree}" -ge 180 ] && [ "${current_degree}" -lt 270 ]; then
            x_relative_to_center=$(math::cos_by_degree $((current_degree - 180))) || return "$SHELL_FALSE"
            x_relative_to_center=$(math::mul "${x_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"
            y_relative_to_center=$(math::sin_by_degree $((current_degree - 180))) || return "$SHELL_FALSE"
            y_relative_to_center=$(math::mul "${y_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"

            x=$(math::sub "$center_cycle_x" "$x_relative_to_center" 0)
            y=$(math::add "$center_cycle_y" "$y_relative_to_center" 0)
            array::rpush __buttons_center_of_cycle_xy "${x},${y}"
        else
            x_relative_to_center=$(math::cos_by_degree $((360 - current_degree))) || return "$SHELL_FALSE"
            x_relative_to_center=$(math::mul "${x_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"
            y_relative_to_center=$(math::sin_by_degree $((360 - current_degree))) || return "$SHELL_FALSE"
            y_relative_to_center=$(math::mul "${y_relative_to_center}" "${__cycle_radius_in_center}") || return "$SHELL_FALSE"

            x=$(math::add "$center_cycle_x" "$x_relative_to_center" 0)
            y=$(math::add "$center_cycle_y" "$y_relative_to_center" 0)
            array::rpush __buttons_center_of_cycle_xy "${x},${y}"
        fi
    done

    ldebug "buttons_center_of_cycle_xy=${__buttons_center_of_cycle_xy[*]}"

    # 逆序，让其方向是顺时针顺序而不是逆时针顺序
    # array::reverse __buttons_center_of_cycle_xy || return "$SHELL_FALSE"
    # 打乱，打乱就不需要逆序处理了
    temp=()
    while (($(array::length __buttons_center_of_cycle_xy) > 0)); do
        index=$(math::rand 0 $(($(array::length __buttons_center_of_cycle_xy) - 1))) || return "$SHELL_FALSE"
        temp+=("${__buttons_center_of_cycle_xy[$index]}")
        array::remove_at __buttons_center_of_cycle_xy "$index"
    done
    __buttons_center_of_cycle_xy=("${temp[@]}")

    return "$SHELL_TRUE"
}

function wlogout_wrap::init_button_cycle_margin_string() {
    local index
    local x
    local y
    local temp
    local button_area_width

    local margin_top
    local margin_right
    local margin_bottom
    local margin_left

    local active_margin_top
    local active_margin_right
    local active_margin_bottom
    local active_margin_left

    button_area_width=$((__focused_monitor_viewport_width / __column_count))

    for ((index = 0; index < __button_count; index++)); do
        temp="${__buttons_center_of_cycle_xy[$index]}"
        x="${temp%%,*}"
        y="${temp##*,}"
        ldebug "button cycle center point: x=${x}, y=${y}"
        # x 此时可能是负数
        x=$(math::sub "$x" $((button_area_width * index)) 0)

        margin_left=$((x - __button_cycle_radius))
        margin_right=$((0 - (x - button_area_width + __button_cycle_radius)))
        margin_top=$((y - __button_cycle_radius))
        margin_bottom=$((__focused_monitor_viewport_height - y - __button_cycle_radius))

        array::rpush __buttons_margin "${margin_top}px ${margin_right}px ${margin_bottom}px ${margin_left}px"
    done
}

function wlogout_wrap::export() {
    local temp

    export FONT_SIZE="${__font_size}"
    export BUTTON_COLOR="$__button_color"

    export BUTTON_RADIUS="${__button_cycle_radius}"

    temp="${__buttons_margin[0]}"
    export MARGIN_0="${temp}"
    temp="${__buttons_margin[1]}"
    export MARGIN_1="${temp}"
    temp="${__buttons_margin[2]}"
    export MARGIN_2="${temp}"
    temp="${__buttons_margin[3]}"
    export MARGIN_3="${temp}"
    temp="${__buttons_margin[4]}"
    export MARGIN_4="${temp}"
    temp="${__buttons_margin[5]}"
    export MARGIN_5="${temp}"

    export LOCK_IMAGE_FILEPATH="${__lock_image_filepath}"
    export LOGOUT_IMAGE_FILEPATH="${__logout_image_filepath}"
    export SHUTDOWN_IMAGE_FILEPATH="${__shutdown_image_filepath}"
    export REBOOT_IMAGE_FILEPATH="${__reboot_image_filepath}"
    export SUSPEND_IMAGE_FILEPATH="${__suspend_image_filepath}"
    export HIBERNATE_IMAGE_FILEPATH="${__hibernate_image_filepath}"
}

function wlogout_wrap::main() {
    local layout_filepath
    local style_filepath
    local style

    wlogout_wrap::set_log || return "$SHELL_FALSE"

    layout_filepath="$(wlogout_wrap::layout_filepath)"
    style_filepath="$(wlogout_wrap::style_filepath)"

    ldebug "layout_filepath=$layout_filepath"
    ldebug "style_filepath=$style_filepath"

    if [ ! -f "$layout_filepath" ]; then
        lerror "layout file($layout_filepath) not exists."
        return "$SHELL_FALSE"
    fi

    if [ ! -f "$style_filepath" ]; then
        lerror "style file($style_filepath) not exists."
        return "$SHELL_FALSE"
    fi

    wlogout_wrap::init_monitor_info || return "$SHELL_FALSE"

    wlogout_wrap::font_size || return "$SHELL_FALSE"

    wlogout_wrap::button_color || return "$SHELL_FALSE"

    wlogout_wrap::button_image_filepath || return "$SHELL_FALSE"

    wlogout_wrap::init_cycle_radius || return "$SHELL_FALSE"

    wlogout_wrap::init_button_cycle_origin_xy || return "$SHELL_FALSE"

    wlogout_wrap::init_button_cycle_margin_string || return "$SHELL_FALSE"

    wlogout_wrap::export || return "$SHELL_FALSE"

    style=$(envsubst <"$style_filepath") || return "$SHELL_FALSE"

    wlogout -b "${__column_count}" -c 0 -r 0 -m 0 --layout "$layout_filepath" --css <(echo "$style") --protocol layer-shell
    return "$SHELL_TRUE"
}

wlogout_wrap::main "$@"
