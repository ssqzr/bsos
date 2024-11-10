#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_9763b925="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function pamac::trait::package_manager() {
    echo "yay"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function pamac::trait::package_name() {
    echo "pamac-aur"
}

# 简短的描述信息，查看包的信息的时候会显示
function pamac::trait::description() {
    echo "A Gtk frontend, Package Manager based on libalpm with AUR and Appstream support"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function pamac::trait::install_guide() {
    return "${SHELL_TRUE}"
}

function pamac::trait::_src_directory() {
    echo "$BUILD_TEMP_DIR/$(pamac::trait::package_name)"
}

function pamac::trait::pre_install() {
    cmd::run_cmd_retry_three cmd::run_cmd_with_history -- git clone --depth 1 https://aur.archlinux.org/pamac-aur.git "$(pamac::trait::_src_directory)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

function pamac::trait::install() {

    cmd::run_cmd_retry_three cmd::run_cmd_with_history -- cd "$(pamac::trait::_src_directory)" "&&" makepkg --syncdeps --install --noconfirm --needed
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "makepkg $(pamac::trait::package_name) failed."
        return "$SHELL_FALSE"
    fi
    return "${SHELL_TRUE}"
}

function pamac::trait::post_install() {
    local pamac_config_filepath="/etc/pamac.conf"

    # 一个命令执行完可以保证原子性
    # https://linux.cn/article-10232-1.html
    # 关于 sed 的 t 命令参考如下：
    # https://markrepo.github.io/commands/2018/06/26/sed/
    # shellcheck disable=SC2016
    # cmd::run_cmd_with_history -- sudo sed -i -e 's/^#RemoveUnrequiredDeps/RemoveUnrequiredDeps/' -e 's/^#EnableAUR/EnableAUR/' -e 's/^#CheckAURUpdates/CheckAURUpdates/' -e 's/^#CheckAURVCSUpdates/CheckAURVCSUpdates/' -e '/^CheckFlatpakUpdates$/d; $a CheckFlatpakUpdates' -e '/^#EnableSnap$/d; $a #EnableSnap' -e '/^EnableFlatpak$/d; $a EnableFlatpak' "${pamac_config_filepath}" || return "$SHELL_FALSE"
    if systemctl::is_exists "pamac-daemon.service"; then
        systemctl::stop "pamac-daemon.service" || return "${SHELL_FALSE}"
    fi

    cmd::run_cmd_with_history -- sudo cp -f "${SCRIPT_DIR_9763b925}/pamac.conf" "${pamac_config_filepath}"

    return "${SHELL_TRUE}"
}

function pamac::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

function pamac::trait::uninstall() {
    package_manager::uninstall "$(pamac::trait::package_manager)" "$(pamac::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function pamac::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function pamac::trait::upgrade() {
    package_manager::upgrade "$(pamac::trait::package_manager)" "$(pamac::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function pamac::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function pamac::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 如下的包才应该添加进来
# 1. 使用包管理器安装，它没有处理的依赖，并且有额外的配置或者其他设置。如果没有额外的配置，可以在 pamac::trait::pre_install 函数里直接安装就可以了。
# 2. 包管理器安装处理了依赖，但是这个依赖有额外的配置或者其他设置的
# NOTE: 这里填写的依赖是必须要安装的
function pamac::trait::dependencies() {
    local apps=("custom:libpamac" "pacman:polkit-kde-agent")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function pamac::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function pamac::trait::main() {
    return "$SHELL_TRUE"
}

pamac::trait::main
