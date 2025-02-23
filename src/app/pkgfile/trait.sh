#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_fba3043f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function pkgfile::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function pkgfile::trait::package_name() {
    echo "pkgfile"
}

# 简短的描述信息，查看包的信息的时候会显示
function pkgfile::trait::description() {
    package_manager::package_description "$(pkgfile::trait::package_manager)" "$(pkgfile::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function pkgfile::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function pkgfile::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function pkgfile::trait::do_install() {
    package_manager::install "$(pkgfile::trait::package_manager)" "$(pkgfile::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function pkgfile::trait::post_install() {
    local unit="pkgfile-update.timer"

    fish::config::add "350" "$SCRIPT_DIR_fba3043f/fish/pkgfile.fish" || return "$SHELL_FALSE"

    systemctl::enable "$unit" || return "$SHELL_FALSE"
    systemctl::restart "$unit" || return "$SHELL_FALSE"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function pkgfile::trait::pre_uninstall() {
    local unit="pkgfile-update.timer"
    if systemctl::is_exists "$unit"; then
        systemctl::stop "$unit" || return "$SHELL_FALSE"
        systemctl::disable "$unit" || return "$SHELL_FALSE"
    fi

    return "${SHELL_TRUE}"
}

# 卸载的操作
function pkgfile::trait::do_uninstall() {
    package_manager::uninstall "$(pkgfile::trait::package_manager)" "$(pkgfile::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function pkgfile::trait::post_uninstall() {
    fish::config::remove "350" "pkgfile.fish" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function pkgfile::trait::upgrade() {
    package_manager::upgrade "$(pkgfile::trait::package_manager)" "$(pkgfile::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function pkgfile::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function pkgfile::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function pkgfile::trait::dependencies() {
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
function pkgfile::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function pkgfile::trait::main() {
    return "$SHELL_TRUE"
}

pkgfile::trait::main
