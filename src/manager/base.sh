#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b5b83ba6="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_b5b83ba6}/../lib/utils/all.sh"

# NOTE: 在处理所有安装流程前需要安装的app，是单独的安装流程。一般是本脚本功能需要的app
# sudo 是为了用户安全
# gum 是安装脚本为了更好的终端交互需要安装的，它可以直接使用pacman安装
# go_yq 是配置管理需要的，安装脚本也需要读写配置
# base 是为了基本的编译需要的
# git 是为了安装pamac需要的，后面 git 还会以custom的方式再安装一遍，因为有一些配置需要配置
# pamac 为了安装其他应用
__PRE_INSTALL_APPS=("custom:sudo" "pacman:lsof" "pacman:gum" "pacman:go-yq" "pacman:base-devel")
__PRE_INSTALL_APPS+=("pacman:git" "custom:yay" "custom:pamac")

function base::get_pre_install_apps() {
    array::print __PRE_INSTALL_APPS
}
