#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_fd204c06="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"

# 指定使用的包管理器
function zsh::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function zsh::trait::package_name() {
    echo "zsh"
}

# 简短的描述信息，查看包的信息的时候会显示
function zsh::trait::description() {
    package_manager::package_description "$(zsh::trait::package_manager)" "$(zsh::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function zsh::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function zsh::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function zsh::trait::do_install() {
    package_manager::install "$(zsh::trait::package_manager)" "$(zsh::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function zsh::trait::post_install() {

    cmd::run_cmd_with_history cp -f "$SCRIPT_DIR_fd204c06/zshrc" "$HOME/.zshrc" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history rm -rf "$HOME/.zkbd" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history rm -rf "$XDG_CONFIG_HOME/zsh" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history cp -rf "$SCRIPT_DIR_fd204c06/zkbd" "$HOME/.zkbd" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history cp -rf "$SCRIPT_DIR_fd204c06/zsh" "$XDG_CONFIG_HOME/zsh" || return "$SHELL_FALSE"

    # 设置默认的shell为zsh
    # https://wiki.archlinux.org/title/zsh#Making_Zsh_your_default_shell
    local username
    username=$(id -un)
    cmd::run_cmd_with_history sudo chsh -s /usr/bin/zsh "${username}"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function zsh::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function zsh::trait::do_uninstall() {
    package_manager::uninstall "$(zsh::trait::package_manager)" "$(zsh::trait::package_name)" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function zsh::trait::post_uninstall() {
    cmd::run_cmd_with_history rm -f "$HOME/.zshrc" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history rm -rf "$HOME/.zkbd" || return "$SHELL_FALSE"
    cmd::run_cmd_with_history rm -rf "$XDG_CONFIG_HOME/zsh" || return "$SHELL_FALSE"
    local username
    username=$(id -un)
    cmd::run_cmd_with_history sudo chsh -s /usr/bin/bash "${username}"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function zsh::trait::finally() {
    println_warn "if you found some keys not working, you can run '/usr/share/zsh/functions/Misc/zkbd' to define keys."
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖，如下的包才应该添加进来
# 1. 使用包管理器安装，它没有处理的依赖，并且有额外的配置或者其他设置。如果没有额外的配置，可以在 _pre_install 函数里直接安装就可以了。
# 2. 包管理器安装处理了依赖，但是这个依赖有额外的配置或者其他设置的
# NOTE: 这里填写的依赖是必须要安装的
function zsh::trait::dependencies() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function zsh::trait::features() {
    local apps=()
    apps+=("custom:fonts")
    apps+=("custom:pkgfile" "default:zsh-completions" "default:zsh-autosuggestions")
    apps+=("custom:fzf" "custom:pywal" "default:zsh-theme-powerlevel10k-git")
    # 如果有特殊处理，zsh-syntax-highlighting 的配置一定要放到最后
    # 虽然目前的依赖顺序没有影响，但是为了后续忘记这个限制，特意放到最后做标注
    # https://github.com/zsh-users/zsh-syntax-highlighting?tab=readme-ov-file#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file
    apps+=("default:zsh-syntax-highlighting")
    array::print apps
    return "${SHELL_TRUE}"
}

function zsh::trait::main() {
    return "$SHELL_TRUE"
}

zsh::trait::main
