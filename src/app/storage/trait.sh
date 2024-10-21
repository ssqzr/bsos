#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_094aa55c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function storage::trait::_get_os_disk() {
    local root_partition_path
    local disk_path
    root_partition_path=$(storage::disk::partition::path_by_mount_point "/") || return "${SHELL_FALSE}"
    disk_path=$(storage::disk::path_by_partition "${root_partition_path}") || return "${SHELL_FALSE}"
    echo "${disk_path}"
    return "${SHELL_TRUE}"
}

function storage::trait::_print_partitions_info() {
    local path="$1"

    local partitions
    local partition

    local id
    local number
    local size_gb_base_1000
    local size_gb_base_1024
    local first_sector
    local last_sector
    local sectors
    local filesystem_id
    local filesystem_type
    local mount_points
    local mount_point

    local index
    local length

    local format="%-6s %-20s %-20s %-20s %-20s %-20s %-36s %-10s %s"

    storage::disk::partition::list partitions "${path}" || return "${SHELL_FALSE}"

    println_info --format="${format}" "Number" "Start" "End" "Sectors" "Size GB(1000)" "Size GB(1024)" "Filesystem ID" "Filesystem Type" "Mount Point"

    for partition in "${partitions[@]}"; do
        id="$(storage::disk::partition::id "${partition}")" || return "${SHELL_FALSE}"
        number="$(storage::disk::partition::number "${partition}")" || return "${SHELL_FALSE}"
        size_gb_base_1000="$(storage::disk::partition::size_gb "${partition}" 1000)" || return "${SHELL_FALSE}"
        size_gb_base_1024="$(storage::disk::partition::size_gb "${partition}" 1024)" || return "${SHELL_FALSE}"
        first_sector="$(storage::disk::partition::first_sector "${partition}")" || return "${SHELL_FALSE}"
        last_sector="$(storage::disk::partition::last_sector "${partition}")" || return "${SHELL_FALSE}"
        ((sectors = last_sector - first_sector + 1))
        filesystem_id="$(storage::disk::partition::filesystem::id "${partition}")" || return "${SHELL_FALSE}"
        filesystem_type="$(storage::disk::partition::filesystem::type "${partition}")" || return "${SHELL_FALSE}"
        storage::disk::partition::mount_points mount_points "${partition}" || return "${SHELL_FALSE}"

        if array::is_empty mount_points; then
            array::rpush mount_points "N/A"
        fi

        length="$(array::length mount_points)" || return "${SHELL_FALSE}"
        for ((index = 0; index < length; index++)); do
            mount_point="$(array::index mount_points "${index}")" || return "${SHELL_FALSE}"
            if [ "$index" -eq 0 ]; then
                println_info --format="${format}" "$number" "$first_sector" "$last_sector" "$sectors" "$size_gb_base_1000" "$size_gb_base_1024" "$filesystem_id" "$filesystem_type" "${mount_point}" || return "${SHELL_FALSE}"
                continue
            fi
            println_info --format="${format}" "" "" "" "" "" "" "" "" "${mount_point}" || return "${SHELL_FALSE}"
        done
    done

}

function storage::trait::_print_free_spaces_info() {
    local path="$1"

    local free_spaces
    local free_space

    local size_byte
    local size_kb_1000
    local size_kb_1024
    local size_mb_1000
    local size_mb_1024
    local size_gb_base_1000
    local size_gb_base_1024
    local first_sector
    local last_sector
    local logical_sector_size_byte
    local sectors

    local temp

    local format="%-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s"

    logical_sector_size_byte="$(storage::disk::sector::logical_size_byte "${path}")" || return "${SHELL_FALSE}"

    storage::disk::partition::free_list free_spaces "${path}" || return "${SHELL_FALSE}"

    println_info --format="${format}" "Start" "End" "Sectors" "Size Byte" "Size KB(1000)" "Size KB(1024)" "Size MB(1000)" "Size MB(1024)" "Size GB(1000)" "Size GB(1024)"

    for free_space in "${free_spaces[@]}"; do
        first_sector="$(echo "${free_space}" | cut -d' ' -f1)" || return "${SHELL_FALSE}"
        last_sector="$(echo "${free_space}" | cut -d' ' -f2)" || return "${SHELL_FALSE}"
        ((sectors = last_sector - first_sector + 1))
        ((size_byte = sectors * logical_sector_size_byte))

        size_kb_1000="$(float::div "${size_byte}" 1000)" || return "${SHELL_FALSE}"
        size_kb_1024="$(float::div "${size_byte}" 1024)" || return "${SHELL_FALSE}"

        size_mb_1000="$(float::div "${size_byte}" $((1000 * 1000)))" || return "${SHELL_FALSE}"
        size_mb_1024="$(float::div "${size_byte}" $((1024 * 1024)))" || return "${SHELL_FALSE}"

        size_gb_base_1000="$(float::div "${size_byte}" $((1000 * 1000 * 1000)))" || return "${SHELL_FALSE}"
        size_gb_base_1024="$(float::div "${size_byte}" $((1024 * 1024 * 1024)))" || return "${SHELL_FALSE}"

        println_info --format="${format}" "$first_sector" "$last_sector" "$sectors" "$size_byte" "$size_kb_1000" "$size_kb_1024" "$size_mb_1000" "$size_mb_1024" "$size_gb_base_1000" "$size_gb_base_1024" || return "${SHELL_FALSE}"
    done
    return "${SHELL_TRUE}"
}

function storage::trait::_print_disk_info() {
    local path="$1"

    local model
    local size_gb_base_1000
    local size_gb_base_1024
    local wwn
    local physical_sector_size_byte
    local logical_sector_size_byte
    local sector_count
    local partition_table_type

    model=$(storage::disk::model "${path}") || return "${SHELL_FALSE}"
    size_gb_base_1000=$(storage::disk::size_gb "${path}" 1000) || return "${SHELL_FALSE}"
    size_gb_base_1024=$(storage::disk::size_gb "${path}" 1024) || return "${SHELL_FALSE}"
    wwn="$(storage::disk::wwn "${path}")" || return "${SHELL_FALSE}"
    physical_sector_size_byte="$(storage::disk::sector::physical_size_byte "${path}")" || return "${SHELL_FALSE}"
    logical_sector_size_byte="$(storage::disk::sector::logical_size_byte "${path}")" || return "${SHELL_FALSE}"
    sector_count="$(storage::disk::sector::count "${path}")" || return "${SHELL_FALSE}"
    partition_table_type="$(storage::disk::partition_table::type "${path}")" || return "${SHELL_FALSE}"

    # 打印磁盘路径
    println_info "Device: $path" || return "${SHELL_FALSE}"
    # 打印磁盘 model
    println_info "Model: $model" || return "${SHELL_FALSE}"
    # 打印磁盘ID
    println_info "WWN: $wwn" || return "${SHELL_FALSE}"
    println_info "" || return "${SHELL_FALSE}"

    # 分区信息
    println_info "Partitions: " || return "${SHELL_FALSE}"
    storage::trait::_print_partitions_info "${path}" || return "${SHELL_FALSE}"
    println_info "" || return "${SHELL_FALSE}"

    # 空闲空间信息
    println_info "Free Spaces: " || return "${SHELL_FALSE}"
    storage::trait::_print_free_spaces_info "${path}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 指定使用的包管理器
function storage::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function storage::trait::package_name() {
    echo ""
}

# 简短的描述信息，查看包的信息的时候会显示
function storage::trait::description() {
    echo "storage manager."
    return "$SHELL_TRUE"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function storage::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function storage::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function storage::trait::install() {
    # package_manager::install "$(storage::trait::package_manager)" "$(storage::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function storage::trait::post_install() {
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function storage::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function storage::trait::uninstall() {
    # package_manager::uninstall "$(storage::trait::package_manager)" "$(storage::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function storage::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function storage::trait::upgrade() {
    # package_manager::upgrade "$(storage::trait::package_manager)" "$(storage::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function storage::trait::fixme() {

    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "{PM_APP_NAME}: The disk management feature has not been implemented yet, the scenario is complex and there are too many function points. "
    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "{PM_APP_NAME}: Please do disk management manually."
    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "{PM_APP_NAME}: You can use parted or fdisk to manage disk, oruse cfdisk for tui."
    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "{PM_APP_NAME}: Currently only basic disk information is displayed."

    local disks
    local disk
    local os_disk

    os_disk=$(storage::trait::_get_os_disk) || return "${SHELL_FALSE}"

    storage::disk::list disks || return "${SHELL_FALSE}"
    for disk in "${disks[@]}"; do
        if [ "${disk}" == "${os_disk}" ]; then
            lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "{PM_APP_NAME}: disk(${os_disk}) is system disk"
        fi

        storage::trait::_print_disk_info "${disk}" || return "${SHELL_FALSE}"
        println_info "======================================="
    done
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function storage::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function storage::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()
    apps+=("pacman:nfs-utils")
    apps+=("pacman:parted")
    # KDE 磁盘管理工具
    apps+=("pacman:partitionmanager")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function storage::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function storage::trait::main() {
    return "${SHELL_TRUE}"
}

storage::trait::main
