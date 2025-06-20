#!/bin/bash

# 随机设置鼠标主题的脚本

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_30346050="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_30346050%%\/app\/hyprcursor*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_30346050}" ]; then
    # 方便开发
    source_filepath="$src_dir/lib/utils/all.sh"
else
    source_filepath="/usr/share/bsos/bash/utils/all.sh"
    if [ ! -e "$source_filepath" ]; then
        echo "path $source_filepath not exist"
        exit 1
    fi
fi
# shellcheck disable=SC1090
source "$source_filepath" || exit 1

function hyprcursor::cursor::log_dir() {
    local log_dir="$HOME/.cache/hyprcursor/log"
    echo "$log_dir"
}

function hyprcursor::cursor::get_current_theme_name() {
    local current_cursor_name=""

    current_cursor_name=$(gsettings get org.gnome.desktop.interface cursor-theme) || return "$SHELL_FALSE"

    # 返回的字符串包含单引号，需要去掉
    current_cursor_name="${current_cursor_name//\'/}"

    echo "$current_cursor_name"
}

function hyprcursor::cursor::blacklist::dir() {
    local dir="$HOME/.cache/hyprcursor"
    echo "$dir"
}

function hyprcursor::cursor::blacklist::filepath() {
    local blacklist=""
    blacklist="$(hyprcursor::cursor::blacklist::dir)/blacklist.txt"
    echo "$blacklist"
}

function hyprcursor::cursor::blacklist::list() {
    local -n blacklist_dd5afa6e="$1"
    shift

    local filepath_dd5afa6e=""
    local temp_str_dd5afa6e=""
    filepath_dd5afa6e="$(hyprcursor::cursor::blacklist::filepath)" || return "$SHELL_FALSE"

    if fs::path::is_not_exists "$filepath_dd5afa6e"; then
        ldebug "blacklist file(${filepath_dd5afa6e}) not exist."
        return "$SHELL_TRUE"
    fi
    temp_str_dd5afa6e=$(cat "$filepath_dd5afa6e") || return "$SHELL_FALSE"

    array::readarray blacklist_dd5afa6e <<<"$temp_str_dd5afa6e" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprcursor::cursor::blacklist::add() {
    local name="$1"
    shift

    local blacklist_filepath=""
    local blacklist=()

    blacklist_filepath="$(hyprcursor::cursor::blacklist::filepath)" || return "$SHELL_FALSE"

    if string::is_empty "$name"; then
        linfo "cursor theme name is empty."
        return "$SHELL_TRUE"
    fi

    hyprcursor::cursor::blacklist::list blacklist || return "$SHELL_FALSE"

    if array::is_contain blacklist "$name"; then
        linfo "cursor theme(${name}) is blacklisted."
        return "$SHELL_TRUE"
    fi

    fs::directory::dirname_create_recursive "${blacklist_filepath}" || return "$SHELL_FALSE"

    echo "$name" >>"$blacklist_filepath" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function hyprcursor::cursor::blacklist::add_current() {

    local current_cursor_name=""

    current_cursor_name=$(hyprcursor::cursor::get_current_theme_name) || return "$SHELL_FALSE"

    hyprcursor::cursor::blacklist::add "$current_cursor_name" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function hyprcursor::cursor::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(hyprcursor::cursor::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    # log::level::set "$LOG_LEVEL_DEBUG" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprcursor::cursor::list() {
    local -n cursor_list_3291c4e7="$1"
    shift

    local temp_str_3291c4e7=""
    temp_str_3291c4e7=$(find "/usr/share/icons" -type f -name index.theme -exec cat {} + | grep -oE "^Name=.*" | grep -vE 'Right$' | awk -F '=' '{print $2}') || return "$SHELL_FALSE"

    array::readarray cursor_list_3291c4e7 <<<"$temp_str_3291c4e7" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprcursor::cursor::random() {
    local blacklist=()
    local cursor_list=()
    local random_index=0
    local length=0
    local name=''

    hyprcursor::cursor::blacklist::list blacklist || return "$SHELL_FALSE"
    hyprcursor::cursor::list cursor_list || return "$SHELL_FALSE"

    ldebug "blacklist cursor themes: $(array::join_with blacklist ',')"
    ldebug "system all cursor themes: $(array::join_with cursor_list ',')"

    # 过滤掉黑名单中的
    for name in "${blacklist[@]}"; do
        array::remove cursor_list "$name" || return "$SHELL_FALSE"
    done

    # 过滤掉当前的
    name="$(hyprcursor::cursor::get_current_theme_name)" || return "$SHELL_FALSE"
    array::remove cursor_list "$name" || return "$SHELL_FALSE"

    linfo "filter cursor themes: $(array::join_with cursor_list ',')"

    length=$(array::length cursor_list) || return "$SHELL_FALSE"
    random_index=$(math::rand 0 "$((length - 1))") || return "$SHELL_FALSE"

    name="${cursor_list[$random_index]}"

    echo "${name}"
}

function hyprcursor::cursor::set_random() {
    local name=""
    name=$(hyprcursor::cursor::random) || return "$SHELL_FALSE"

    linfo "set cursor theme: ${name}"

    cmd::run_cmd_with_history -- hyprctl setcursor "{{${name}}}" 24 || return "$SHELL_FALSE"

    # 设置 flatpak 应用
    flatpak::override::environment::allow --scope=user "XCURSOR_THEME" "${name}" || return "${SHELL_FALSE}"
    flatpak::override::environment::allow --scope=user "XCURSOR_SIZE" "24" || return "${SHELL_FALSE}"

    return "$SHELL_TRUE"
}

function hyprcursor::cursor::main() {
    local command="$1"

    hyprcursor::cursor::set_log || return "$SHELL_FALSE"

    case "$command" in
    blacklist::add)
        hyprcursor::cursor::blacklist::add_current || return "$SHELL_FALSE"
        hyprcursor::cursor::set_random || return "$SHELL_FALSE"
        ;;
    *)
        hyprcursor::cursor::set_random || return "$SHELL_FALSE"
        ;;
    esac

    return "$SHELL_TRUE"
}

hyprcursor::cursor::main "$@"
