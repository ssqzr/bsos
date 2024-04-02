#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_fba3043f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"

function pkgfile::trait::_env() {

    if [ -z "${SRC_ROOT_DIR}" ]; then
        println_error "env SRC_ROOT_DIR is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "${PM_APP_NAME}" ]; then
        println_error "env PM_APP_NAME is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "${BUILD_TEMP_DIR}" ]; then
        println_error "env BUILD_TEMP_DIR is not set"
        return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

# 指定使用的包管理器
function pamac::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function pkgfile::trait::package_name() {
    echo "pkgfile"
}

# 简短的描述信息，查看包的信息的时候会显示
function pkgfile::trait::description() {
    package_manager::package_description "$(pamac::trait::package_manager)" "$(pkgfile::trait::package_name)"
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
    package_manager::install "$(pamac::trait::package_manager)" "$(pkgfile::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function pkgfile::trait::post_install() {
    cmd::run_cmd_with_history sudo systemctl enable pkgfile-update.timer || return "$SHELL_FALSE"
    cmd::run_cmd_with_history sudo systemctl restart pkgfile-update.timer || return "$SHELL_FALSE"

    local zshrc_filepath="$HOME/.zshrc"
    local package_name
    package_name="$(pkgfile::trait::package_name)"
    grep "${package_name} begin" "$zshrc_filepath" >/dev/null 2>&1
    if [ $? -eq "$SHELL_TRUE" ]; then
        linfo "${PM_APP_NAME} has modify config."
        return "$SHELL_TRUE"
    fi

    printf "# %s begin\nsource /usr/share/doc/pkgfile/command-not-found.zsh\n# %s end" "${package_name}" "${package_name}" >>"$zshrc_filepath" || return "$SHELL_FALSE"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function pkgfile::trait::pre_uninstall() {
    cmd::run_cmd_with_history sudo systemctl stop pkgfile-update.timer
    cmd::run_cmd_with_history sudo systemctl disable pkgfile-update.timer

    return "${SHELL_TRUE}"
}

# 卸载的操作
function pkgfile::trait::do_uninstall() {
    package_manager::uninstall "$(pamac::trait::package_manager)" "$(pkgfile::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function pkgfile::trait::post_uninstall() {
    local package_name
    package_name="$(pkgfile::trait::package_name)"
    sed::delete_between_line "${package_name} begin" "${package_name} end" "$HOME/.zshrc" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function pkgfile::trait::finally() {
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
function pkgfile::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function pkgfile::trait::main() {
    pkgfile::trait::_env || return "$SHELL_FALSE"
}

pkgfile::trait::main
