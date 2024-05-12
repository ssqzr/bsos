#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_ce74706e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function yazi::undo_set_xdg_mime() {
    if [ -f "${XDG_CONFIG_HOME}/mimeapps.list" ]; then
        cmd::run_cmd_with_history sed -i "'/yazi.desktop/d'" "${XDG_CONFIG_HOME}/mimeapps.list" || return "${SHELL_FALSE}"
    fi
    return "$SHELL_TRUE"
}

function yazi::set_xdg_mime() {
    yazi::undo_set_xdg_mime || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history xdg-mime default "yazi.desktop" "inode/directory" || return "${SHELL_FALSE}"
    return "$SHELL_TRUE"
}

# 指定使用的包管理器
function yazi::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function yazi::trait::package_name() {
    echo "yazi"
}

# 简短的描述信息，查看包的信息的时候会显示
function yazi::trait::description() {
    package_manager::package_description "$(yazi::trait::package_manager)" "$(yazi::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function yazi::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function yazi::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function yazi::trait::do_install() {
    package_manager::install "$(yazi::trait::package_manager)" "$(yazi::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function yazi::trait::post_install() {

    cmd::run_cmd_with_history rm -rf "${XDG_CONFIG_HOME}/yazi" || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history cp -rf "${SCRIPT_DIR_ce74706e}/yazi" "${XDG_CONFIG_HOME}/" || return "${SHELL_FALSE}"
    # https://wiki.archlinux.org/title/default_applications
    yazi::set_xdg_mime || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history mkdir -p "${XDG_CONFIG_HOME}/yazi/plugins" || return "${SHELL_FALSE}"
    # 需要安装 ouch
    cmd::run_cmd_retry_three cmd::run_cmd_with_history git clone https://github.com/ndtoan96/ouch.yazi.git "${XDG_CONFIG_HOME}/yazi/plugins/ouch.yazi" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function yazi::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function yazi::trait::do_uninstall() {
    package_manager::uninstall "$(yazi::trait::package_manager)" "$(yazi::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function yazi::trait::post_uninstall() {
    cmd::run_cmd_with_history rm -rf "${XDG_CONFIG_HOME}/yazi" || return "${SHELL_FALSE}"
    yazi::undo_set_xdg_mime || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function yazi::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function yazi::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function yazi::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # pacman:vim
    # yay:vim
    # pamac:vim
    # custom:vim   自定义，也就是通过本脚本进行安装
    local apps=("custom:xdg" "default:ouch" "default:poppler" "default:fd" "custom:fzf" "default:wl-clipboard" "default:zoxide" "default:jq" "custom:fonts" "default:ffmpegthumbnailer" "default:ripgrep")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function yazi::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function yazi::trait::main() {
    return "$SHELL_TRUE"
}

yazi::trait::main
