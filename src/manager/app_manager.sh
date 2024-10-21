#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_612d794c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/../lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/../lib/utils/utest.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/base.sh"

function manager::app::is_package_name_valid() {
    local package_name="$1"
    # https://www.gnu.org/software/bash/manual/html_node/Conditional-Constructs.html#index-_005b_005b
    # https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html
    if [[ ! "$package_name" =~ ^[^:[:space:]]+:[^:[:space:]]+$ ]]; then
        lerror "package_name($package_name) is invalid, it should be 'package_manager:app_name'"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function manager::app::parse_package_manager() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"
    local package_manager=${pm_app%:*}
    echo "$package_manager"
}

function manager::app::parse_app_name() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"
    local app_name=${pm_app#*:}
    echo "$app_name"
}

function manager::app::is_custom() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    local package_manager
    package_manager=$(manager::app::parse_package_manager "$pm_app")
    if [ "$package_manager" == "custom" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function manager::app::app_directory() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    if ! manager::app::is_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(manager::app::parse_app_name "$pm_app")
    echo "${SRC_ROOT_DIR}/app/${app_name}"
}

function manager::app::run_custom_manager() {
    local pm_app="$1"
    local sub_command="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty, params=$*"
        return "$SHELL_FALSE"
    fi

    if [ -z "$sub_command" ]; then
        lerror "sub_command is empty"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(manager::app::parse_app_name "$pm_app")

    if ! manager::app::is_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom, sub_command=${sub_command}"
        return "$SHELL_FALSE"
    fi

    local custom_manager_path="${SCRIPT_DIR_612d794c}/custom_manager.sh"

    if [ ! -e "${custom_manager_path}" ]; then
        lerror "app install manager is not exists, custom_manager_path=${custom_manager_path}"
        return "${SHELL_FALSE}"
    fi

    linfo "do app custom manager: ${custom_manager_path} ${app_name} ${sub_command}"
    "$custom_manager_path" "${app_name}" "${sub_command}" || return "$SHELL_FALSE"
    linfo "do app custom manager success: ${custom_manager_path} ${app_name} ${sub_command}"
    return "$SHELL_TRUE"
}

# 应该是检查顶层的app没有循环依赖就可以了，但是需要先找到顶层的app。也很麻烦，所以采用缓存的方式。
# app1依赖app2，app2没有循环依赖，那么app1也没有循环依赖
# app1依赖app2，app2有循环依赖，那么app1也有循环依赖
# app1依赖app2，app2依赖app3，app3没有循环依赖，那么app2也没有循环依赖，那么app1也没有循环依赖
# app1依赖app2，app2依赖app3，app3有循环依赖，那么app2也有循环依赖，那么app1也有循环依赖
function manager::app::is_no_loop_relationships() {
    local -n cache_apps_2fcf6903="$1"
    # relation_type 取值：dependencies 或者 features
    local relation_type="$2"
    local pm_app="$3"
    local link_path="$4"

    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    local temp_array=()
    local item
    local temp_str

    if ! manager::app::is_custom "$pm_app"; then
        # 如果不是自定义的包，那么不需要检查循环依赖
        return "$SHELL_TRUE"
    fi

    if array::is_contain "${!cache_apps_2fcf6903}" "$pm_app"; then
        # 如果已经在缓存中，那么不需要检查循环依赖
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "app($pm_app) has checked no loop ${relation_type}. skip it."
        return "$SHELL_TRUE"
    fi

    echo "$link_path" | grep -wq "$pm_app"
    if [ $? -eq "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "app($pm_app) has loop ${relation_type}. ${relation_type} link path: ${link_path} $pm_app"
        return "$SHELL_FALSE"
    fi

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "${relation_type}")" || return "$SHELL_FALSE"
    array::readarray temp_array < <(echo "$temp_str")
    for item in "${temp_array[@]}"; do
        manager::app::is_no_loop_relationships "${!cache_apps_2fcf6903}" "${relation_type}" "${item}" "$link_path $pm_app" || return "$SHELL_FALSE"
    done

    cache_apps_2fcf6903+=("${pm_app}")
    return "$SHELL_TRUE"
}

# 检查循环依赖
function manager::app::check_loop_relationships() {

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "start check all app loop relationships, it may take a long time..."

    local _d4dd25bd_dependencies_cache_apps=()
    local _83bf212f_features_cache_apps=()

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        manager::app::is_no_loop_relationships _d4dd25bd_dependencies_cache_apps "dependencies" "${pm_app}" || return "$SHELL_FALSE"
        manager::app::is_no_loop_relationships _83bf212f_features_cache_apps "features" "${pm_app}" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "check all app loop relationships success"
    return "$SHELL_TRUE"
}

# 使用包管理器直接执行命令
function manager::app::do_command_use_pm() {
    local command="$1"
    shift
    local pm_app="$1"
    shift
    local level_indent="$1"
    shift

    if [ -z "$command" ]; then
        lerror "command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if manager::app::is_custom "${pm_app}"; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is custom, can not do command($command) by package manager"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    package=$(manager::app::parse_app_name "$pm_app")

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use ${package_manager} do command(${command})"

    "package_manager::${command}" "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use ${package_manager} do command(${command}) failed"
        return "$SHELL_FALSE"
    fi

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use ${package_manager} do command(${command}) success"

    return "$SHELL_TRUE"
}

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_use_custom() {
    local -n cache_apps_ef62dd2b="$1"
    shift
    local command="$1"
    shift
    local pm_app="$1"
    shift
    local level_indent="$1"
    shift

    if [ -z "$command" ]; then
        lerror "command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local item
    local dependencies
    local features
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip use custom manager do command(${command})"
        return "$SHELL_TRUE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager start do command(${command}) flow..."

    # 获取它的依赖
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start dependencies do command(${command})..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_command "${!cache_apps_ef62dd2b}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    if array::is_contain "${!cache_apps_ef62dd2b}" "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager self has been done command(${command}), not do again."
    else
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager self do command(${command})..."
        manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"
    fi

    # 获取它的feature
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start features do command(${command})..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_command "${!cache_apps_ef62dd2b}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do command(${command}) end."

    return "${SHELL_TRUE}"
}

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_use_custom_reverse() {
    local -n cache_apps_ef62dd2b="$1"
    shift
    local command="$1"
    shift
    local pm_app="$1"
    shift
    local level_indent="$1"
    shift

    if [ -z "$command" ]; then
        lerror "command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local item
    local dependencies
    local features
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip use custom manager do command(${command})"
        return "$SHELL_TRUE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager start do command(${command}) flow..."

    # 获取它的feature
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start features do command(${command})..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_command_reverse "${!cache_apps_ef62dd2b}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    if array::is_contain "${!cache_apps_ef62dd2b}" "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager self has been done command(${command}), not do again."
    else
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager self do command(${command})..."
        manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"
    fi

    # 获取它的依赖
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start dependencies do command(${command})..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_command_reverse "${!cache_apps_ef62dd2b}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do command(${command}) done"

    return "${SHELL_TRUE}"
}

# 安装一个APP，附带其他的操作
# NOTE: manager::app::do_command_use_pm 和 manager::app::do_command_use_custom 的 command 参数可接受的值是不一样的
function manager::app::do_command() {
    local -n apps_0c1cd5f7="$1"
    shift
    local command="$1"
    shift
    local pm_app="$1"
    shift
    local level_indent="$1"
    shift

    if [ -z "$command" ]; then
        lerror "param command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start do command(${command})..."

    if array::is_contain "${!apps_0c1cd5f7}" "${pm_app}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: has been done command(${command}). not do again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::do_command_use_pm "${command}" "$pm_app" "${level_indent}" || return "$SHELL_FALSE"
    else
        manager::app::do_command_use_custom "${!apps_0c1cd5f7}" "${command}" "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    # 所有操作都执行完毕，添加到缓存
    apps_0c1cd5f7+=("${pm_app}")

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: do command(${command}) success."
    return "${SHELL_TRUE}"
}

# 安装一个APP，附带其他的操作
function manager::app::do_command_reverse() {
    local -n apps_bab15ea2="$1"
    shift
    local command="$1"
    shift
    local pm_app="$1"
    shift
    local level_indent="$1"
    shift

    if [ -z "$command" ]; then
        lerror "param command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: do command(${command})..."

    if array::is_contain "${!apps_bab15ea2}" "${pm_app}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: has been done command(${command}). not do again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::do_command_use_pm "${command}" "$pm_app" "${level_indent}" || return "$SHELL_FALSE"
    else
        manager::app::do_command_use_custom_reverse "${!apps_bab15ea2}" "${command}" "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    # 所有操作都执行完毕，添加到缓存
    apps_bab15ea2+=("${pm_app}")

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: do command(${command}) success."
    return "${SHELL_TRUE}"
}

# 运行安装向导
function manager::app::install_guide() {
    local -n cache_apps_91f1e7eb="$1"
    local pm_app="$2"

    local command="install_guide"

    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip do command(${command})"
        return "$SHELL_TRUE"
    fi

    manager::app::do_command "${!cache_apps_91f1e7eb}" "${command}" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::app::do_install_use_custom() {
    local -n install_apps_ae2e39de="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local dependencies
    local features
    local item
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, can not use custom manager to install"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 安装所有 dependencies
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start dependencies install..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::install "${!install_apps_ae2e39de}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: all dependencies install success"

    # 安装前置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self pre_install..."
    manager::app::run_custom_manager "${pm_app}" "pre_install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self pre_install failed."
        return "$SHELL_FALSE"
    fi
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self pre_install success."

    # 安装流程
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self install..."
    manager::app::run_custom_manager "${pm_app}" "install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self install failed"
        return "$SHELL_FALSE"
    fi
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self install success."

    # 安装所有 features
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start features install..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")

    for item in "${features[@]}"; do
        manager::app::install "${!install_apps_ae2e39de}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: all features install success."

    # 安装后置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self post_install..."
    manager::app::run_custom_manager "${pm_app}" "post_install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self post_install failed"
        return "$SHELL_FALSE"
    fi
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self post_install success."
    return "$SHELL_TRUE"
}

# 安装一个APP，附带其他的操作
function manager::app::install() {
    local -n install_apps_abdee2e4="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install..."

    if array::is_contain "${!install_apps_abdee2e4}" "${pm_app}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: installed. dont install again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::do_command_use_pm "install" "$pm_app" "${level_indent}" || return "$SHELL_FALSE"
    else
        manager::app::do_install_use_custom "${!install_apps_abdee2e4}" "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    install_apps_abdee2e4+=("${pm_app}")

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install success."
    return "${SHELL_TRUE}"
}

# 更新一个APP，附带其他的操作
function manager::app::upgrade() {
    local -n apps_215a25dc="$1"
    local pm_app="$2"
    local level_indent="$3"

    local command="upgrade"

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    manager::app::do_command "${!apps_215a25dc}" "${command}" "${pm_app}" "${level_indent}" || return "$SHELL_FALSE"

    return "${SHELL_TRUE}"
}

# 运行 fixme
function manager::app::fixme() {
    local -n cache_apps_3e3889c9="$1"
    local pm_app="$2"

    local command="fixme"

    # NOTE: manager::app::do_command_use_pm 的 command 参数没有 fixme 的值
    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip do command(${command})"
        return "$SHELL_TRUE"
    fi

    manager::app::do_command "${!cache_apps_3e3889c9}" "${command}" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::app::unfixme() {
    local -n cache_apps_9f5466d3="$1"
    local pm_app="$2"

    local command="unfixme"

    # NOTE: manager::app::do_command_use_pm 的 command 参数没有 unfixme 的值
    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip do command(${command})"
        return "$SHELL_TRUE"
    fi

    manager::app::do_command_reverse "${!cache_apps_9f5466d3}" "${command}" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::app::_do_uninstall_use_custom() {
    local -n uninstalled_apps_a7a18468="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local dependencies
    local features
    local item
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, can not use custom manager to uninstall"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 先运行卸载前置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self pre_uninstall..."
    manager::app::run_custom_manager "${pm_app}" "pre_uninstall"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self pre_uninstall failed"
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self pre_uninstall success"

    # 卸载所有 features
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: start all features uninstall..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::uninstall "${!uninstalled_apps_a7a18468}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: all features uninstall success"

    # 卸载自己
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self uninstall..."
    manager::app::run_custom_manager "${pm_app}" "uninstall"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self uninstall failed"
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self uninstall success"

    # 运行卸载后置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self post_uninstall..."
    manager::app::run_custom_manager "${pm_app}" "post_uninstall"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self post_uninstall failed"
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: use custom manager do self post_uninstall success"

    # 卸载所有 dependencies
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: all dependencies uninstall..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::uninstall "${!uninstalled_apps_a7a18468}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: all dependencies uninstall success"

    return "$SHELL_TRUE"
}

function manager::app::uninstall() {
    local -n uninstalled_apps_03c55110="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if base::core_apps::is_contain "$pm_app"; then
        ldebug "app(${pm_app}) is core app, can not uninstall"
        return "$SHELL_TRUE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstalling..."

    if array::is_contain "${!uninstalled_apps_03c55110}" "${pm_app}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstalled. dont uninstall again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::do_command_use_pm "uninstall" "$pm_app" "${level_indent}" || return "$SHELL_FALSE"
    else
        manager::app::_do_uninstall_use_custom "${!uninstalled_apps_03c55110}" "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    uninstalled_apps_03c55110+=("${pm_app}")

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstall success."
    return "$SHELL_TRUE"
}

########################### 下面是测试代码 ###########################
function TEST::manager::app::is_package_name_valid() {
    manager::app::is_package_name_valid "pamac:app_name"
    utest::assert $?

    manager::app::is_package_name_valid ""
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac app_name"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid ":"
    utest::assert_fail $?

    manager::app::is_package_name_valid "::"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac:"
    utest::assert_fail $?

    manager::app::is_package_name_valid ":pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac::pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid " :pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac: "
    utest::assert_fail $?

    manager::app::is_package_name_valid " pamac:pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac :pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac: pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac:pamac "
    utest::assert_fail $?

    manager::app::is_package_name_valid " pamac : pamac "
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac：pamac"
    utest::assert_fail $?
}

function manager::app::_main() {

    return "$SHELL_TRUE"
}

manager::app::_main
