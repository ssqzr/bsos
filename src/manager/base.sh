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
__CORE_APPS=("custom:systemd_resolved" "custom:pacman" "custom:sudo" "pacman:go-yq" "pacman:gum")
# __PRE_INSTALL_APPS=()
# __PRE_INSTALL_APPS+=("${__CORE_APPS[@]}")
# __PRE_INSTALL_APPS+=("pacman:gum" "pacman:base-devel")
# __PRE_INSTALL_APPS+=("pacman:git" "custom:yay" "custom:pamac")

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
