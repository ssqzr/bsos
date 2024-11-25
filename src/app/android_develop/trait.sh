#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_a8316bbe="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function android_develop::settings::agree_license() {
    local sdkmanager="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"

    # 同意许可协议
    cmd::run_cmd_with_history -- yes "|" sudo "${sdkmanager}" --licenses || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function android_develop::settings::install_android_build_tools() {
    # 使用 sdkmanager 安装其他的包，而不是安装 aur 包是因为：
    # - aur 包太多，不知道选择哪个
    # - 安装多个版本时，可以通过 sdkmanager 管理，而不是安装多个 aur 包
    local build_tool
    # 由于 sdkmanager 并不在当前的 PATH 路径中，需要重新打开终端才会添加 sdkmanager 的执行目录到 PATH 中
    # 所以当前脚本执行需要使用绝对路径
    local sdkmanager="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"

    # 安装build-tools
    build_tool=$("${sdkmanager}" --list | grep build-tools | tail -n 1 | awk '{print $1}') || return "$SHELL_FALSE"
    build_tool=$(string::trim "$build_tool") || return "$SHELL_FALSE"
    "${sdkmanager}" --list_installed | grep -q "$build_tool"
    if [ "$?" -eq "$SHELL_TRUE" ]; then
        ldebug "android build-tools($build_tool) is already installed."
    else
        cmd::run_cmd_with_history --sudo -- "${sdkmanager}" --sdk_root=/opt/android-sdk --install "'$build_tool'" || return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

function android_develop::settings::install_android_platform_tools() {
    # 只有一个版本
    local platform_tools="platform-tools"
    local sdkmanager="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"

    "${sdkmanager}" --list_installed | grep -q "$platform_tools"
    if [ "$?" -eq "$SHELL_TRUE" ]; then
        ldebug "android platform-tools($platform_tools) is already installed."
    else
        cmd::run_cmd_with_history --sudo -- "${sdkmanager}" --sdk_root=/opt/android-sdk --install "'$platform_tools'" || return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

function android_develop::settings::install_android_platform() {
    # FIXME: 没有找到一个简单的方式找到最新的版本，这里暂时写死
    local platform="platforms;android-34"
    local sdkmanager="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"

    "${sdkmanager}" --list_installed | grep -q "$platform"
    if [ "$?" -eq "$SHELL_TRUE" ]; then
        ldebug "android platform($platform) is already installed."
    else
        cmd::run_cmd_with_history --sudo -- "${sdkmanager}" --sdk_root=/opt/android-sdk --install "'$platform'" || return "$SHELL_FALSE"
    fi

    return "$SHELL_TRUE"
}

# 指定使用的包管理器
function android_develop::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function android_develop::trait::package_name() {
    echo "android develop tools"
}

# 简短的描述信息，查看包的信息的时候会显示
function android_develop::trait::description() {
    # package_manager::package_description "$(android_develop::trait::package_manager)" "$(android_develop::trait::package_name)" || return "$SHELL_FALSE"
    echo "deploy android develop tools"
    return "$SHELL_TRUE"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function android_develop::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function android_develop::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function android_develop::trait::do_install() {
    # package_manager::install "$(android_develop::trait::package_manager)" "$(android_develop::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function android_develop::trait::post_install() {
    android_develop::settings::agree_license || return "${SHELL_FALSE}"
    android_develop::settings::install_android_build_tools || return "${SHELL_FALSE}"
    android_develop::settings::install_android_platform_tools || return "${SHELL_FALSE}"
    android_develop::settings::install_android_platform || return "${SHELL_FALSE}"

    # android-sdk-cmdline-tools-latest 包会处理 ANDROID_HOME 和 ANDROID_SDK_ROOT 和 PATH 环境变量
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function android_develop::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function android_develop::trait::do_uninstall() {
    # package_manager::uninstall "$(android_develop::trait::package_manager)" "$(android_develop::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function android_develop::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function android_develop::trait::upgrade() {
    # package_manager::upgrade "$(android_develop::trait::package_manager)" "$(android_develop::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function android_develop::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function android_develop::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function android_develop::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()

    apps+=("pacman:jdk-openjdk")
    # apps+=("pacman:android-tools")
    apps+=("yay:android-sdk-cmdline-tools-latest")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function android_develop::trait::features() {
    local apps=()

    apps+=("flatpak:com.google.AndroidStudio")

    array::print apps
    return "${SHELL_TRUE}"
}

function android_develop::trait::main() {
    return "${SHELL_TRUE}"
}

android_develop::trait::main
