#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_fd204c06="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 处理 .config/zsh 目录下的配置文件
function zsh::settings::zsh_dir() {
    local filepath
    local filename
    local files
    local temp_str

    # 备份配置文件
    fs::directory::safe_delete "$BUILD_TEMP_DIR/zsh" || return "$SHELL_FALSE"
    fs::directory::copy "$XDG_CONFIG_HOME/zsh" "$BUILD_TEMP_DIR/zsh" || return "$SHELL_FALSE"
    fs::directory::safe_delete "$XDG_CONFIG_HOME/zsh" || return "$SHELL_FALSE"

    # 拷贝全新的文件
    fs::directory::copy "$SCRIPT_DIR_fd204c06/zsh" "$XDG_CONFIG_HOME/zsh" || return "$SHELL_FALSE"

    # 处理 zshrc.d 目录下的配置文件，赋值不属于 zsh 内置的脚本
    fs::directory::read files "$BUILD_TEMP_DIR/zsh/zshrc.d" || return "$SHELL_FALSE"
    for filepath in "${files[@]}"; do
        filename="$(basename "$filepath")"
        temp_str="$XDG_CONFIG_HOME/zsh/zshrc.d/$filename"
        if fs::path::is_exists "$temp_str"; then
            continue
        fi
        if fs::path::is_file "$filepath"; then
            fs::file::copy "$filepath" "$temp_str" || return "$SHELL_FALSE"
        elif fs::path::is_directory "$filepath"; then
            fs::directory::copy "$filepath" "$temp_str" || return "$SHELL_FALSE"
        else
            lerror "file($filepath) is not file and directory"
            return "$SHELL_FALSE"
        fi
    done

    return "${SHELL_TRUE}"
}

# 指定使用的包管理器
function zsh::trait::package_manager() {
    echo "pacman"
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

    fs::file::copy --force "$SCRIPT_DIR_fd204c06/zshrc" "$HOME/.zshrc" || return "$SHELL_FALSE"
    fs::directory::copy --force "$SCRIPT_DIR_fd204c06/zkbd" "$HOME/.zkbd" || return "$SHELL_FALSE"
    zsh::settings::zsh_dir || return "$SHELL_FALSE"

    # 设置默认的shell为zsh
    # https://wiki.archlinux.org/title/zsh#Making_Zsh_your_default_shell
    local username
    username=$(id -un)
    cmd::run_cmd_with_history -- sudo chsh -s /usr/bin/zsh "${username}"

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
    fs::file::delete "$HOME/.zshrc" || return "$SHELL_FALSE"
    fs::directory::safe_delete "$HOME/.zkbd" || return "$SHELL_FALSE"
    fs::directory::safe_delete "$XDG_CONFIG_HOME/zsh" || return "$SHELL_FALSE"
    local username
    username=$(id -un)
    cmd::run_cmd_with_history -- sudo chsh -s /usr/bin/bash "${username}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function zsh::trait::fixme() {
    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "if you found some keys not working, you can run '/usr/share/zsh/functions/Misc/zkbd' to define keys."
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function zsh::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 如下的包才应该添加进来
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
    apps+=("custom:pkgfile" "pacman:zsh-completions" "pacman:zsh-autosuggestions")
    apps+=("custom:fzf" "custom:pywal" "yay:zsh-theme-powerlevel10k-git")
    apps+=("custom:nvm")
    # 如果有特殊处理，zsh-syntax-highlighting 的配置一定要放到最后
    # 虽然目前的依赖顺序没有影响，但是为了后续忘记这个限制，特意放到最后做标注
    # https://github.com/zsh-users/zsh-syntax-highlighting?tab=readme-ov-file#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file
    apps+=("pacman:zsh-syntax-highlighting")
    array::print apps
    return "${SHELL_TRUE}"
}

function zsh::trait::main() {
    return "$SHELL_TRUE"
}

zsh::trait::main
