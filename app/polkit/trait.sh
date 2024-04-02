#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_e208daf3="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"

function polkit::trait::_env() {

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
function polkit::trait::package_manager() {
    # 这个被包管理器依赖，只能使用原始的pacman安装
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function polkit::trait::package_name() {
    echo "polkit-kde-agent"
}

# 简短的描述信息，查看包的信息的时候会显示
function polkit::trait::description() {
    package_manager::package_description "$(polkit::trait::package_manager)" "$(polkit::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function polkit::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function polkit::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function polkit::trait::do_install() {
    package_manager::install "$(polkit::trait::package_manager)" "$(polkit::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function polkit::trait::post_install() {
    # 设置当前组内的用户执行pamac不需要输入密码
    local rule_filename="10-pamac.rules"
    local dst_filepath="/etc/polkit-1/rules.d/${rule_filename}"
    cmd::run_cmd_with_history sudo cp "${SCRIPT_DIR_e208daf3}/${rule_filename}" "${dst_filepath}" || return "${SHELL_FALSE}"

    local group_name
    group_name="$(id -ng)"
    cmd::run_cmd_with_history sudo sed -i "'s/usergroup/${group_name}/g'" "${dst_filepath}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function polkit::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function polkit::trait::do_uninstall() {
    package_manager::uninstall "$(polkit::trait::package_manager)" "$(polkit::trait::package_name)"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function polkit::trait::post_uninstall() {
    local rule_filename="10-pamac.rules"
    local dst_filepath="/etc/polkit-1/rules.d/${rule_filename}"
    cmd::run_cmd_with_history rm -f "${dst_filepath}"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function polkit::trait::finally() {
    cmd::run_cmd_with_history sudo rm -f "/etc/polkit-1/rules.d/10-pamac.rules"
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖，如下的包才应该添加进来
# 1. 使用包管理器安装，它没有处理的依赖，并且有额外的配置或者其他设置。如果没有额外的配置，可以在 polkit::trait::pre_install 函数里直接安装就可以了。
# 2. 包管理器安装处理了依赖，但是这个依赖有额外的配置或者其他设置的
# NOTE: 这里填写的依赖是必须要安装的
function polkit::trait::dependencies() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function polkit::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function polkit::trait::main() {
    polkit::trait::_env || return "$SHELL_FALSE"
}

polkit::trait::main
