#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_6e66a585="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"

function gnome_keyring::trait::_env() {

    if [ -z "${HOME}" ]; then
        println_error "env HOME is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "${XDG_CONFIG_HOME}" ]; then
        println_error "env XDG_CONFIG_HOME is not set"
        return "$SHELL_FALSE"
    fi

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
function gnome_keyring::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function gnome_keyring::trait::package_name() {
    # https://rtfm.co.ua/en/what-is-linux-keyring-gnome-keyring-secret-service-and-d-bus/
    # https://wiki.archlinuxcn.org/wiki/GNOME/Keyring
    echo "gnome-keyring"
}

# 简短的描述信息，查看包的信息的时候会显示
function gnome_keyring::trait::description() {
    package_manager::package_description "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function gnome_keyring::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function gnome_keyring::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function gnome_keyring::trait::do_install() {
    package_manager::install "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function gnome_keyring::trait::post_install() {
    # https://wiki.archlinuxcn.org/wiki/GNOME/Keyring#%E7%94%A8PAM%E7%9A%84%E6%96%B9%E6%B3%95
    # https://stackoverflow.com/questions/37909388/append-line-after-last-match-with-sed
    # 本来想使用sed解决的，但是网上给的方案都没有说明，出现问题也不好排查
    # cmd::run_cmd_with_history sudo sed -i -e "'1h;1!H;$!d;x;s/.*auth [^\n]*/&\nauth optional pam_gnome_keyring.so/'" -e "'1h;1!H;$!d;x;s/.*session [^\n]*/&\nsession optional pam_gnome_keyring.so auto_start/'" /etc/pam.d/login || return "${SHELL_FALSE}"
    local tmp_pam_login_file="${BUILD_TEMP_DIR}/login.tmp"

    local line
    local found=""

    while read -r line; do
        # 空行和注释行直接处理
        if [ -z "${line}" ]; then
            echo "${line}" >>"${tmp_pam_login_file}"
            continue
        fi
        if [[ "${line}" == "#"* ]]; then
            echo "${line}" >>"${tmp_pam_login_file}"
            continue
        fi

        if [[ "${found}" == "auth"* ]] && [[ "${line}" != "auth"* ]]; then
            echo "auth optional pam_gnome_keyring.so" >>"${tmp_pam_login_file}"
        fi

        if [[ "${found}" == "session"* ]] && [[ "${line}" != "session"* ]]; then
            echo "session optional pam_gnome_keyring.so auto_start" >>"${tmp_pam_login_file}"
        fi

        found="${line}"
        echo "${line}" >>"${tmp_pam_login_file}"

    done </etc/pam.d/login

    cmd::run_cmd_with_history sudo cp -f "${tmp_pam_login_file}" /etc/pam.d/login || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function gnome_keyring::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function gnome_keyring::trait::do_uninstall() {
    package_manager::uninstall "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function gnome_keyring::trait::post_uninstall() {
    cmd::run_cmd_with_history sudo sed -i -e "'/pam_gnome_keyring.so/d'" /etc/pam.d/login || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function gnome_keyring::trait::finally() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function gnome_keyring::trait::dependencies() {
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
function gnome_keyring::trait::features() {
    local apps=("default:libsecret")
    array::print apps
    return "${SHELL_TRUE}"
}

function gnome_keyring::trait::main() {
    gnome_keyring::trait::_env || return "$SHELL_FALSE"
}

gnome_keyring::trait::main
