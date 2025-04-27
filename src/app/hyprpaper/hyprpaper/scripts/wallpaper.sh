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
src_dir="${SCRIPT_DIR_154f29f7%%\/app\/hyprpaper*}"
if [ -d "$src_dir" ] && [ "${src_dir}" != "${SCRIPT_DIR_154f29f7}" ]; then
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

function hyprpaper::wallpaper::log_dir() {
    local log_dir="$HOME/.cache/hyprpaper/log"
    echo "$log_dir"
}

function hyprpaper::wallpaper::directory() {
    local wallpaper_dir="$HOME/.cache/hyprpaper/wallpapers"
    echo "$wallpaper_dir"
}

function hyprpaper::wallpaper::today() {
    date "+%Y-%m-%d"
}

function hyprpaper::wallpaper::bing_wallpaper_filepath() {
    local monitor="$1"
    local wallpaper_dir
    local day

    wallpaper_dir="$(hyprpaper::wallpaper::directory)" || return "$SHELL_FALSE"

    day=$(hyprpaper::wallpaper::today)
    echo "${wallpaper_dir}/bing_${day}_${monitor}.jpg"
}

function hyprpaper::wallpaper::bing_wallpaper_url() {
    local index="$1"
    local url
    local temp_str

    # https://stackoverflow.com/questions/10639914/is-there-a-way-to-get-bings-photo-of-the-day
    temp_str=$(curl -s -k -L "https://www.bing.com/HPImageArchive.aspx?format=js&idx=${index}&n=1&mkt=zh-cn")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get bing.com wallpaper info failed"
        return "$SHELL_FALSE"
    fi

    url=$(echo "$temp_str" | yq '.images[0].url') || return "$SHELL_FALSE"

    if [ -z "$url" ] || [ "$url" == "null" ]; then
        lerror "get bing.com wallpaper image url failed"
        return "$SHELL_FALSE"
    fi

    url="https://www.bing.com${url}"
    echo "$url"
}

function hyprpaper::wallpaper::bing_wallpaper_download() {
    local index="$1"
    local filepath="$2"
    local tmp_filepath="${filepath}.tmp"

    local url
    local wallpaper_dir

    url=$(hyprpaper::wallpaper::bing_wallpaper_url "$index") || return "$SHELL_FALSE"

    # 使用curl总是出现命令执行完，立即检测文件不存在的情况
    # cmd::run_cmd_with_history -- curl -s -k -L -o "$filepath" "'$url'" || return "$SHELL_FALSE"
    # wget 命令失败时可能会残留空文件，所以先保存到临时文件
    cmd::run_cmd_with_history -- wget -q -O "{{$tmp_filepath}}" "{{$url}}" || return "$SHELL_FALSE"
    fs::file::move "$tmp_filepath" "$filepath" || return "$SHELL_FALSE"

    if [ ! -f "$filepath" ]; then
        # 刚开始在虚拟机测试，当 curl 执行完成后，检测下载的文件并不存在
        # 所以这里加一个判断记录日志方便排查
        # 目前还不知道为什么会出现这种情况，可能是虚拟机慢的原因
        lerror "filepath=$filepath not exist"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

# 一直调用 bing_wallpaper_download 直到下载成功
function hyprpaper::wallpaper::bing_wallpaper_download_wrapper() {
    while true; do
        if hyprpaper::wallpaper::bing_wallpaper_download "$@"; then
            return "$SHELL_TRUE"
        fi
        lerror "call bing_wallpaper_download failed, sleep 1s..."
        sleep 1
    done
}

function hyprpaper::wallpaper::clean_old_file() {
    local wallpaper_dir
    local today

    wallpaper_dir="$(hyprpaper::wallpaper::directory)" || return "$SHELL_FALSE"
    fs::directory::create_recursive "$wallpaper_dir" || return "$SHELL_FALSE"

    today="$(hyprpaper::wallpaper::today)" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history -- find "$wallpaper_dir" -type f -not -name "'*${today}*'" -exec rm -f {} "\;" || return "${SHELL_FALSE}"

    return "$SHELL_TRUE"
}

# 因为当前脚本是和hyprpaper一起运行的，可能hyprpaper还没准备好，此时调用命令会报错
function hyprpaper::wallpaper::check_hyprpaper_ready() {
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

function hyprpaper::wallpaper::set_log() {
    local log_filename="${BASH_SOURCE[0]}"
    log_filename="${log_filename##*/}"
    log::handler::file_handler::register || return "$SHELL_FALSE"
    log::handler::file_handler::set_log_file "$(hyprpaper::wallpaper::log_dir)/${log_filename}.log" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 获取所有显示器的id列表
# 列表通过距离原点的距离进行排序
function hyprpaper::wallpaper::monitors() {
    local -n monitors_name_a4d29a8e="$1"
    shift

    local monitors_a4d29a8e
    local monitor_count_a4d29a8e
    local index_a4d29a8e
    local id_a4d29a8e
    local name_a4d29a8e
    local description_a4d29a8e
    local temp_a4d29a8e
    local distance_a4d29a8e=0
    local x_a4d29a8e
    local y_a4d29a8e
    local min_index_a4d29a8e=0
    local min_distance_a4d29a8e=-1

    monitors_a4d29a8e="$(hyprctl monitors -j)" || return "$SHELL_FALSE"
    monitor_count_a4d29a8e=$(echo "$monitors_a4d29a8e" | yq 'length')

    temp_a4d29a8e=()
    for ((index_a4d29a8e = 0; index_a4d29a8e < monitor_count_a4d29a8e; index_a4d29a8e++)); do
        id_a4d29a8e="$(echo "$monitors_a4d29a8e" | yq ".[${index_a4d29a8e}].id")" || return "$SHELL_FALSE"
        name_a4d29a8e="$(echo "$monitors_a4d29a8e" | yq ".[${index_a4d29a8e}].name")" || return "$SHELL_FALSE"
        description_a4d29a8e="$(echo "$monitors_a4d29a8e" | yq ".[${index_a4d29a8e}].description")" || return "$SHELL_FALSE"
        x_a4d29a8e="$(echo "$monitors_a4d29a8e" | yq ".[${index_a4d29a8e}].x")" || return "$SHELL_FALSE"
        y_a4d29a8e="$(echo "$monitors_a4d29a8e" | yq ".[${index_a4d29a8e}].y")" || return "$SHELL_FALSE"
        distance_a4d29a8e=$((x_a4d29a8e * x_a4d29a8e + y_a4d29a8e * y_a4d29a8e))

        array::rpush temp_a4d29a8e "${id_a4d29a8e}::${name_a4d29a8e}::${description_a4d29a8e}::${distance_a4d29a8e}" || return "$SHELL_FALSE"
    done

    # 按照距离进行排序
    monitors_a4d29a8e=()
    while array::is_not_empty temp_a4d29a8e; do
        min_index_a4d29a8e=0
        min_distance_a4d29a8e=-1
        monitor_count_a4d29a8e=$(array::length temp_a4d29a8e) || return "$SHELL_FALSE"
        for ((index_a4d29a8e = 0; index_a4d29a8e < monitor_count_a4d29a8e; index_a4d29a8e++)); do
            distance_a4d29a8e="$(echo "${temp_a4d29a8e[$index_a4d29a8e]}" | awk -F "::" '{print $4}')"
            if [ "$min_distance_a4d29a8e" -lt 0 ] || [ "$distance_a4d29a8e" -lt "$min_distance_a4d29a8e" ]; then
                min_index_a4d29a8e="$index_a4d29a8e"
                min_distance_a4d29a8e="$distance_a4d29a8e"
            fi
        done

        array::rpush monitors_a4d29a8e "${temp_a4d29a8e[$min_index_a4d29a8e]}" || return "$SHELL_FALSE"
        array::remove_at REF_PLACEHOLDER temp_a4d29a8e "$min_index_a4d29a8e" || return "$SHELL_FALSE"
    done

    linfo "sorted monitors: $(array::join_with monitors_a4d29a8e ', ')"

    monitors_name_a4d29a8e=()
    for temp_a4d29a8e in "${monitors_a4d29a8e[@]}"; do
        name_a4d29a8e="$(echo "$temp_a4d29a8e" | awk -F "::" '{print $2}')"
        array::rpush "${!monitors_name_a4d29a8e}" "$name_a4d29a8e" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function hyprpaper::wallpaper::main() {
    local filepath
    local monitors
    local name
    local index

    hyprpaper::wallpaper::set_log || return "$SHELL_FALSE"

    hyprpaper::wallpaper::check_hyprpaper_ready

    hyprpaper::wallpaper::clean_old_file || return "$SHELL_FALSE"

    hyprpaper::wallpaper::monitors monitors || return "$SHELL_FALSE"

    index=0
    for name in "${monitors[@]}"; do
        filepath="$(hyprpaper::wallpaper::bing_wallpaper_filepath "${name}")" || return "$SHELL_FALSE"

        if fs::path::is_exists "${filepath}"; then
            linfo "wallpaper $filepath exist, skip download"
        else
            hyprpaper::wallpaper::bing_wallpaper_download_wrapper "${index}" "${filepath}" || return "$SHELL_FALSE"
        fi
        cmd::run_cmd_with_history -- hyprctl -q hyprpaper preload "${filepath}"
        cmd::run_cmd_with_history -- hyprctl -q hyprpaper wallpaper "${name},contain:${filepath}"
        # 应用所有显示器
        # cmd::run_cmd_with_history -- hyprctl -q hyprpaper wallpaper "${filepath}"

        index=$((index + 1))
    done

    cmd::run_cmd_with_history -- hyprctl -q hyprpaper unload unused || return "$SHELL_FALSE"

    name="$(array::first monitors)" || return "$SHELL_FALSE"
    filepath="$(hyprpaper::wallpaper::bing_wallpaper_filepath "${name}")" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history -- wallust run "${filepath}"

    return "$SHELL_TRUE"
}

hyprpaper::wallpaper::main "$@"
