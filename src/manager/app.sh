#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_612d794c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/../lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/../lib/utils/utest.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/base.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/utils.sh"

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
    package_manager=$(manager::app::parse_package_manager "$pm_app") || return "$SHELL_FALSE"
    if [ "$package_manager" == "custom" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function manager::app::is_not_custom() {
    ! manager::app::is_custom "$@"
}

function manager::app::app_directory() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    if manager::app::is_not_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(manager::app::parse_app_name "$pm_app") || return "$SHELL_FALSE"
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
    app_name=$(manager::app::parse_app_name "$pm_app") || return "$SHELL_FALSE"

    if manager::app::is_not_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom, sub_command=${sub_command}"
        return "$SHELL_FALSE"
    fi

    local custom_manager_path="${SCRIPT_DIR_612d794c}/custom_agent.sh"

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
    shift
    # relation_type 取值：dependencies 或者 features
    local relation_type_2fcf6903="$1"
    shift
    local pm_app_2fcf6903="$1"
    shift
    local link_path_2fcf6903="$1"
    shift

    local temp_array_2fcf6903=()
    local temp_2fcf6903

    manager::app::is_package_name_valid "$pm_app_2fcf6903" || return "$SHELL_FALSE"

    if manager::app::is_not_custom "$pm_app_2fcf6903"; then
        # 如果不是自定义的包，那么不需要检查循环依赖
        return "$SHELL_TRUE"
    fi

    if array::is_contain "${!cache_apps_2fcf6903}" "$pm_app_2fcf6903"; then
        # 如果已经在缓存中，那么不需要检查循环依赖
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "app($pm_app_2fcf6903) has checked no loop ${relation_type_2fcf6903}. skip it."
        return "$SHELL_TRUE"
    fi

    echo "$link_path_2fcf6903" | grep -wq "$pm_app_2fcf6903"
    if [ $? -eq "${SHELL_TRUE}" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "app($pm_app_2fcf6903) has loop ${relation_type_2fcf6903}. ${relation_type_2fcf6903} link path: ${link_path_2fcf6903} $pm_app_2fcf6903"
        return "$SHELL_FALSE"
    fi

    temp_2fcf6903="$(manager::app::run_custom_manager "${pm_app_2fcf6903}" "${relation_type_2fcf6903}")" || return "$SHELL_FALSE"
    array::readarray temp_array_2fcf6903 < <(echo "$temp_2fcf6903")
    for temp_2fcf6903 in "${temp_array_2fcf6903[@]}"; do
        manager::app::is_no_loop_relationships "${!cache_apps_2fcf6903}" "${relation_type_2fcf6903}" "${temp_2fcf6903}" "$link_path_2fcf6903 $pm_app_2fcf6903" || return "$SHELL_FALSE"
    done

    cache_apps_2fcf6903+=("${pm_app_2fcf6903}")
    return "$SHELL_TRUE"
}

# 检查循环依赖
function manager::app::check_loop_relationships() {
    # shellcheck disable=SC2034
    local dependencies_cache_apps=()
    # shellcheck disable=SC2034
    local features_cache_apps=()
    local app_name
    local pm_app
    local app_path

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "start check all app loop relationships, it may take a long time..."

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        app_name=$(basename "${app_path}")
        pm_app="$(manager::utils::convert_app_name "${app_name}")" || return "$SHELL_FALSE"

        manager::app::is_no_loop_relationships dependencies_cache_apps "dependencies" "${pm_app}" || return "$SHELL_FALSE"
        manager::app::is_no_loop_relationships features_cache_apps "features" "${pm_app}" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "check all app loop relationships success"
    return "$SHELL_TRUE"
}

# 使用包管理器直接执行命令
function manager::app::do_command_use_pm() {
    local -n exclude_apps_a55aa4b0="$1"
    shift
    local command_a55aa4b0="$1"
    shift
    local pm_app_a55aa4b0="$1"
    shift
    local level_indent_a55aa4b0="$1"
    shift

    local package_manager_a55aa4b0
    local package_a55aa4b0
    # 系统包管理器没有这些命令，忽略
    # shellcheck disable=SC2034
    local ignore_command_a55aa4b0=("install_guide" "pre_install" "post_install" "pre_uninstall" "post_uninstall" "fixme" "unfixme")

    if [ -z "$command_a55aa4b0" ]; then
        lerror "command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app_a55aa4b0" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if manager::app::is_custom "${pm_app_a55aa4b0}"; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_a55aa4b0}${pm_app_a55aa4b0}: is custom, can not do command($command_a55aa4b0) by package manager"
        return "$SHELL_FALSE"
    fi

    if array::is_contain ignore_command_a55aa4b0 "$command_a55aa4b0"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_a55aa4b0}${pm_app_a55aa4b0}: system package manager can not do it, ignore command($command_a55aa4b0)"
        return "$SHELL_TRUE"
    fi

    package_manager_a55aa4b0=$(manager::app::parse_package_manager "$pm_app_a55aa4b0") || return "$SHELL_FALSE"
    package_a55aa4b0=$(manager::app::parse_app_name "$pm_app_a55aa4b0") || return "$SHELL_FALSE"

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_a55aa4b0}${pm_app_a55aa4b0}: use ${package_manager_a55aa4b0} do command(${command_a55aa4b0})"

    if array::is_contain "${!exclude_apps_a55aa4b0}" "${pm_app_a55aa4b0}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_a55aa4b0}${pm_app_a55aa4b0}: it is in exclude apps, not do command(${command_a55aa4b0})."
        return "$SHELL_TRUE"
    fi

    "package_manager::${command_a55aa4b0}" "${package_manager_a55aa4b0}" "${package_a55aa4b0}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_a55aa4b0}${pm_app_a55aa4b0}: use ${package_manager_a55aa4b0} do command(${command_a55aa4b0}) failed"
        return "$SHELL_FALSE"
    fi

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_a55aa4b0}${pm_app_a55aa4b0}: use ${package_manager_a55aa4b0} do command(${command_a55aa4b0}) success"

    return "$SHELL_TRUE"
}

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_use_custom() {
    local -n cache_apps_ef62dd2b="$1"
    shift
    local -n exclude_apps_ef62dd2b="$1"
    shift
    local command_ef62dd2b="$1"
    shift
    local pm_app_ef62dd2b="$1"
    shift
    local is_reverse_ef62dd2b="${1:-false}"
    shift
    local level_indent_ef62dd2b="$1"
    shift

    # shellcheck disable=SC2034
    local dependencies_ef62dd2b
    # shellcheck disable=SC2034
    local features_ef62dd2b
    local relationship_ef62dd2b
    local temp_ef62dd2b

    if [ -z "$command_ef62dd2b" ]; then
        lerror "command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app_ef62dd2b" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: use custom manager do command(${command_ef62dd2b}) start."

    if manager::app::is_not_custom "${pm_app_ef62dd2b}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: is not custom, skip use custom manager do command(${command_ef62dd2b})"
        return "$SHELL_TRUE"
    fi

    # 获取它的依赖
    temp_ef62dd2b="$(manager::app::run_custom_manager "${pm_app_ef62dd2b}" "dependencies")"
    array::readarray dependencies_ef62dd2b < <(echo "$temp_ef62dd2b")
    # 获取它的feature
    temp_ef62dd2b="$(manager::app::run_custom_manager "${pm_app_ef62dd2b}" "features")"
    array::readarray features_ef62dd2b < <(echo "$temp_ef62dd2b")

    if string::is_false "${is_reverse_ef62dd2b}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: start dependencies do command(${command_ef62dd2b})..."
        array::copy relationship_ef62dd2b dependencies_ef62dd2b || return "$SHELL_FALSE"

    else
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: start features do command(${command_ef62dd2b})..."
        array::copy relationship_ef62dd2b features_ef62dd2b || return "$SHELL_FALSE"
    fi
    for temp_ef62dd2b in "${relationship_ef62dd2b[@]}"; do
        manager::app::do_command "${!cache_apps_ef62dd2b}" "${!exclude_apps_ef62dd2b}" "${command_ef62dd2b}" "${temp_ef62dd2b}" "${is_reverse_ef62dd2b}" "${level_indent_ef62dd2b}  " || return "$SHELL_FALSE"
    done

    # 处理自己
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: use custom manager self do command(${command_ef62dd2b})..."
    if array::is_contain "${!exclude_apps_ef62dd2b}" "${pm_app_ef62dd2b}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: it is in exclude apps, not do command(${command_ef62dd2b})."
    else
        manager::app::run_custom_manager "${pm_app_ef62dd2b}" "${command_ef62dd2b}" || return "$SHELL_FALSE"
    fi

    if string::is_false "${is_reverse_ef62dd2b}"; then
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: start features do command(${command_ef62dd2b})..."
        array::copy relationship_ef62dd2b features_ef62dd2b || return "$SHELL_FALSE"
    else
        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: start dependencies do command(${command_ef62dd2b})..."
        array::copy relationship_ef62dd2b dependencies_ef62dd2b || return "$SHELL_FALSE"
    fi
    for temp_ef62dd2b in "${relationship_ef62dd2b[@]}"; do
        manager::app::do_command "${!cache_apps_ef62dd2b}" "${!exclude_apps_ef62dd2b}" "${command_ef62dd2b}" "${temp_ef62dd2b}" "${is_reverse_ef62dd2b}" "${level_indent_ef62dd2b}  " || return "$SHELL_FALSE"
    done

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_ef62dd2b}${pm_app_ef62dd2b}: use custom manager do command(${command_ef62dd2b}) end."

    return "${SHELL_TRUE}"
}

function manager::app::do_command() {
    local -n apps_0c1cd5f7="$1"
    shift
    local -n exclude_apps_0c1cd5f7="$1"
    shift
    local command_0c1cd5f7="$1"
    shift
    local pm_app_0c1cd5f7="$1"
    shift
    local is_reverse_0c1cd5f7="${1:-false}"
    shift
    local level_indent_0c1cd5f7="$1"
    shift

    if [ -z "$command_0c1cd5f7" ]; then
        lerror "param command is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$pm_app_0c1cd5f7" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_0c1cd5f7}${pm_app_0c1cd5f7}: start do command(${command_0c1cd5f7})..."

    manager::app::is_package_name_valid "$pm_app_0c1cd5f7" || return "$SHELL_FALSE"

    if array::is_contain "${!apps_0c1cd5f7}" "${pm_app_0c1cd5f7}"; then
        lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_0c1cd5f7}${pm_app_0c1cd5f7}: has been done command(${command_0c1cd5f7}). not do again."
        return "${SHELL_TRUE}"
    fi

    if manager::app::is_not_custom "$pm_app_0c1cd5f7"; then
        manager::app::do_command_use_pm "${!exclude_apps_0c1cd5f7}" "${command_0c1cd5f7}" "$pm_app_0c1cd5f7" "${level_indent_0c1cd5f7}" || return "$SHELL_FALSE"
    else
        # 注意 manager::app::do_command_use_custom 会调用 manager::app::do_command 形成递归
        manager::app::do_command_use_custom "${!apps_0c1cd5f7}" "${!exclude_apps_0c1cd5f7}" "${command_0c1cd5f7}" "$pm_app_0c1cd5f7" "${is_reverse_0c1cd5f7}" "${level_indent_0c1cd5f7}" || return "$SHELL_FALSE"
    fi

    # 所有操作都执行完毕，添加到缓存
    apps_0c1cd5f7+=("${pm_app_0c1cd5f7}")

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${level_indent_0c1cd5f7}${pm_app_0c1cd5f7}: do command(${command_0c1cd5f7}) success."
    return "${SHELL_TRUE}"
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
