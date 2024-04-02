#!/bin/bash

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function git::trait::_env() {

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
function git::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function git::trait::package_name() {
    echo "git"
}

# 简短的描述信息，查看包的信息的时候会显示
function git::trait::description() {
    package_manager::package_description "$(git::trait::package_manager)" "$(git::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function git::trait::install_guide() {
    local username
    username=$(users)
    username=$(tui::input_required "used to git config --global user.name" "config git username: " "${username}") || return "$SHELL_FALSE"

    local email
    email=$(tui::input_required "used to git config --global user.email" "config git email: " "${email}") || return "$SHELL_FALSE"

    local http_proxy
    http_proxy=$(tui::input_optional "used to git config --global http.proxy" "config git http_proxy: ")
    if [ -z "${http_proxy}" ]; then
        lwarn "git config http_proxy will not be set"
    fi

    local https_proxy
    https_proxy=$(tui::input_optional "used to git config --global https.proxy" "config git https_proxy: ")
    if [ -z "${https_proxy}" ]; then
        lwarn "git config https_proxy will not be set"
    fi

    # 写入配置文件
    config::app::map::set "$PM_APP_NAME" "username" "${username}"
    config::app::map::set "$PM_APP_NAME" "email" "${email}"
    config::app::map::set "$PM_APP_NAME" "http_proxy" "${http_proxy}"
    config::app::map::set "$PM_APP_NAME" "https_proxy" "${https_proxy}"
    return "$SHELL_TRUE"
}

function git::trait::pre_install() {
    return "${SHELL_TRUE}"
}

function git::trait::do_install() {
    package_manager::install "$(git::trait::package_manager)" "$(git::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

function git::trait::post_install() {
    local username
    local email
    local http_proxy
    local https_proxy
    username=$(config::app::map::get "$PM_APP_NAME" "username")
    email=$(config::app::map::get "$PM_APP_NAME" "email")
    http_proxy=$(config::app::map::get "$PM_APP_NAME" "http_proxy")
    https_proxy=$(config::app::map::get "$PM_APP_NAME" "https_proxy")

    # 可以重复设置，覆盖之前的设置，所以设置前不用检查
    if [ -z "${username}" ]; then
        lwarn "git username is empty, not auto set it"
    else
        cmd::run_cmd_with_history git config --global user.name "${username}"
    fi

    if [ -z "${email}" ]; then
        lwarn "git email is empty, not auto set it"
    else
        cmd::run_cmd_with_history git config --global user.email "${email}"
    fi

    if [ -z "${http_proxy}" ]; then
        lwarn "git http_proxy is empty, not auto set it"
    else
        cmd::run_cmd_with_history git config --global http.proxy "${http_proxy}"
    fi

    if [ -z "${https_proxy}" ]; then
        lwarn "git https_proxy is empty, not auto set it"
    else
        cmd::run_cmd_with_history git config --global https.proxy "${https_proxy}"
    fi
    return "${SHELL_TRUE}"
}

function git::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

function git::trait::do_uninstall() {
    package_manager::uninstall "$(git::trait::package_manager)" "$(git::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

function git::trait::post_uninstall() {
    cmd::run_cmd_with_history rm -f "$HOME/.gitconfig"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function git::trait::finally() {
    println_info "${PM_APP_NAME}: you should copy you RSA key to github or gitee account"

    return "${SHELL_TRUE}"
}

# 安装和运行的依赖，如下的包才应该添加进来
# 1. 使用包管理器安装，它没有处理的依赖，并且有额外的配置或者其他设置。如果没有额外的配置，可以在 git::trait::pre_install 函数里直接安装就可以了。
# 2. 包管理器安装处理了依赖，但是这个依赖有额外的配置或者其他设置的
# NOTE: 这里填写的依赖是必须要安装的
function git::trait::dependencies() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function git::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function git::trait::main() {
    git::trait::_env || return "$SHELL_FALSE"
}

git::trait::main
