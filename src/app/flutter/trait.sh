#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_2c7abf78="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function flutter::settings::install_dir() {
    echo "$HOME/software/flutter"
    return "${SHELL_TRUE}"
}

function flutter::settings::env::clean() {
    zsh::config::remove "350" "flutter.zsh" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function flutter::settings::env::setup() {
    local filepath
    local src_dir
    src_dir="$(flutter::settings::install_dir)" || return "${SHELL_FALSE}"

    zsh::config::add "350" "${SCRIPT_DIR_2c7abf78}/flutter.zsh" || return "${SHELL_FALSE}"
    filepath="$(zsh::config::filepath "350" "flutter.zsh")" || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history -- echo "export PATH=\\\"$src_dir/bin:\\\$PATH\\\"" ">>" "$filepath" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 指定使用的包管理器
function flutter::trait::package_manager() {
    echo "yay"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function flutter::trait::package_name() {
    echo "flutter"
}

# 简短的描述信息，查看包的信息的时候会显示
function flutter::trait::description() {
    # package_manager::package_description "$(flutter::trait::package_manager)" "$(flutter::trait::package_name)" || return "$SHELL_FALSE"
    echo "Flutter SDK"
    return "$SHELL_TRUE"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function flutter::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function flutter::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function flutter::trait::install() {
    # package_manager::install "$(flutter::trait::package_manager)" "$(flutter::trait::package_name)" || return "${SHELL_FALSE}"
    local src_dir
    src_dir="$(flutter::settings::install_dir)"

    if [ ! -e "$src_dir/.git" ]; then
        fs::directory::safe_delete "$src_dir" || return "${SHELL_FALSE}"
        cmd::run_cmd_with_history -- git clone "https://github.com/flutter/flutter.git" "$src_dir" || return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function flutter::trait::post_install() {
    local flutter_cmd
    # FIXME: ./README.adoc#flutter-xdg-config-home
    flutter_cmd=("unset" "XDG_CONFIG_HOME" ";" "$(flutter::settings::install_dir)/bin/flutter")

    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" channel stable || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" upgrade || return "${SHELL_FALSE}"

    flutter::settings::env::setup || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" config --android-sdk "/opt/android-sdk" || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" config --enable-web || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" config --enable-linux-desktop || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" config --enable-android || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" config --android-studio-dir=/var/lib/flatpak/app/com.google.AndroidStudio/current/active/files/extra/android-studio || return "${SHELL_FALSE}"

    # 运行 flutter 命令会调用 adb 命令运行一个服务，子进程会占用锁文件不释放。
    process::kill_by_name adb || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function flutter::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function flutter::trait::uninstall() {
    # package_manager::uninstall "$(flutter::trait::package_manager)" "$(flutter::trait::package_name)" || return "${SHELL_FALSE}"
    fs::directory::safe_delete "$(flutter::settings::install_dir)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function flutter::trait::post_uninstall() {
    flutter::settings::env::clean || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function flutter::trait::upgrade() {
    local flutter_cmd
    # FIXME: ./README.adoc#flutter-xdg-config-home
    flutter_cmd=("unset" "XDG_CONFIG_HOME" ";" "$(flutter::settings::install_dir)/bin/flutter")

    cmd::run_cmd_with_history -- "${flutter_cmd[@]}" upgrade || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function flutter::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function flutter::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function flutter::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()
    apps+=("custom:chrome")
    apps+=("custom:android_develop")
    # 编译 linux 的桌面程序需要 clang
    apps+=("pacman:clang")
    # flutter 切换 channel 或者 upgrade 等的时候需要解压包
    apps+=("pacman:unzip")

    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function flutter::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function flutter::trait::main() {
    return "${SHELL_TRUE}"
}

flutter::trait::main
