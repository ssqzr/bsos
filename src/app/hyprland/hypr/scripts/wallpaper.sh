#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_154f29f7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [ -z "$HOME" ]; then
    echo "env HOME is not set"
    exit 1
fi
src_dir=""
source_filepath=""
src_dir="${SCRIPT_DIR_154f29f7%%\/app\/hyprland*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_154f29f7}" ]; then
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

function hyprland::cache_dir() {
    local cache_dir="$HOME/.cache/hypr"
    echo "$cache_dir"
}

function hyprland::wallpaper::directory() {
    local cache_dir
    cache_dir="$(hyprland::cache_dir)"
    local wallpaper_dir="$cache_dir/wallpapers"
    echo "$wallpaper_dir"
}

function hyprland::wallpaper::today() {
    date "+%Y-%m-%d"
}

function hyprland::wallpaper::bing_wallpaper_filepath() {
    local monitor_name="$1"
    local wallpaper_dir
    local day

    wallpaper_dir="$(hyprland::wallpaper::directory)" || return "$SHELL_FALSE"

    day=$(hyprland::wallpaper::today)
    echo "${wallpaper_dir}/bing_${day}_${monitor_name}.jpg"
}

function hyprland::wallpaper::bing_wallpaper_url() {
    local index="$1"
    local url

    # https://stackoverflow.com/questions/10639914/is-there-a-way-to-get-bings-photo-of-the-day
    url=$(curl -s -k -L "https://www.bing.com/HPImageArchive.aspx?format=js&idx=${index}&n=1&mkt=zh-cn" | yq '.images[0].url') || return "$SHELL_FALSE"

    url="https://www.bing.com${url}"
    echo "$url"
}

function hyprland::wallpaper::bing_wallpaper_download() {
    local index="$1"
    local filepath="$2"
    local tmp_filepath="${filepath}.tmp"

    local url
    local wallpaper_dir

    url=$(hyprland::wallpaper::bing_wallpaper_url "$index") || return "$SHELL_FALSE"

    # 使用curl总是出现命令执行完，立即检测文件不存在的情况
    # cmd::run_cmd_with_history curl -s -k -L -o "$filepath" "'$url'" || return "$SHELL_FALSE"
    # wget 命令失败时可能会残留空文件，所以先保存到临时文件
    cmd::run_cmd_with_history wget -q -O "$tmp_filepath" "'$url'" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history mv -f "'$tmp_filepath'" "'$filepath'" || return "$SHELL_FALSE"

    if [ ! -f "$filepath" ]; then
        # 刚开始在虚拟机测试，当 curl 执行完成后，检测下载的文件并不存在
        # 所以这里加一个判断记录日志方便排查
        # 目前还不知道为什么会出现这种情况，可能是虚拟机慢的原因
        lerror "filepath=$filepath not exist"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

function hyprland::wallpaper::clean_old_file() {
    local wallpaper_dir
    local today

    wallpaper_dir="$(hyprland::wallpaper::directory)" || return "$SHELL_FALSE"
    if [ ! -e "$wallpaper_dir" ]; then
        cmd::run_cmd_with_history mkdir -p "$wallpaper_dir" || return "${SHELL_FALSE}"
        return "$SHELL_TRUE"
    fi

    today="$(hyprland::wallpaper::today)" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history find "$wallpaper_dir" -type f -not -name "*${today}*" -exec rm -f {} "\;" || return "${SHELL_FALSE}"

    return "$SHELL_TRUE"
}

# 因为当前脚本是和hyprpaper一起运行的，可能hyprpaper还没准备好，此时调用命令会报错
function hyprland::wallpaper::check_hyprpaper_ready() {
    local output
    while true; do
        output=$(hyprctl hyprpaper unload unused)
        if [ "$output" != "ok" ]; then
            ldebug "hyprpaper not ready, output=$output, sleep 1s..."
            sleep 1
        else
            break
        fi
    done
    ldebug "hyprpapre ready"
}

function hyprland::wallpaper::set_log_file() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::set_log_file "$(hyprland::cache_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprland::wallpaper::main() {
    local filepath
    local monitors
    local monitor_count
    local index
    local name

    hyprland::wallpaper::set_log_file || return "$SHELL_FALSE"

    hyprland::wallpaper::check_hyprpaper_ready

    hyprland::wallpaper::clean_old_file || return "$SHELL_FALSE"

    monitors="$(hyprctl monitors -j)" || return "$SHELL_FALSE"

    monitor_count=$(echo "$monitors" | yq 'length')

    for ((index = 0; index < monitor_count; index++)); do
        name="$(echo "$monitors" | yq ".[${index}].name")" || return "$SHELL_FALSE"

        filepath="$(hyprland::wallpaper::bing_wallpaper_filepath "${name}")" || return "$SHELL_FALSE"

        if [ ! -f "$filepath" ]; then
            hyprland::wallpaper::bing_wallpaper_download "${index}" "${filepath}" || return "$SHELL_FALSE"
        else
            linfo "wallpaper $filepath exist, skip download"
        fi

        cmd::run_cmd_with_history hyprctl hyprpaper preload "${filepath}"
        cmd::run_cmd_with_history hyprctl hyprpaper wallpaper "${name},${filepath}"
        # 应用所有显示器
        # cmd::run_cmd_with_history hyprctl hyprpaper wallpaper "${filepath}"

    done

    cmd::run_cmd_with_history hyprctl hyprpaper unload unused || return "$SHELL_FALSE"

    # 获取第一个显示器的名称
    name="$(echo "$monitors" | yq ".[0].name")" || return "$SHELL_FALSE"
    filepath="$(hyprland::wallpaper::bing_wallpaper_filepath "${name}")" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history wallust -q "${filepath}"

    return "$SHELL_TRUE"
}

hyprland::wallpaper::main "$@"
