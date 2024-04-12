#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b121320e="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

function manager::cache::_recursion_generate_pre_install_list() {
    local pm_app="$1"
    local dependencies
    local item
    local features
    local temp
    if ! manager::app::is_custom "${pm_app}"; then
        config::cache::pre_install_apps::rpush_unique "${pm_app}"
        return "$SHELL_TRUE"
    fi

    # 获取它的依赖
    temp="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "${temp}")

    for item in "${dependencies[@]}"; do
        manager::cache::_recursion_generate_pre_install_list "${item}" || return "$SHELL_FALSE"
    done

    # 获取它的feature
    temp="$(manager::app::run_custom_manager "${pm_app}" "features")" || return "$SHELL_FALSE"
    array::readarray features < <(echo "${temp}")
    for item in "${features[@]}"; do
        manager::cache::_recursion_generate_pre_install_list "${item}" || return "$SHELL_FALSE"
    done

    # 处理自己
    config::cache::pre_install_apps::rpush_unique "${pm_app}"
    return "$SHELL_TRUE"
}

# 这个列表目前只是用作过滤使用
function manager::cache::generate_pre_install_list() {
    local pm_app
    local pre_install_apps=()
    local temp_str

    config::cache::pre_install_apps::clean || return "$SHELL_FALSE"

    println_info "generate pre install app list, it take a long time..."
    linfo "generate pre install app list, it take a long time..."

    temp_str="$(base::get_pre_install_apps)" || return "$SHELL_FALSE"
    array::readarray pre_install_apps < <(echo "${temp_str}")
    for pm_app in "${pre_install_apps[@]}"; do
        manager::cache::_recursion_generate_pre_install_list "${pm_app}" || return "$SHELL_FALSE"
    done

    linfo "generate pre install app list success."
    println_success "generate pre install app list success."
    return "$SHELL_TRUE"
}

# 生成安装列表
function manager::cache::generate_top_apps() {
    local pm_app="$1"

    local temp_str

    # 先清空安装列表
    config::cache::top_apps::clean || return "$SHELL_FALSE"

    println_info "generate top install app list, it take a long time..."
    linfo "generate top install app list, it take a long time..."

    if [ -n "$pm_app" ]; then
        linfo "only add ${pm_app} to top app list"
        config::cache::top_apps::rpush "$pm_app" || return "$SHELL_FALSE"
        return "$SHELL_TRUE"
    fi

    # 被其他app依赖的app
    local as_dependencies=()
    # 没有被依赖的
    local none_dependencies=()

    local app_path
    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        if config::cache::pre_install_apps::is_contain "$pm_app"; then
            continue
        fi

        if ! array::is_contain as_dependencies "$pm_app"; then
            array::rpush_unique none_dependencies "$pm_app"
        fi

        # 获取它的依赖
        local dependencies
        temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
        array::readarray dependencies < <(echo "$temp_str")

        local item
        for item in "${dependencies[@]}"; do
            array::remove none_dependencies "$item"
            array::rpush_unique as_dependencies "$item"
        done

        # 获取它的feature
        local features
        temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
        array::readarray features < <(echo "$temp_str")
        for item in "${features[@]}"; do
            array::remove none_dependencies "$item"
            array::rpush_unique as_dependencies "$item"
        done
    done
    ldebug "none_dependencies: ${none_dependencies[*]}"
    ldebug "as_dependencies: ${as_dependencies[*]}"

    # 生成安装列表
    local pm_app
    for item in "${none_dependencies[@]}"; do
        config::cache::top_apps::rpush "$item" || return "$SHELL_FALSE"
    done

    linfo "generate top install app list success"
    println_success "generate top install app list success"

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
        temp_str="$(config::cache::app::dependencies::get "$item")"
        array::readarray item_dependencies < <(echo "$temp_str")
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
        temp_str="$(config::cache::app::dependencies::get "$item")"
        array::readarray item_dependencies < <(echo "$temp_str")
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
    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        config::cache::app::dependencies::delete "$pm_app" || return "$SHELL_FALSE"
        config::cache::app::as_dependencies::delete "$pm_app" || return "$SHELL_FALSE"
    done

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        manager::cache::generate_app_dependencies "$pm_app" || return "$SHELL_FALSE"
    done

    # 根据dependencies依赖关系，生成as_dependencies的列表
    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        local item_dependencies=()
        temp_str="$(config::cache::app::dependencies::get "$pm_app")"
        array::readarray item_dependencies < <(echo "$temp_str")

        for item in "${item_dependencies[@]}"; do
            config::cache::app::as_dependencies::rpush_unique "$item" "$pm_app" || return "$SHELL_FALSE"
        done
    done

    println_success "generate apps relation map success."

    return "$SHELL_TRUE"
}

function manager::cache::do() {
    local reuse_cache
    while true; do
        printf_blue "reuse cache if exists ??? (y/n)[Y] "
        read -r -e -n 1 reuse_cache
        linfo "get input reuse_cache=${reuse_cache}"
        if [ -z "$reuse_cache" ]; then
            reuse_cache="y"
            break
        fi
        if string::is_true_or_false "$reuse_cache"; then
            break
        fi
        println_error "input invalid, please input y or n."
    done
    if string::is_false "$reuse_cache"; then
        config::cache::delete || return "$SHELL_FALSE"
    fi

    if config::cache::is_exists; then
        linfo "cache exists, reuse it."
        return "$SHELL_TRUE"
    fi

    # 这个列表目前只用作过滤判断用
    manager::cache::generate_pre_install_list || return "$SHELL_FALSE"

    manager::cache::generate_apps_relation || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
