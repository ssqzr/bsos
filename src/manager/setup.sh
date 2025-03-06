#!/bin/bash

# 全局可用的函数和变量

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_ec3f6be7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_ec3f6be7}/../lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_ec3f6be7}/global.sh"

# NOTE: 不要打印日志，因为一般调用这个函数在日志初始化前
function manager::setup::check_root_user() {
    if os::user::is_root; then
        # 此时还没初始化日志，所以不能使用日志接口
        println_error "this script cannot be run as root."
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# 不能通过命令替换的方式调用，不然输出并不会打印到终端，而是返回后才打印或者保存到变量中了
# 所以通过引用的方式返回密码
function manager::setup::input_root_password() {
    # 执行 su 需要输入密码

    local -n password_58016c37="$1"

    while true; do
        printf_blue "Please input your root password: "

        read -r -s -e password_58016c37

        if [ -z "$password_58016c37" ]; then
            lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "password is required to continue."
            continue
        fi

        if ! printf "%s" "$password_58016c37" | su - root -c /bin/true; then
            println_red "Invalid password, please try again."
            continue
        fi
        break
    done

    return "$SHELL_TRUE"
}

# 导出全局的变量
# NOTE: 通过环境变量是因为需要传递给子进程
function manager::setup::export_env() {
    local temp

    temp="$(dirname "${SCRIPT_DIR_ec3f6be7}")"
    export SRC_ROOT_DIR="${temp}"

    temp="$(global::temp_base_dir)"
    export BUILD_ROOT_DIR="$temp/build"

    # 处理 ROOT_PASSWORD
    manager::setup::input_root_password temp || return "$SHELL_FALSE"
    export ROOT_PASSWORD="${temp}"
}

function manager::setup::lock::filepath() {
    echo "$(global::temp_base_dir)/$(global::project_name).lock"
}

# 简单的单例，防止重复运行
# NOTE: 需要直接调用这个函数，不能通过命令替换等运行子程序的方式调用
function manager::setup::lock::lock() {
    local lock_file
    lock_file="$(manager::setup::lock::filepath)" || return "$SHELL_FALSE"
    lock::lock "$lock_file" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function manager::setup::lock::clean() {
    local lock_file
    lock_file="$(manager::setup::lock::filepath)" || return "$SHELL_FALSE"
    lock::clean "$lock_file" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 启用无需密码
# NOTE: 此时不一定有sudo，只能通过su root来执行
function manager::setup::enable_no_password() {
    local root_password="$1"
    shift

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "enable no password..."

    if string::is_empty "${root_password}"; then
        linfo "root password is empty, can not enable no password"
        return "$SHELL_FALSE"
    fi

    local username
    username=$(os::user::name)
    local filepath="/etc/sudoers.d/10-${username}"
    linfo "enable user(${username}) no password to run sudo"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'mkdir -p \""$(dirname "${filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) NOPASSWD:ALL\" \> "${filepath}"\' || return "${SHELL_FALSE}"
    linfo "enable user(${username}) no password to run sudo success"

    # 设置当前组内的用户执行pamac不需要输入密码
    local group_name
    group_name="$(os::user::group)"
    linfo "enable no password for group(${group_name}) to run pamac"
    local src_filepath="${SRC_ROOT_DIR}/assets/polkit/10-pamac.rules"
    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'mkdir -p \""$(dirname "${filepath}")"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'cp -f \""${src_filepath}"\" \""${filepath}"\"\' || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'sed -i \"s/usergroup/"${group_name}"/g\" \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "enable no password for group(${group_name}) to run pamac success"

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "enable no password success"

    return "$SHELL_TRUE"
}

# 禁用无需密码
# NOTE: 此时不一定有sudo，只能通过su root来执行
function manager::setup::disable_no_password() {
    local root_password="$1"
    shift

    local username
    local filepath

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "disable no password..."

    if string::is_empty "${root_password}"; then
        linfo "root password is empty, can not disable no password"
        return "$SHELL_FALSE"
    fi

    username=$(os::user::name)
    filepath="/etc/sudoers.d/10-${username}"
    linfo "disable no password for user(${username})"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'echo \""${username}" ALL=\(ALL\) ALL\" \> "${filepath}"\' || return "${SHELL_FALSE}"
    linfo "disable no password for user(${username}) success"

    filepath="/etc/polkit-1/rules.d/10-pamac.rules"
    linfo "disable no password for pamac, delete filepath=${filepath}"
    cmd::run_cmd_with_history --sensitive="${root_password}" -- printf "${root_password}" "|" su - root -c \'rm -f \""${filepath}"\"\' || return "${SHELL_FALSE}"
    linfo "disable no password for pamac success"

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "disable no password success"
    return "$SHELL_TRUE"
}

function manager::setup::_clear_child_process() {
    linfo "pkill child process..."
    pkill -P "$$"
    case "$?" in
    0)
        linfo "pkill child process success."
        ;;
    1)
        linfo "no child process to pkill."
        ;;
    *)
        lerror "pkill child process failed. exit code=$?"
        ;;
    esac
    return "$SHELL_TRUE"
}

# EXIT
# 正常退出还是异常退出都会调用
function manager::setup::signal::handler::EXIT() {
    local code="$?"
    linfo "EXIT signal handler start"

    linfo "script exit, pid=$$, exit code=${code}"

    if string::is_not_empty "${ROOT_PASSWORD}"; then
        manager::setup::disable_no_password "${ROOT_PASSWORD}" || return "$SHELL_FALSE"
    fi
    manager::setup::lock::clean || return "$SHELL_FALSE"

    linfo "EXIT signal handler success"
}

function manager::setup::signal::handler::INT() {
    linfo "INT signal handler start"

    manager::setup::_clear_child_process || return "$SHELL_FALSE"

    linfo "INT signal handler success"

    return "$SHELL_TRUE"
}

function manager::setup::signal::handler::QUIT() {
    linfo "QUIT signal handler start"

    manager::setup::_clear_child_process || return "$SHELL_FALSE"

    linfo "QUIT signal handler success"

    return "$SHELL_TRUE"
}

function manager::setup::signal::handler::TERM() {
    linfo "TERM signal handler start"

    manager::setup::_clear_child_process || return "$SHELL_FALSE"

    linfo "TERM signal handler success"

    return "$SHELL_TRUE"
}

function manager::setup::signal::register() {
    trap manager::setup::signal::handler::EXIT EXIT
    trap manager::setup::signal::handler::INT INT
    trap manager::setup::signal::handler::QUIT QUIT
    trap manager::setup::signal::handler::TERM TERM
}
