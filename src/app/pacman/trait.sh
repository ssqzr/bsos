#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_c93a9e29="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function pacman::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function pacman::trait::package_name() {
    echo "pacman"
}

# 简短的描述信息，查看包的信息的时候会显示
function pacman::trait::description() {
    package_manager::package_description "$(pacman::trait::package_manager)" "$(pacman::trait::package_name)" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function pacman::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function pacman::trait::pre_install() {
    # https://stackoverflow.com/questions/31869731/what-is-the-meaning-of-0-xxx-in-sed
    # https://stackoverflow.com/questions/30386483/command-to-insert-lines-before-first-match
    # 使用 @ 替换掉 / ，避免路径里的 / 需要被转移
    # 添加国内的源
    # Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
    grep "mirrors.tuna.tsinghua.edu.cn" "/etc/pacman.d/mirrorlist" >/dev/null
    if [ "$?" == "$SHELL_FALSE" ]; then
        cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c "\"sed -i '0,/^[# ]*Server/s@@Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\\\$repo/os/\\\$arch\n&@' /etc/pacman.d/mirrorlist\"" || return "${SHELL_FALSE}"
    fi

    # 更新软件数据库
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "start update pacman database..."
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \""pacman -Sy --noconfirm"\" || return "${SHELL_FALSE}"
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "update pacman database success."

    return "${SHELL_TRUE}"
}

# 安装的操作
function pacman::trait::do_install() {
    # 系统自带了，不用安装
    # package_manager::install "$(pacman::trait::package_manager)" "$(pacman::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function pacman::trait::post_install() {
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function pacman::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function pacman::trait::do_uninstall() {
    # 系统自带的，不卸载
    # package_manager::uninstall "$(pacman::trait::package_manager)" "$(pacman::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function pacman::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function pacman::trait::upgrade() {
    package_manager::upgrade "$(pacman::trait::package_manager)" "$(pacman::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function pacman::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function pacman::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function pacman::trait::dependencies() {
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
function pacman::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function pacman::trait::main() {
    return "${SHELL_TRUE}"
}

pacman::trait::main
