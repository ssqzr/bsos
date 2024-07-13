#!/bin/bash

if [ -n "${SCRIPT_DIR_f3dd15b5}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_f3dd15b5="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_f3dd15b5}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_f3dd15b5}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_f3dd15b5}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_f3dd15b5}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_f3dd15b5}/../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_f3dd15b5}/../float.sh"

function storage::disk::list() {
    local -n disks_29302f7a="$1"
    shift
    local temp_str_29302f7a

    temp_str_29302f7a=$(LANG=C lsblk -n -o PATH -p -a -d) || return "${SHELL_FALSE}"
    array::readarray "${!disks_29302f7a}" < <(echo "${temp_str_29302f7a}")
    return "${SHELL_TRUE}"
}

function storage::disk::path_by_partition() {
    local partition_path="$1"
    shift

    local path
    path=$(LANG=C lsblk -n -d -p -o PKNAME "${partition_path}") || return "${SHELL_FALSE}"

    echo "${path}"
    return "${SHELL_TRUE}"
}

function storage::disk::model() {
    local path="$1"
    shift

    local model
    # model=$(sudo LANG=C fdisk -x "${path}" | grep "Disk model" | awk -F ':' '{print $2}') || return "${SHELL_FALSE}"
    model=$(LANG=C lsblk -n -o MODEL "${path}") || return "${SHELL_FALSE}"
    model=$(string::trim "${model}") || return "${SHELL_FALSE}"
    echo "${model}"
    return "${SHELL_TRUE}"
}

function storage::disk::size_byte() {
    local path="$1"
    shift

    local size_byte

    size_byte=$(LANG=C lsblk -n -o SIZE --bytes -d "${path}") || return "${SHELL_FALSE}"
    size_byte=$(string::trim "${size_byte}") || return "${SHELL_FALSE}"
    echo "${size_byte}"
    return "${SHELL_TRUE}"
}

function storage::disk::size_gb() {
    local path="$1"
    shift
    local base="${1:-1024}"
    shift

    local size_byte
    local size_gb

    size_byte=$(storage::disk::size_byte "${path}") || return "${SHELL_FALSE}"
    # 保留两位小数
    size_gb=$(float::div "${size_byte}" "$((base * base * base))") || return "${SHELL_FALSE}"
    # size_gb 的长度可能小于 3
    # echo "${size_gb:0:-2}.${size_gb: -2}"
    echo "${size_gb}"
    return "${SHELL_TRUE}"
}

function storage::disk::wwn() {
    local path="$1"
    shift
    local wwn
    wwn=$(LANG=C lsblk -n -d -o WWN "${path}") || return "${SHELL_FALSE}"
    wwn=$(string::trim "${wwn}") || return "${SHELL_FALSE}"
    echo "${wwn}"
    return "${SHELL_TRUE}"
}

function storage::disk::sector::physical_size_byte() {
    local path="$1"
    shift

    local size_byte

    size_byte=$(LANG=C lsblk -n -d -o PHY-SEC "${path}") || return "${SHELL_FALSE}"
    size_byte=$(string::trim "${size_byte}") || return "${SHELL_FALSE}"
    echo "${size_byte}"
    return "${SHELL_TRUE}"
}

function storage::disk::sector::logical_size_byte() {
    local path="$1"
    shift

    local size_byte

    size_byte=$(LANG=C lsblk -n -d -o LOG-SEC "${path}") || return "${SHELL_FALSE}"
    size_byte=$(string::trim "${size_byte}") || return "${SHELL_FALSE}"
    echo "${size_byte}"
    return "${SHELL_TRUE}"
}

function storage::disk::sector::count() {
    local path="$1"
    shift

    local count
    local size_byte
    local logical_sector_size_byte

    size_byte="$(storage::disk::size_byte "${path}")" || return "${SHELL_FALSE}"
    logical_sector_size_byte="$(storage::disk::sector::logical_size_byte "${path}")" || return "${SHELL_FALSE}"

    ((count = size_byte / logical_sector_size_byte))
    echo "${count}"
    return "${SHELL_TRUE}"
}

# 检查指定扇区是否对齐，不仅仅适用 4K 对齐。
function storage::disk::sector::check_align() {
    local path="$1"
    shift
    local sector="$1"
    shift

    local min_sector
    local logical_sector_size_byte
    local physical_sector_size_byte
    local temp

    physical_sector_size_byte=$(storage::disk::sector::physical_size_byte "${path}") || return "${SHELL_FALSE}"
    logical_sector_size_byte=$(storage::disk::sector::logical_size_byte "${path}") || return "${SHELL_FALSE}"

    ((min_sector = physical_sector_size_byte / logical_sector_size_byte))
    ((temp = sector % min_sector))

    if [ ${temp} -ne 0 ]; then
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# 分区表类型，例如是 gpt msdos 等
function storage::disk::partition_table::type() {
    local path="$1"
    shift

    local pt_type
    pt_type=$(LANG=C lsblk -n -o PTTYPE "${path}") || return "${SHELL_FALSE}"
    pt_type=$(string::trim "${pt_type}") || return "${SHELL_FALSE}"
    echo "${pt_type}"
    return "${SHELL_TRUE}"
}

# 创建分区表
function storage::disk::partition_table::create() {
    local path="$1"
    shift
    local table_type="${1:-gpt}"
    shift

    cmd::run_cmd_with_history --sudo -- parted -s "${path}" mklabel "${table_type}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}
