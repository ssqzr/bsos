#!/bin/bash

# 开发协助脚本
# 1. 没有其他依赖
# 2. 和安装脚本没有关系，因为开发环境和安装环境不是同一个

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d6dc03c7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/lib/utils/all.sh"
log::set_log_file "${SCRIPT_DIR_d6dc03c7}/dev.log"

function gen_uuid() {
    uuidgen | awk -F '-' '{print $1}'
}

function update_install_script() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    local uuid
    uuid=$(gen_uuid)
    sed -i "s/SCRIPT_DIR_uuid/SCRIPT_DIR_$uuid/g" "${app_dir}/install.sh"
    sed -i "s/template/""${app_name}""/g" "${app_dir}/install.sh"
}

function update_trait_script() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    local uuid
    uuid=$(gen_uuid)
    sed -i "s/SCRIPT_DIR_uuid/SCRIPT_DIR_$uuid/g" "${app_dir}/trait.sh"
    sed -i "s/template/""${app_name}""/g" "${app_dir}/trait.sh"
}

function update_readme() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    sed -i "s/app_name/$app_name/" "${app_dir}/README.asciidoc"
}

function create_app() {
    if [ $# -ne 1 ]; then
        lerror "add app failed, param app_name is empty"
    fi

    if [ -z "$1" ]; then
        lerror "add app failed, param app_name is empty"
        return "$SHELL_FALSE"
    fi

    local app_name="$1"

    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    if [ -e "${app_dir}" ]; then
        println_warn "app already exists: $app_name"
        return "$SHELL_FALSE"
    fi

    println_info "add app: $app_name"

    cp -r "${SCRIPT_DIR_d6dc03c7}/app_template" "${app_dir}"

    update_install_script "${app_name}" || return "$SHELL_FALSE"

    update_trait_script "$app_name" || return "$SHELL_FALSE"

    update_readme "$app_name" || return "$SHELL_FALSE"
}

function update_template() {
    local app_dir
    for app_dir in "${SCRIPT_DIR_d6dc03c7}/app"/*; do
        local app_name
        app_name="$(basename "$app_dir")"
        if [ ! -d "$app_dir" ]; then
            println_warn "$app_dir is not a directory"
            continue
        fi

        linfo "update app($app_name) template"
        # 复制新的文件
        cp -r --update=none "${SCRIPT_DIR_d6dc03c7}/app_template"/* "${app_dir}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "copy template file to app($app_name) failed"
            return "$SHELL_FALSE"
        fi

        # 复制需要覆盖的文件
        cp -f "${SCRIPT_DIR_d6dc03c7}/app_template/install.sh" "${app_dir}/install.sh"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "copy template file(install.sh) to app($app_name) failed"
            return "$SHELL_FALSE"
        fi

        # 修改需要修改的文件
        update_install_script "${app_name}" || return "$SHELL_FALSE"
    done
}

function main() {
    local cmd="$1"
    local params=("${@:2}")

    case "$cmd" in

    "create_app")
        create_app "${params[@]}"
        ;;
    "update_template")
        update_template
        ;;
    *)
        println_error "unknown cmd: $cmd"
        ;;
    esac
}

main "$@"
