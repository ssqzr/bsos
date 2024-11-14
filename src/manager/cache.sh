#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b121320e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/../lib/utils/all.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/app_manager.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/base.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b121320e}/flags.sh" || exit 1

# 生成安装列表
function manager::cache::generate_top_apps() {
    local pm_apps=("${@}")

    local pm_app
    local temp_str
    local priority_apps=()
    # 被其他app依赖的app
    local required_by=()
    # 没有被依赖的
    local none_dependencies=()
    local item
    local app_path

    # 先清空安装列表
    config::cache::top_apps::clean || return "$SHELL_FALSE"

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "generate top install app list, it take a long time..."

    if manager::flags::develop::is_exists; then
        linfo "is in develop mode, not add prior install apps to top app list"
    else
        # 先处理优先安装的app
        temp_str="$(base::prior_install_apps::list)" || return "$SHELL_FALSE"
        array::readarray priority_apps < <(echo "${temp_str}")
        for pm_app in "${priority_apps[@]}"; do
            config::cache::top_apps::rpush_unique "$pm_app" || return "$SHELL_FALSE"
        done
    fi

    if ! array::is_empty pm_apps; then
        linfo "only add ${pm_apps[*]} to top app list"
        for pm_app in "${pm_apps[@]}"; do
            config::cache::top_apps::rpush_unique "$pm_app" || return "$SHELL_FALSE"
        done
        return "$SHELL_TRUE"
    fi

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        if base::core_apps::is_contain "$pm_app"; then
            continue
        fi

        if ! array::is_contain required_by "$pm_app"; then
            array::rpush_unique none_dependencies "$pm_app"
        fi

        # 获取它的依赖
        local dependencies
        temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
        array::readarray dependencies < <(echo "$temp_str")

        local item
        for item in "${dependencies[@]}"; do
            array::remove none_dependencies "$item"
            array::rpush_unique required_by "$item"
        done

        # 获取它的feature
        local features
        temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
        array::readarray features < <(echo "$temp_str")
        for item in "${features[@]}"; do
            array::remove none_dependencies "$item"
            array::rpush_unique required_by "$item"
        done
    done
    ldebug "none_dependencies: ${none_dependencies[*]}"
    ldebug "required_by: ${required_by[*]}"

    # 生成安装列表
    for item in "${none_dependencies[@]}"; do
        config::cache::top_apps::rpush_unique "$item" || return "$SHELL_FALSE"
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "generate top install app list success"

    return "$SHELL_TRUE"
}

function manager::cache::generate_exclude_apps() {
    local -n exclude_apps_83764fdc="$1"
    shift

    local item_83764fdc

    # 每次都重新生成
    config::cache::exclude_apps::clean || return "$SHELL_FALSE"

    for item_83764fdc in "${exclude_apps_83764fdc[@]}"; do
        config::cache::exclude_apps::rpush_unique "$item_83764fdc" || return "$SHELL_FALSE"
    done
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

    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "generate apps relation infomation, it take a long time..."

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        config::cache::app::dependencies::delete "$pm_app" || return "$SHELL_FALSE"
        config::cache::app::required_by::delete "$pm_app" || return "$SHELL_FALSE"
    done

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        manager::cache::generate_app_dependencies "$pm_app" || return "$SHELL_FALSE"
    done

    # 根据dependencies依赖关系，生成 as_dependencies 的列表
    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        local item_dependencies=()
        config::cache::app::dependencies::all item_dependencies "$item" || return "$SHELL_FALSE"

        for item in "${item_dependencies[@]}"; do
            config::cache::app::required_by::rpush_unique "$item" "$pm_app" || return "$SHELL_FALSE"
        done
    done

    lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "generate apps relation map success."

    return "$SHELL_TRUE"
}

function manager::cache::do() {
    local -n include_pm_apps_096d6b8f=$1
    shift
    local -n exclude_pm_apps_096d6b8f=$1
    shift

    if ! manager::flags::reuse_cache::is_exists; then
        linfo "no reuse cache, delete all cache"
        config::cache::delete || return "$SHELL_FALSE"
    fi

    if config::cache::apps::is_not_exists; then
        manager::cache::generate_apps_relation || return "$SHELL_FALSE"
    fi

    # 指定 include_pm_apps_096d6b8f 参数时，必须重新生成 top app list
    if ! array::is_empty "${!include_pm_apps_096d6b8f}"; then
        manager::cache::generate_top_apps "${include_pm_apps_096d6b8f[@]}" || return "$SHELL_FALSE"
    else
        if config::cache::top_apps::is_not_exists; then
            # 生成需要处理的应用列表
            manager::cache::generate_top_apps "${include_pm_apps_096d6b8f[@]}" || return "$SHELL_FALSE"
        fi
    fi

    manager::cache::generate_exclude_apps "${!exclude_pm_apps_096d6b8f}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
