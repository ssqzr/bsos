#!/bin/bash

if [ -n "${SCRIPT_DIR_37054d6f}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_37054d6f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/../float.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_37054d6f}/disk.sh"

function storage::disk::partition::list() {
    local -n partitions_8b9d2b6c="$1"
    shift
    local path="$1"
    shift

    local temp_str_8b9d2b6c

    temp_str_8b9d2b6c=$(LANG=C lsblk -n -p -a -o PATH "${path}") || return "${SHELL_FALSE}"
    array::readarray "${!partitions_8b9d2b6c}" < <(echo "${temp_str_8b9d2b6c}")
    array::remove "${!partitions_8b9d2b6c}" "${path}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::free_list() {
    local -n free_space_bb113365="$1"
    shift
    local path_bb113365="$1"
    shift

    local partitions_bb113365
    local partition
    local start
    local end
    local sector_count
    local first_sector
    local last_sector

    sector_count=$(storage::disk::sector::count "${path_bb113365}") || return "${SHELL_FALSE}"

    storage::disk::partition::list "partitions_bb113365" "${path_bb113365}" || return "${SHELL_FALSE}"

    start=0
    for partition in "${partitions_bb113365[@]}"; do
        first_sector=$(storage::disk::partition::first_sector "${partition}") || return "${SHELL_FALSE}"
        last_sector=$(storage::disk::partition::last_sector "${partition}") || return "${SHELL_FALSE}"
        if [ "$start" -lt "$first_sector" ]; then
            ((end = first_sector - 1))
            array::rpush "${!free_space_bb113365}" "${start} ${end}" || return "${SHELL_FALSE}"
        fi
        ((start = last_sector + 1))
    done
    if [ "$start" -lt "$sector_count" ]; then
        ((end = sector_count - 1))
        array::rpush "${!free_space_bb113365}" "${start} ${end}" || return "${SHELL_FALSE}"
    fi
    return "${SHELL_TRUE}"
}

function storage::disk::partition::path_by_mount_point() {
    local mount_point="$1"
    shift

    local path

    path=$(LANG=C lsblk -n -p -o PATH,MOUNTPOINTS | grep -w "${mount_point}" | awk '{print $1}') || return "${SHELL_FALSE}"

    echo "${path}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::id() {
    local path="$1"
    shift

    local id

    # PARTUUID  是分区的标识
    # PTUUID    是分区表的标识
    # UUID      是文件系统的标识
    # 如果一个磁盘有多个分区，那么每个分区的 PARTUUID 是不一样的， PTUUID 是一样的
    id=$(LANG=C lsblk -n -o PARTUUID "${path}") || return "${SHELL_FALSE}"
    id=$(string::trim "${id}") || return "${SHELL_FALSE}"
    echo "${id}"
    return "${SHELL_TRUE}"
}

# 分区在分区表的位置
function storage::disk::partition::number() {
    local path="$1"
    shift

    if fs::path::is_not_exists "${path}"; then
        lerror "partition(${path}) not exist"
        return "${SHELL_FALSE}"
    fi

    local number

    number=$(LANG=C lsblk -n -o PARTN "${path}" 2>/dev/null) || return "${SHELL_FALSE}"
    number=$(string::trim "${number}") || return "${SHELL_FALSE}"

    echo "${number}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::size_byte() {
    local path="$1"
    shift

    local size_byte

    size_byte=$(LANG=C lsblk -n -o SIZE --bytes -d "${path}") || return "${SHELL_FALSE}"
    size_byte=$(string::trim "${size_byte}") || return "${SHELL_FALSE}"

    echo "${size_byte}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::size_gb() {
    local path="$1"
    shift
    local base="${1:-1024}"
    shift

    local size_byte
    local size_gb

    size_byte=$(storage::disk::partition::size_byte "${path}") || return "${SHELL_FALSE}"
    # 保留两位小数
    size_gb=$(float::div "${size_byte}" "$((base * base * base))") || return "${SHELL_FALSE}"
    echo "${size_gb}"

    return "${SHELL_TRUE}"
}

function storage::disk::partition::first_sector() {
    local path="$1"
    shift

    local first_sector
    # local disk_path

    # disk_path="$(storage::disk::path_by_partition "${path}")" || return "${SHELL_FALSE}"
    # first_sector=$(LANG=C fdisk -l "${disk_path}" | grep -w "${path}" | awk '{print $2}') || return "${SHELL_FALSE}"

    first_sector="$(LANG=C lsblk -n -o START "${path}")" || return "${SHELL_FALSE}"

    first_sector=$(string::trim "${first_sector}") || return "${SHELL_FALSE}"
    echo "${first_sector}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::last_sector() {
    local path="$1"
    shift

    local first_sector
    local last_sector
    local size_byte
    local logical_sector_size_byte
    local temp_str

    temp_str="$(LANG=C lsblk -n --bytes -o LOG-SEC,START,SIZE "${path}")" || return "${SHELL_FALSE}"

    logical_sector_size_byte="$(echo "${temp_str}" | awk '{print $1}')" || return "${SHELL_FALSE}"
    logical_sector_size_byte=$(string::trim "${logical_sector_size_byte}") || return "${SHELL_FALSE}"

    first_sector="$(echo "${temp_str}" | awk '{print $2}')" || return "${SHELL_FALSE}"
    first_sector=$(string::trim "${first_sector}") || return "${SHELL_FALSE}"

    size_byte="$(echo "${temp_str}" | awk '{print $3}')" || return "${SHELL_FALSE}"
    size_byte=$(string::trim "${size_byte}") || return "${SHELL_FALSE}"

    ((last_sector = first_sector + size_byte / logical_sector_size_byte - 1))
    last_sector=$(string::trim "${last_sector}") || return "${SHELL_FALSE}"

    echo "${last_sector}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::filesystem::id() {
    local path="$1"
    shift

    local id

    id=$(LANG=C lsblk -n -o UUID "${path}") || return "${SHELL_FALSE}"
    id=$(string::trim "${id}") || return "${SHELL_FALSE}"

    echo "${id}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::filesystem::type() {
    local path="$1"
    shift

    local fs_type

    fs_type=$(LANG=C lsblk -n -o FSTYPE "${path}") || return "${SHELL_FALSE}"
    fs_type=$(string::trim "${fs_type}") || return "${SHELL_FALSE}"

    echo "${fs_type}"

    return "${SHELL_TRUE}"
}

function storage::disk::partition::mount_points() {
    # shellcheck disable=SC2034
    local -n mount_points_d89bed32="$1"
    shift
    local path="$1"
    shift

    local temp_str_d89bed32

    temp_str_d89bed32="$(LANG=C lsblk -n -o MOUNTPOINTS "${path}")" || return "${SHELL_FALSE}"
    array::readarray mount_points_d89bed32 < <(echo "${temp_str_d89bed32}")

    return "${SHELL_TRUE}"
}

function storage::disk::partition::create::_last_free_gen_start_sector() {
    local path="$1"
    shift

    # 倍数
    local factor
    # 磁盘总扇区数
    local sector_count
    # 磁盘逻辑扇区大小
    local logical_sector_size_byte
    # 磁盘物理扇区大小
    local physical_sector_size_byte
    # https://www.diskgenius.cn/exp/about-4k-alignment.php
    # Windows系统默认对齐的扇区数是2048。这个数值基本上能满足几乎所有磁盘的4K对齐要求了。
    local default_sector=2048
    # 分区列表
    local partitions
    local temp
    # 最小扇区
    local min_sector

    sector_count="$(storage::disk::sector::count "${path}")" || return "${SHELL_FALSE}"
    physical_sector_size_byte=$(storage::disk::sector::physical_size_byte "${path}") || return "${SHELL_FALSE}"
    logical_sector_size_byte=$(storage::disk::sector::logical_size_byte "${path}") || return "${SHELL_FALSE}"

    ((factor = physical_sector_size_byte / logical_sector_size_byte))

    # 获取分区列表
    storage::disk::partition::list partitions "${path}" || return "${SHELL_FALSE}"
    if array::is_empty partitions; then
        min_sector=1
    else
        temp="$(array::last partitions)" || return "${SHELL_FALSE}"
        min_sector="$(storage::disk::partition::last_sector "${temp}")" || return "${SHELL_FALSE}"
        ((min_sector += 1))
    fi

    if [ "${min_sector}" -lt "${default_sector}" ]; then
        ldebug "min_sector(${min_sector}) < default_sector(${default_sector}), set to default_sector(${default_sector})"
        min_sector="${default_sector}"
    fi

    if [ "$min_sector" -gt "${sector_count}" ]; then
        lerror "min_sector(${min_sector}) > disk sector count(${sector_count})"
        return "$SHELL_FALSE"
    fi

    if [ "${factor}" -ge "${min_sector}" ]; then
        echo "${factor}"
        return "${SHELL_TRUE}"
    fi

    # 判断是否能整除
    ((temp = min_sector % factor))
    if [ ${temp} -eq 0 ]; then
        echo "${min_sector}"
        return "${SHELL_TRUE}"
    fi

    ((temp = min_sector / min_sector))
    ((temp = (temp + 1) * factor))
    echo "${temp}"

    return "${SHELL_TRUE}"
}

function storage::disk::partition::create::_last_free_gen_end_sector() {
    local path="$1"
    shift
    local start_sector="$1"
    shift

    # 倍数
    local factor
    # 磁盘总扇区数
    local sector_count
    # 磁盘逻辑扇区大小
    local logical_sector_size_byte
    # 磁盘物理扇区大小
    local physical_sector_size_byte
    local temp
    local end_sector

    sector_count="$(storage::disk::sector::count "${path}")" || return "${SHELL_FALSE}"
    physical_sector_size_byte=$(storage::disk::sector::physical_size_byte "${path}") || return "${SHELL_FALSE}"
    logical_sector_size_byte=$(storage::disk::sector::logical_size_byte "${path}") || return "${SHELL_FALSE}"

    ((factor = physical_sector_size_byte / logical_sector_size_byte))

    # 最大的整GB大小
    ((temp = (sector_count - start_sector) / 1024 / 1024 / 1024))
    ((end_sector = start_sector + temp * 1024 * 1024 * 1024))

    echo "${end_sector}"

    return "${SHELL_TRUE}"
}

function storage::disk::partition::create::_check_sector_range() {
    local path="$1"
    shift
    local start_sector="$1"
    shift
    local end_sector="$1"
    shift

    local free_spaces
    local temp_str
    local free_start
    local free_end

    if [ "${start_sector}" -ge "${end_sector}" ]; then
        lerror "param start_sector(${start_sector}) >= end_sector(${end_sector})"
        return "${SHELL_FALSE}"
    fi

    storage::disk::partition::free_list free_spaces "${path}" || return "${SHELL_FALSE}"

    for temp_str in "${free_spaces[@]}"; do
        free_start="$(echo "${temp_str}" | cut -d' ' -f1)" || return "${SHELL_FALSE}"
        free_end="$(echo "${temp_str}" | cut -d' ' -f2)" || return "${SHELL_FALSE}"
        if [ "${start_sector}" -ge "${free_start}" ] && [ "${end_sector}" -le "${free_end}" ]; then
            return "${SHELL_TRUE}"
        fi
    done

    return "${SHELL_FALSE}"
}

function storage::disk::partition::create::_check_partition_type() {
    local partition_type="$1"
    shift
    local valid_types=("primary" "logical" "extended")

    if array::contains valid_types "${partition_type}"; then
        return "${SHELL_TRUE}"
    fi
    lerror "unknown partition type ${partition_type}, valid types: ${valid_types[*]}"
    return "${SHELL_FALSE}"
}

# 创建分区
function storage::disk::partition::create() {
    # 磁盘路径
    local path
    local start_sector
    local end_sector
    # 分区类型，如: primary 、 logical 、 extended ，并且只有 msdos 或者 dvh 分区表才支持
    local part_type
    # 必须为 gpt 分区表的分区指定 name
    local name
    # 对齐方式
    # none
    #       Use the minimum alignment allowed by the disk type. 使用磁盘类型允许的最小对齐方式。
    # cylinder
    #       Align partitions to cylinders. 将分区与圆柱体对齐。
    # minimal
    #       Use minimum alignment as given by the disk topology information. This and the opt value will
    #       use layout information provided by the disk to align the logical partition table addresses to
    #       actual physical blocks on the disks. The min value is the minimum alignment needed to align
    #       the partition properly to physical blocks, which avoids performance degradation.
    #       使用磁盘拓扑信息给出的最小对齐方式。
    #       该值和 opt 值将使用磁盘提供的布局信息将逻辑分区表地址与磁盘上的实际物理块对齐。
    #       最小值是将分区正确对齐到物理块所需的最小对齐方式，这可以避免性能下降。
    # optimal
    #       Use optimum alignment as given by the disk topology information. This aligns to a multiple of
    #       the physical block size in a way that guarantees optimal performance.
    #       使用磁盘拓扑信息给出的最佳对齐方式。这以保证最佳性能的方式与物理块大小的倍数对齐。
    # 不同的 align 导致创建出来的分区真实的 start 和 end 扇区和参数指定的 start 和 end 会不一样
    local align
    local is_sudo="$SHELL_TRUE"
    local password

    local param
    local partition_table_type

    for param in "$@"; do
        case "$param" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        --part-type=*)
            parameter::parse_string --option="$param" part_type || return "${SHELL_FALSE}"
            ;;
        --name=*)
            parameter::parse_string --option="$param" name || return "${SHELL_FALSE}"
            ;;
        --align=*)
            parameter::parse_string --option="$param" align || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v path ]; then
                path="$param"
                continue
            fi
            if [ ! -v start_sector ]; then
                start_sector="$param"
                continue
            fi
            if [ ! -v end_sector ]; then
                end_sector="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    align=${align:-optimal}

    if [ ! -v path ]; then
        lerror "parameter path is not set"
        return "${SHELL_FALSE}"
    fi
    if string::is_empty "${path}"; then
        lerror "parameter path is empty"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v start_sector ]; then
        lerror "parameter start_sector is not set"
        return "${SHELL_FALSE}"
    fi

    if string::is_empty "${start_sector}"; then
        lerror "parameter start_sector is empty"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v end_sector ]; then
        lerror "parameter end_sector is not set"
        return "${SHELL_FALSE}"
    fi

    if string::is_empty "${end_sector}"; then
        lerror "parameter end_sector is empty"
        return "${SHELL_FALSE}"
    fi

    # 获取分区表类型
    partition_table_type="$(storage::disk::partition_table::type "${path}")" || return "${SHELL_FALSE}"
    case "${partition_table_type}" in
    gpt)
        if string::is_empty "${name}"; then
            # gpt 分区表必须指定 name
            name='""'
        fi
        if string::is_not_empty "$part_type"; then
            lerror "GPT partition table does not support --part-type option"
            return "${SHELL_FALSE}"
        fi
        ;;
    dos)
        if string::is_not_empty "${name}"; then
            lerror "DOS partition table does not support --name option"
            return "${SHELL_FALSE}"
        fi
        storage::disk::partition::create::_check_partition_type "${part_type}" || return "${SHELL_FALSE}"
        ;;
    *)
        lerror "unsupported partition table type ${partition_table_type}"
        return "${SHELL_FALSE}"
        ;;
    esac

    storage::disk::partition::create::_check_sector_range "${path}" "${start_sector}" "${end_sector}" || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" --password="$password" -- parted -a optimal -s "${path}" mkpart "${part_type}" "{{$name}}" "${start_sector}s" "${end_sector}s" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function storage::disk::partition::delete_by_number() {

    local path="$1"
    shift
    local number="$1"
    shift

    if string::is_empty "${number}"; then
        lerror "parameter number is empty"
        return "${SHELL_FALSE}"
    fi

    cmd::run_cmd_with_history --sudo -- parted -s "${path}" rm "${number}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::delete_by_path() {
    local disk_path="$1"
    shift
    local partition_path="$1"
    shift

    if fs::path::is_not_exists "${partition_path}"; then
        ldebug "partition() is not exists, ignore delete."
        return "${SHELL_TRUE}"
    fi

    local number
    number="$(storage::disk::partition::number "${partition_path}")" || return "${SHELL_FALSE}"
    storage::disk::partition::delete_by_number "${disk_path}" "${number}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function storage::disk::partition::delete_all() {
    local disk_path="$1"
    shift

    local partitions
    local partition
    storage::disk::partition::list partitions "${disk_path}" || return "${SHELL_FALSE}"

    for partition in "${partitions[@]}"; do
        storage::disk::partition::delete_by_path "${disk_path}" "${partition}" || return "${SHELL_FALSE}"
    done

    return "${SHELL_TRUE}"
}
