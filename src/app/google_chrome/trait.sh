#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_8474d0ef="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"


# 指定使用的包管理器
function google_chrome::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function google_chrome::trait::package_name() {
    echo "google-chrome"
}

# 简短的描述信息，查看包的信息的时候会显示
function google_chrome::trait::description() {
    package_manager::package_description "$(google_chrome::trait::package_manager)" "$(google_chrome::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function google_chrome::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function google_chrome::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function google_chrome::trait::do_install() {
    package_manager::install "$(google_chrome::trait::package_manager)" "$(google_chrome::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function google_chrome::trait::post_install() {
    # 可以修改启动参数配置文件 ~/.config/chrome-flags.conf
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function google_chrome::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function google_chrome::trait::do_uninstall() {
    package_manager::uninstall "$(google_chrome::trait::package_manager)" "$(google_chrome::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function google_chrome::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function google_chrome::trait::finally() {
    println_info "${PM_APP_NAME}: you should login to chrome and sync data"
    println_info "${PM_APP_NAME}: you should change chrome default download path"
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function google_chrome::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # pacman:vim
    # yay:vim
    # pamac:vim
    # custom:vim   自定义，也就是通过本脚本进行安装
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function google_chrome::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function google_chrome::trait::main() {
    return "$SHELL_TRUE"
}

google_chrome::trait::main
