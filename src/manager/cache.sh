#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b121320e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/../lib/utils/all.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/app.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/base.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/flags.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/utils.sh" || exit 1

# 生成安装列表
function manager::cache::generate_top_apps() {
    local command_6fef53f7="$1"
    shift
    local -n pm_apps_6fef53f7="$1"
    shift

    local pm_app_6fef53f7
    local temp_str_6fef53f7
    local temp_array_6fef53f7=()
    local priority_apps_6fef53f7=()
    # 被其他app依赖的app
    local required_by_6fef53f7=()
    # 没有被依赖的
    local none_dependencies_6fef53f7=()
    local item_6fef53f7
    local app_path_6fef53f7
    local app_name_6fef53f7

    # 先清空安装列表
    config::cache::top_apps::clean || return "$SHELL_FALSE"

    linfo "generate top install app list, it take a long time..."

    if manager::flags::develop::is_exists; then
        linfo "is in develop mode, not add prior install apps to top app list"
    else
        # shellcheck disable=SC2034
        temp_array_6fef53f7=("uninstall" "unfixme")
        if array::is_contain temp_array_6fef53f7 "$command_6fef53f7" && array::is_not_empty "${!pm_apps_6fef53f7}"; then
            linfo "command=($command_6fef53f7) and apps(${pm_apps_6fef53f7[*]}) is not empty, not add prior install apps to top app list"
        else
            # 先处理优先安装的app
            manager::base::prior_install_apps::all priority_apps_6fef53f7 || return "$SHELL_FALSE"
            for pm_app_6fef53f7 in "${priority_apps_6fef53f7[@]}"; do
                config::cache::top_apps::rpush_unique "$pm_app_6fef53f7" || return "$SHELL_FALSE"
            done
        fi
    fi

    if array::is_not_empty "${!pm_apps_6fef53f7}"; then
        linfo "only add ${pm_apps_6fef53f7[*]} to top app list"
        for pm_app_6fef53f7 in "${pm_apps_6fef53f7[@]}"; do
            config::cache::top_apps::rpush_unique "$pm_app_6fef53f7" || return "$SHELL_FALSE"
        done
        return "$SHELL_TRUE"
    fi

    for app_path_6fef53f7 in "${SRC_ROOT_DIR}/app"/*; do
        app_name_6fef53f7=$(basename "${app_path_6fef53f7}")
        pm_app_6fef53f7="$(manager::utils::convert_app_name "${app_name_6fef53f7}")" || return "$SHELL_FALSE"

        if manager::base::core_apps::is_contain "$pm_app_6fef53f7"; then
            continue
        fi

        if ! array::is_contain required_by_6fef53f7 "$pm_app_6fef53f7"; then
            array::rpush_unique none_dependencies_6fef53f7 "$pm_app_6fef53f7"
        fi

        # 获取它的依赖
        local dependencies
        temp_str_6fef53f7="$(manager::app::run_custom_manager "${pm_app_6fef53f7}" "dependencies")"
        array::readarray dependencies < <(echo "$temp_str_6fef53f7")

        local item_6fef53f7
        for item_6fef53f7 in "${dependencies[@]}"; do
            array::remove none_dependencies_6fef53f7 "$item_6fef53f7"
            array::rpush_unique required_by_6fef53f7 "$item_6fef53f7"
        done

        # 获取它的feature
        local features
        temp_str_6fef53f7="$(manager::app::run_custom_manager "${pm_app_6fef53f7}" "features")"
        array::readarray features < <(echo "$temp_str_6fef53f7")
        for item_6fef53f7 in "${features[@]}"; do
            array::remove none_dependencies_6fef53f7 "$item_6fef53f7"
            array::rpush_unique required_by_6fef53f7 "$item_6fef53f7"
        done
    done
    ldebug "none_dependencies_6fef53f7: ${none_dependencies_6fef53f7[*]}"
    ldebug "required_by_6fef53f7: ${required_by_6fef53f7[*]}"

    # 生成安装列表
    for item_6fef53f7 in "${none_dependencies_6fef53f7[@]}"; do
        config::cache::top_apps::rpush_unique "$item_6fef53f7" || return "$SHELL_FALSE"
    done

    lsuccess "generate top install app list success"

    return "$SHELL_TRUE"
}

function manager::cache::generate_exclude_apps() {
    local -n exclude_apps_83764fdc="$1"
    shift

    local item_83764fdc

    linfo "generate exclude app."

    # 每次都重新生成
    config::cache::exclude_apps::clean || return "$SHELL_FALSE"

    for item_83764fdc in "${exclude_apps_83764fdc[@]}"; do
        config::cache::exclude_apps::rpush_unique "$item_83764fdc" || return "$SHELL_FALSE"
    done

    linfo "generate exclude app success."

    return "$SHELL_TRUE"
}

function manager::cache::generate_app_dependencies() {
    local pm_app="$1"
    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local all_dependencies=()
    local dependencies=()
    local features=()
    local item
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo "app(${pm_app}) is not custom app, not need generate dependencies"
        return "$SHELL_TRUE"
    fi

    if config::cache::app::dependencies::is_exists "$pm_app"; then
        linfo "app(${pm_app}) dependencies has been generated"
        return "$SHELL_TRUE"
    fi

    config::cache::app::dependencies::clean "$pm_app" || return "$SHELL_FALSE"

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    # 处理 dependencies
    for item in "${dependencies[@]}"; do
        all_dependencies+=("$item")
        if ! manager::app::is_custom "${item}"; then
            linfo "dependency app(${item}) is not custom app, not need generate dependencies"
            continue
        fi
        manager::cache::generate_app_dependencies "$item" || return "$SHELL_FALSE"
        local item_dependencies=()
        config::cache::app::dependencies::all item_dependencies "$item" || return "$SHELL_FALSE"
        array::extend all_dependencies item_dependencies
    done

    # 处理 features
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        all_dependencies+=("$item")
        if ! manager::app::is_custom "${item}"; then
            linfo "feature app(${item}) is not custom app, not need generate dependencies"
            continue
        fi
        manager::cache::generate_app_dependencies "$item" || return "$SHELL_FALSE"
        local item_dependencies=()
        config::cache::app::dependencies::all item_dependencies "$item" || return "$SHELL_FALSE"
        array::extend all_dependencies item_dependencies
    done

    for item in "${all_dependencies[@]}"; do
        config::cache::app::dependencies::rpush_unique "$pm_app" "$item" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

# 每个APP的依赖关系图
function manager::cache::generate_apps_relation() {
    local temp_str
    local app_name
    local pm_app
    local item_dependencies=()

    linfo "generate apps relation infomation, it take a long time..."

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        app_name=$(basename "${app_path}")
        pm_app="$(manager::utils::convert_app_name "$app_name")" || return "$SHELL_FALSE"

        config::cache::app::dependencies::delete "$pm_app" || return "$SHELL_FALSE"
        config::cache::app::required_by::delete "$pm_app" || return "$SHELL_FALSE"
    done

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        app_name=$(basename "${app_path}")
        pm_app="$(manager::utils::convert_app_name "$app_name")" || return "$SHELL_FALSE"

        manager::cache::generate_app_dependencies "$pm_app" || return "$SHELL_FALSE"
    done

    # 根据dependencies依赖关系，生成 as_dependencies 的列表
    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        app_name=$(basename "${app_path}")
        pm_app="$(manager::utils::convert_app_name "$app_name")" || return "$SHELL_FALSE"

        item_dependencies=()
        config::cache::app::dependencies::all item_dependencies "$item" || return "$SHELL_FALSE"

        for item in "${item_dependencies[@]}"; do
            config::cache::app::required_by::rpush_unique "$item" "$pm_app" || return "$SHELL_FALSE"
        done
    done

    lsuccess "generate apps relation map success."

    return "$SHELL_TRUE"
}

function manager::cache::do() {
    local command_096d6b8f=$1
    shift
    local -n include_pm_apps_096d6b8f=$1
    shift
    local -n exclude_pm_apps_096d6b8f=$1
    shift

    local exit_code_096d6b8f=0

    if manager::flags::reuse_cache::is_not_exists; then
        linfo "no reuse cache, delete all cache"
        config::cache::delete || return "$SHELL_FALSE"
    fi

    if config::cache::apps::is_not_exists; then
        tui::components::spinner::main --title="generate apps relation. It may take a long time..." exit_code_096d6b8f manager::cache::generate_apps_relation || return "$SHELL_FALSE"
        if [ "$exit_code_096d6b8f" -ne "$SHELL_TRUE" ]; then
            lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "generate apps relation failed."
            return "$SHELL_FALSE"
        fi
    fi

    # 指定 include_pm_apps_096d6b8f 参数时，必须重新生成
    if array::is_not_empty "${!include_pm_apps_096d6b8f}" || config::cache::top_apps::is_not_exists; then
        tui::components::spinner::main --title="generate top apps. It may take a long time..." exit_code_096d6b8f manager::cache::generate_top_apps "${command_096d6b8f}" "${!include_pm_apps_096d6b8f}" || return "$SHELL_FALSE"
        if [ "$exit_code_096d6b8f" -ne "$SHELL_TRUE" ]; then
            lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "generate top apps failed."
            return "$SHELL_FALSE"
        fi
    fi

    # 每次都重新生成，因为没有提供清空的接口，缓存后想清空的话，需要手动删除配置。并且排除的应用不多，不会很耗时。
    manager::cache::generate_exclude_apps "${!exclude_pm_apps_096d6b8f}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
