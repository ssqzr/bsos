#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b5b83ba6="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_b5b83ba6}/../lib/utils/all.sh"

# NOTE: 在处理所有安装流程前需要安装的app，是单独的安装流程。一般是本脚本功能需要的app
# NOTE: 这些模块安装不会处理依赖，只安装自己，所以最好不要有什么依赖
# custom:systemd_resolved 是为了解决网络问题
# custom:pacman 配置 pacman 镜像
# sudo 是为了用户安全
# go-yq 是配置管理需要的，安装脚本也需要读写配置
# gum 是安装脚本为了更好的终端交互需要安装的，运行安装向导等交互场景需要用到
# fzf 是安装脚本为了更好的终端交互需要安装的，当选项比较多时搜索比较方便
__CORE_APPS=("custom:systemd_resolved" "custom:pacman" "custom:sudo" "pacman:go-yq" "pacman:gum" "pacman:fzf")

# 优先安装的应用
# system_setting 系统设置
# base-devel 是为了基本的编译需要的
# git 是为了安装pamac需要的，后面 git 还会以custom的方式再安装一遍，因为有一些配置需要配置
# yay 为了安装其他应用
# pamac 为了安装其他应用
# rust 我需要rustup包，但是一些APP依赖rust时默认安装的是rust包，导致再次安装rustup会冲突
__PRIOR_INSTALL_APPS=("custom:system_setting" "pacman:base-devel" "pacman:git" "custom:yay" "custom:pamac" "custom:rust")

function base::core_apps::list() {
    array::print __CORE_APPS
}

function base::core_apps::is_contain() {
    local pm_app="$1"
    array::is_contain __CORE_APPS "$pm_app"
}

function base::prior_install_apps::list() {

    array::print __PRIOR_INSTALL_APPS
}

function base::prior_install_apps::is_contain() {
    local pm_app="$1"
    array::is_contain __PRIOR_INSTALL_APPS "$pm_app"
}

# NOTE: 不要打印日志，因为一般调用这个函数在日志初始化前
function base::check_root_user() {
    if os::user::is_root; then
        # 此时还没初始化日志，所以不能使用日志接口
        println_error "this script cannot be run as root."
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# 简单的单例，防止重复运行
function base::lock() {
    local lock_file="/tmp/bsos.lock"
    exec 99>"$lock_file"
    flock -n 99
    if [ $? -ne "$SHELL_TRUE" ]; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "already running, exit."
        return "${SHELL_FALSE}"
    fi
    echo "$$" >&99
    # shellcheck disable=SC2064
    trap "rm -f ${lock_file}" INT TERM EXIT

    return "$SHELL_TRUE"
}

function base::input_root_password() {
    # 执行 su 需要输入密码
    local password
    while true; do
        printf_blue "Please input your root password: "
        read -r -s -e password
        if [ -z "$password" ]; then
            lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "password is required to continue."
            continue
        fi
        break
    done
    export ROOT_PASSWORD="${password}"
}

# 导出全局的变量
function base::export_env() {
    local src_dir

    # 最长的是 success 字符串，长度为 7
    export LOG_HANDLER_STREAM_FORMATTER="{{datetime}} [{{level|to_upper|justify 7 center}}] {{message}}"

    src_dir="$(dirname "${SCRIPT_DIR_b5b83ba6}")"
    export SRC_ROOT_DIR="${src_dir}"
    export BUILD_ROOT_DIR="/var/tmp/bsos/build"

    # 处理 ROOT_PASSWORD
    base::input_root_password
}

# 启用无需密码
function base::enable_no_password() {
    # NOTE: 此时不一定有sudo，只能通过su root来执行
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "enable no password..."

    local username
    username=$(os::user::name)
    local filepath="/etc/sudoers.d/10-${username}"
    linfo "enable user(${username}) no password to run sudo"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'mkdir -p \""$(dirname "${filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) NOPASSWD:ALL\" \> "${filepath}"\' || return "${SHELL_FALSE}"
    linfo "enable user(${username}) no password to run sudo success"

    # 设置当前组内的用户执行pamac不需要输入密码
    local group_name
    group_name="$(os::user::group)"
    linfo "enable no password for group(${group_name}) to run pamac"
    local src_filepath="${SRC_ROOT_DIR}/assets/polkit/10-pamac.rules"
    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'mkdir -p \""$(dirname "${filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'cp -f \""${src_filepath}"\" \""${filepath}"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'sed -i \"s/usergroup/"${group_name}"/g\" \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "enable no password for group(${group_name}) to run pamac success"

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "enable no password success"

    return "$SHELL_TRUE"
}

# 禁用无需密码
function base::disable_no_password() {
    # NOTE: 此时不一定有sudo，只能通过su root来执行

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "disable no password..."

    local username
    username=$(os::user::name)
    local filepath="/etc/sudoers.d/10-${username}"
    linfo "disable no password for user(${username})"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) ALL\" \> "${filepath}"\' || return "${SHELL_FALSE}"
    linfo "disable no password for user(${username}) success"

    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    linfo "disable no password for pamac, delete filepath=${filepath}"
    cmd::run_cmd_with_history -- printf "${ROOT_PASSWORD}" "|" su - root -c \'rm -f \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "disable no password for pamac success"

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "disable no password success"
    return "$SHELL_TRUE"
}
