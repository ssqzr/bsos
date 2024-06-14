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

    linfo "run app custom manager: ${custom_manager_path} ${app_name} ${sub_command}"
    "$custom_manager_path" "${app_name}" "${sub_command}" || return "$SHELL_FALSE"
    linfo "run app custom manager success: ${custom_manager_path} ${app_name} ${sub_command}"
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

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_recursion() {
    local -n cache_apps_9efd3e61="$1"
    local command="$2"
    local pm_app="$3"
    local level_indent="$4"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local item
    local dependencies
    local features
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip run ${command}"
        return "$SHELL_TRUE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run ${command}..."

    # 获取它的依赖
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: dependencies run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_command_recursion "${!cache_apps_9efd3e61}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    if array::is_contain "${!cache_apps_9efd3e61}" "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: has run command(${command}), skip it"
    else
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: self run ${command}..."
        manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"
        cache_apps_9efd3e61+=("${pm_app}")
    fi

    # 获取它的feature
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: features run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_command_recursion "${!cache_apps_9efd3e61}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run ${command} done"

    return "${SHELL_TRUE}"
}

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_recursion_reverse() {
    local -n cache_apps_565a8946="$1"
    local command="$2"
    local pm_app="$3"
    local level_indent="$4"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local item
    local dependencies
    local features
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, skip run ${command}"
        return "$SHELL_TRUE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run ${command}..."

    # 获取它的feature
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: features run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_command_recursion_reverse "${!cache_apps_565a8946}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    if array::is_contain "${!cache_apps_565a8946}" "${pm_app}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: has run command(${command}), skip it"
    else
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: self run ${command}..."
        manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"
        cache_apps_565a8946+=("${pm_app}")
    fi

    # 获取它的依赖
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: dependencies run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_command_recursion_reverse "${!cache_apps_565a8946}" "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run ${command} done"

    return "${SHELL_TRUE}"
}

# 运行安装向导
function manager::app::do_install_guide() {
    local -n cache_apps_91f1e7eb="$1"
    local pm_app="$2"
    manager::app::do_command_recursion "${!cache_apps_91f1e7eb}" "install_guide" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 使用包管理器直接安装
function manager::app::do_install_use_pm() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if manager::app::is_custom "${pm_app}"; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is custom, can not use package manager direct install"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    package=$(manager::app::parse_app_name "$pm_app")

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: direct installing app with ${package_manager}"

    package_manager::install "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: direct install app with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: direct install app with ${package_manager} success"

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
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, can not use custom to install"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 安装所有 dependencies
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install all dependencies..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_install "${!install_apps_ae2e39de}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install all dependencies success"

    # 安装前置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run pre_install..."
    manager::app::run_custom_manager "${pm_app}" "pre_install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: pre_install failed."
        return "$SHELL_FALSE"
    fi
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run pre_install success."

    # 安装流程
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run do_install..."
    manager::app::run_custom_manager "${pm_app}" "do_install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: do_install failed"
        return "$SHELL_FALSE"
    fi
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run do_install success."

    # 安装所有 features
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install all features..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")

    for item in "${features[@]}"; do
        manager::app::do_install "${!install_apps_ae2e39de}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: all features install success."

    # 安装后置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run post_install..."
    manager::app::run_custom_manager "${pm_app}" "post_install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: post_install failed"
        return "$SHELL_FALSE"
    fi
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run post_install success."
    return "$SHELL_TRUE"
}

# 安装一个APP，附带其他的操作
function manager::app::do_install() {
    local -n install_apps_abdee2e4="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install..."

    if array::is_contain "${!install_apps_abdee2e4}" "${pm_app}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: installed. dont need install again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::do_install_use_pm "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    else
        manager::app::do_install_use_custom "${!install_apps_abdee2e4}" "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    install_apps_abdee2e4+=("${pm_app}")

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: install success."
    return "${SHELL_TRUE}"
}

# 运行 fixme
function manager::app::do_fixme() {
    local -n cache_apps_3e3889c9="$1"
    local pm_app="$2"
    manager::app::do_command_recursion "${!cache_apps_3e3889c9}" "fixme" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::app::do_unfixme() {
    local -n cache_apps_9f5466d3="$1"
    local pm_app="$2"
    manager::app::do_command_recursion_reverse "${!cache_apps_9f5466d3}" "unfixme" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 使用包管理器直接安装
function manager::app::_do_uninstall_use_pm() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if manager::app::is_custom "${pm_app}"; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is custom, can not use package manager direct uninstall"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    package=$(manager::app::parse_app_name "$pm_app")

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: direct uninstalling app with ${package_manager}"

    package_manager::uninstall "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: direct uninstall app with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: direct uninstall app with ${package_manager} success"

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
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: is not custom, can not use custom to uninstall"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 先运行卸载前置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run pre_uninstall..."
    manager::app::run_custom_manager "${pm_app}" "pre_uninstall"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run pre_uninstall failed"
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run pre_uninstall success"

    # 卸载所有 features
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstall all features..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_uninstall "${!uninstalled_apps_a7a18468}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstall all features success"

    # 卸载自己
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run do_uninstall..."
    manager::app::run_custom_manager "${pm_app}" "do_uninstall"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run do_uninstall failed"
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run do_uninstall success"

    # 运行卸载后置操作
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run post_uninstall..."
    manager::app::run_custom_manager "${pm_app}" "post_uninstall"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run post_uninstall failed"
        return "$SHELL_FALSE"
    fi
    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: run post_uninstall success"

    # 卸载所有 dependencies
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstall dependencies..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_uninstall "${!uninstalled_apps_a7a18468}" "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstall all dependencies success"

    return "$SHELL_TRUE"
}

function manager::app::do_uninstall() {
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
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent}${pm_app}: uninstalled. dont need uninstall again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::_do_uninstall_use_pm "$pm_app" "$level_indent" || return "$SHELL_FALSE"
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
