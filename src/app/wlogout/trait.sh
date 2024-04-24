#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_37160405="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function wlogout::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function wlogout::trait::package_name() {
    echo "wlogout"
}

# 简短的描述信息，查看包的信息的时候会显示
function wlogout::trait::description() {
    package_manager::package_description "$(wlogout::trait::package_manager)" "$(wlogout::trait::package_name)" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function wlogout::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function wlogout::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function wlogout::trait::do_install() {
    package_manager::install "$(wlogout::trait::package_manager)" "$(wlogout::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function wlogout::trait::post_install() {
    local conf_filepath="$XDG_CONFIG_HOME/wlogout"
    cmd::run_cmd_with_history mkdir -p "$XDG_CONFIG_HOME"
    cmd::run_cmd_with_history rm -rf "$conf_filepath"
    cmd::run_cmd_with_history cp -rf "$SCRIPT_DIR_37160405/wlogout" "$conf_filepath" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function wlogout::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function wlogout::trait::do_uninstall() {
    package_manager::uninstall "$(wlogout::trait::package_manager)" "$(wlogout::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function wlogout::trait::post_uninstall() {
    local conf_filepath="$XDG_CONFIG_HOME/wlogout"
    cmd::run_cmd_with_history rm -rf "$conf_filepath"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function wlogout::trait::fixme() {
    println_info "${PM_APP_NAME}: TODO: "

    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function wlogout::trait::unfixme() {
    println_info "${PM_APP_NAME}: start undo fixme..."

    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function wlogout::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # default:vim 使用默认的包管理器，默认的包管理器代码里定义
    # pacman:vim
    # yay:vim
    # pamac:vim
    # custom:vim   自定义，也就是通过本脚本进行安装
    local apps=()
    # 动态颜色主题
    apps+=("custom:pywal" "default:go-yq")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function wlogout::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function wlogout::trait::main() {
    return "${SHELL_TRUE}"
}

wlogout::trait::main
