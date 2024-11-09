#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_45be7d64="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function swap::trait::memory::size_byte() {
    local size_byte
    size_byte=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}') || return "${SHELL_FALSE}"
    echo "${size_byte}"
    return "${SHELL_TRUE}"
}

function swap::trait::swap::filepath() {
    echo "/swapfile"
    return "${SHELL_TRUE}"
}

# 计算最小的 swap 大小
function swap::trait::swap::min_size_gb() {
    local size_gb=1
    local memory_size_byte
    local memory_size_gb
    memory_size_byte=$(swap::trait::memory::size_byte) || return "${SHELL_FALSE}"

    memory_size_gb=$memory_size_byte
    memory_size_gb=$(math::div "${memory_size_gb}" 1024) || return "${SHELL_FALSE}"
    memory_size_gb=$(math::div "${memory_size_gb}" 1024) || return "${SHELL_FALSE}"
    memory_size_gb=$(math::div "${memory_size_gb}" 1024) || return "${SHELL_FALSE}"

    # 向上取整
    memory_size_gb=$(math::ceil "${memory_size_gb}") || return "${SHELL_FALSE}"

    # 如果内存小于等于 1G ，那么最小的 swap 就是 1G
    while math::lt "$size_gb" "${memory_size_gb}"; do
        size_gb=$(math::mul "${size_gb}" 2) || return "${SHELL_FALSE}"
    done

    linfo "swap size_gb=${size_gb}"
    echo "${size_gb}"

    return "${SHELL_TRUE}"
}

function swap::trait::swap::edit_fstab() {
    local swap_filepath
    swap_filepath=$(swap::trait::swap::filepath) || return "${SHELL_FALSE}"

    # cmd::run_cmd_with_history -- echo "'${swap_filepath} none swap defaults 0 0'" "|" sudo tee -a "/etc/fstab" || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history --sudo -- sed -i -e "'\$a${swap_filepath} none swap defaults 0 0'" "/etc/fstab" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function swap::trait::swap::undo_edit_fstab() {
    local swap_filepath
    swap_filepath=$(swap::trait::swap::filepath) || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history --sudo -- sed -i "'\%${swap_filepath}%d'" "/etc/fstab" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 指定使用的包管理器
function swap::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function swap::trait::package_name() {
    echo "swap"
}

# 简短的描述信息，查看包的信息的时候会显示
function swap::trait::description() {
    # package_manager::package_description "$(swap::trait::package_manager)" "$(swap::trait::package_name)" || return "$SHELL_FALSE"
    echo "make swap file, it is not a real app"
    return "$SHELL_TRUE"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function swap::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function swap::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function swap::trait::install() {
    # package_manager::install "$(swap::trait::package_manager)" "$(swap::trait::package_name)" || return "${SHELL_FALSE}"

    local swap_filepath
    local swap_min_size_gb
    local swap_min_size_byte
    local swap_file_size_byte

    swap_filepath=$(swap::trait::swap::filepath) || return "${SHELL_FALSE}"
    swap_min_size_gb=$(swap::trait::swap::min_size_gb) || return "${SHELL_FALSE}"
    swap_min_size_byte=$(math::mul "${swap_min_size_gb}" 1024*1024*1024) || return "${SHELL_FALSE}"

    if swap::is_enabled; then
        linfo "swap is enabled"

        if swap::is_not_exists "${swap_filepath}"; then
            linfo "swap enabled, and swap file(${swap_filepath}) is not exists, swap not create by this script, do nothing."
            return "${SHELL_TRUE}"
        fi

        # 获取当前的 swap 文件大小
        # FIXME: swapon 查看的 swap 大小比交换文件偏小，暂时不知道为什么。所以这里对比交换文件的大小
        swap_file_size_byte="$(fs::file::size_byte "${swap_filepath}")" || return "${SHELL_FALSE}"
        if math::ge "${swap_file_size_byte}" "${swap_min_size_byte}"; then
            linfo "current swap file size_byte=${swap_file_size_byte} >= min_size_byte=${swap_min_size_byte}, do nothing."
            return "${SHELL_TRUE}"
        fi
        linfo "current swap file size_byte=${swap_file_size_byte} < min_size_byte=${swap_min_size_byte}, need to reset."
        # 当前的 swap 文件小于计算出来的最小的 swap 文件大小，那么需要进行重置
        swap::swapoff "${swap_filepath}" || return "${SHELL_FALSE}"
        # 不需要修改其他
    fi

    fs::file::delete --sudo "${swap_filepath}" || return "${SHELL_FALSE}"
    swap::make_swapfile "${swap_filepath}" "${swap_min_size_byte}" || return "${SHELL_FALSE}"
    swap::swapon "${swap_filepath}" || return "${SHELL_FALSE}"

    swap::trait::swap::undo_edit_fstab || return "${SHELL_FALSE}"
    swap::trait::swap::edit_fstab || return "${SHELL_FALSE}"
    systemctl::manager_state::reload || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function swap::trait::post_install() {
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function swap::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function swap::trait::uninstall() {
    # package_manager::uninstall "$(swap::trait::package_manager)" "$(swap::trait::package_name)" || return "${SHELL_FALSE}"
    local swap_filepath

    swap_filepath=$(swap::trait::swap::filepath) || return "${SHELL_FALSE}"

    if swap::is_not_exists "${swap_filepath}"; then
        linfo "swap file(${swap_filepath}) is not exists, do nothing."
        return "${SHELL_TRUE}"
    fi
    swap::swapoff "${swap_filepath}" || return "${SHELL_FALSE}"
    fs::file::delete --sudo "${swap_filepath}" || return "${SHELL_FALSE}"
    swap::trait::swap::undo_edit_fstab || return "${SHELL_FALSE}"
    systemctl::manager_state::reload || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function swap::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function swap::trait::upgrade() {
    # package_manager::upgrade "$(swap::trait::package_manager)" "$(swap::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function swap::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function swap::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function swap::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function swap::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function swap::trait::main() {
    return "${SHELL_TRUE}"
}

swap::trait::main
