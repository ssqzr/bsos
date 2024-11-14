#!/bin/bash

# 开发协助脚本
# 1. 没有其他依赖
# 2. 和安装脚本没有关系，因为开发环境和安装环境不是同一个

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d6dc03c7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/lib/utils/all.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/manager/base.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/manager/app.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/manager/flags.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/manager/flow.sh"

function develop::gen_uuid() {
    uuidgen | awk -F '-' '{print $1}'
}

function develop::update_trait_script() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    local uuid
    uuid=$(develop::gen_uuid)
    sed -i "s/SCRIPT_DIR_uuid/SCRIPT_DIR_$uuid/g" "${app_dir}/trait.sh"
    sed -i "s/template/""${app_name}""/g" "${app_dir}/trait.sh"
}

function develop::update_readme() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    sed -i "s/app_name/$app_name/" "${app_dir}/README.adoc"
}

function develop::command::create() {
    local app_names
    local app_name
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v app_names ]; then
        lerror "add app failed, param(--app) is not set"
        return "$SHELL_FALSE"
    fi

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    if array::is_empty app_names; then
        lerror "add app failed, param(--app) is empty"
        return "$SHELL_FALSE"
    fi

    for app_name in "${app_names[@]}"; do
        if [ -z "$app_name" ]; then
            continue
        fi

        local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

        if [ -e "${app_dir}" ]; then
            lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "app already exists: $app_name"
            continue
        fi

        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "add app: $app_name"

        cp -r "${SCRIPT_DIR_d6dc03c7}/template/app_name" "${app_dir}"

        develop::update_trait_script "$app_name" || return "$SHELL_FALSE"
        develop::update_readme "$app_name" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function develop::command::update() {
    local app_names

    local app_name
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v app_names ]; then
        lwarn "param(--app) is not set app"
        local files=()
        fs::directory::read files "${SCRIPT_DIR_d6dc03c7}/app" || return "$SHELL_FALSE"

        for file in "${files[@]}"; do
            if [ ! -d "$file" ]; then
                lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "$file is not a directory"
                continue
            fi
            app_names+=("$(basename "$file")")
        done
    fi

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    if array::is_empty app_names; then
        lerror "update app failed, param(--app) is empty"
        return "$SHELL_FALSE"
    fi

    for app_name in "${app_names[@]}"; do
        if [ -z "$app_name" ]; then
            continue
        fi
        local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

        if [ ! -e "$app_dir" ]; then
            lerror --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "app($app_name) not exists"
            return "$SHELL_FALSE"
        fi

        linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "update app($app_name) template..."
        # 复制新的文件
        cp -r --update=none "${SCRIPT_DIR_d6dc03c7}/template/app_name"/* "${app_dir}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "copy template file to app($app_name) failed"
            return "$SHELL_FALSE"
        fi
    done

    return "$SHELL_TRUE"
}

function develop::command::check_loop() {
    manager::app::check_loop_relationships || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function develop::command::trait() {

    manager::flags::develop::add || return "$SHELL_FALSE"

    local app_names
    local traits

    local app_name
    local pm_app
    local command
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --trait=*)
            parameter::parse_array --separator="," --option="$param" traits || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v app_names ]; then
        lerror "call app trait failed, param(--app) is not set"
        return "$SHELL_FALSE"
    fi

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    if array::is_empty app_names; then
        lerror "call app trait failed, param(--app) is empty"
        return "$SHELL_FALSE"
    fi

    if [ ! -v traits ]; then
        lerror "call app trait failed, param(--trait) is not set"
        return "$SHELL_FALSE"
    fi

    array::remove_empty traits || return "$SHELL_FALSE"
    array::dedup traits || return "$SHELL_FALSE"

    if array::is_empty traits; then
        lerror "call app trait failed, param(--trait) is empty"
        return "$SHELL_FALSE"
    fi

    for app_name in "${app_names[@]}"; do
        pm_app="custom:$app_name"
        for command in "${traits[@]}"; do
            linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "call app($pm_app) trait ${command}..."
            manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"
            lsuccess --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "call app($pm_app) trait ${command} success."
        done
    done

    return "$SHELL_TRUE"
}

function develop::command::install() {
    manager::flags::develop::add || return "$SHELL_FALSE"
    manager::flags::reuse_cache::add || return "$SHELL_FALSE"

    local app_names

    local app_name
    local pm_apps=()
    local exclude_app_names=()
    local exclude_pm_apps=()
    local param

    for param in "$@"; do
        case "$param" in
        --app=*)
            parameter::parse_array --separator="," --option="$param" app_names || return "$SHELL_FALSE"
            ;;
        --exclude-app=*)
            parameter::parse_array --separator="," --option="$param" exclude_app_names || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v app_names ]; then
        lerror "call app install failed, param(--app) is not set"
        return "$SHELL_FALSE"
    fi

    array::remove_empty app_names || return "$SHELL_FALSE"
    array::dedup app_names || return "$SHELL_FALSE"

    array::remove_empty exclude_app_names || return "$SHELL_FALSE"
    array::dedup exclude_app_names || return "$SHELL_FALSE"

    if array::is_empty app_names; then
        lerror "call app install failed, param(--app) is empty"
        return "$SHELL_FALSE"
    fi

    for app_name in "${app_names[@]}"; do
        pm_apps+=("custom:$app_name")
    done

    for app_name in "${exclude_app_names[@]}"; do
        exclude_pm_apps+=("custom:$app_name")
    done

    manager::cache::do pm_apps exclude_pm_apps || return "$SHELL_FALSE"

    manager::flow::install::main || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function develop::command() {
    local subcommand="$1"
    local command_params=("${@:2}")

    case "${subcommand}" in
    "create" | "update" | "check_loop" | "install" | "trait")
        "develop::command::${subcommand}" "${command_params[@]}" || return "$SHELL_FALSE"
        ;;
    *)
        lerror "unknown command(${subcommand})"
        return "$SHELL_FALSE"
        ;;
    esac
    return "$SHELL_TRUE"
}
