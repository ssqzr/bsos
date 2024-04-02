#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_6fc7c409="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"

function libpamac::trait::_env() {

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
function libpamac::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function libpamac::trait::package_name() {
    echo "libpamac-aur"
}

# 简短的描述信息，查看包的信息的时候会显示
function libpamac::trait::description() {
    echo "Pamac package manager library based on libalpm"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function libpamac::trait::install_guide() {
    return "${SHELL_TRUE}"
}

function libpamac::trait::_src_directory() {
    echo "$BUILD_TEMP_DIR/$(libpamac::trait::package_name)"
}

# 安装的前置操作，比如下载源代码
function libpamac::trait::pre_install() {
    cmd::run_cmd_with_history git clone --depth 1 https://aur.archlinux.org/libpamac-aur.git "$(libpamac::trait::_src_directory)" || return "$SHELL_FALSE"

    return "${SHELL_TRUE}"
}

# 安装的操作
function libpamac::trait::do_install() {

    local pkgbuild_filepath
    pkgbuild_filepath="$(libpamac::trait::_src_directory)/PKGBUILD"
    cmd::run_cmd_with_history sed -i "'s/ENABLE_FLATPAK=0/ENABLE_FLATPAK=1/'" "$pkgbuild_filepath" || return "$SHELL_FALSE"

    cmd::run_cmd_with_history cd "$(libpamac::trait::_src_directory)" "&&" makepkg --syncdeps --install --noconfirm --needed
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "makepkg $(libpamac::trait::package_name) failed."
        return "$SHELL_FALSE"
    fi

    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function libpamac::trait::post_install() {
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function libpamac::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function libpamac::trait::do_uninstall() {
    package_manager::uninstall "$(libpamac::trait::package_manager)" "$(libpamac::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function libpamac::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function libpamac::trait::finally() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖，如下的包才应该添加进来
# 1. 使用包管理器安装，它没有处理的依赖，并且有额外的配置或者其他设置。如果没有额外的配置，可以在 libpamac::trait::pre_install 函数里直接安装就可以了。
# 2. 包管理器安装处理了依赖，但是这个依赖有额外的配置或者其他设置的
# NOTE: 这里填写的依赖是必须要安装的
function libpamac::trait::dependencies() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function libpamac::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function libpamac::trait::main() {
    libpamac::trait::_env || return "$SHELL_FALSE"
}

libpamac::trait::main
