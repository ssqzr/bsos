#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_c084e0be="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"


# 指定使用的包管理器
function hyprland::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function hyprland::trait::package_name() {
    echo "hyprland"
}

# 简短的描述信息，查看包的信息的时候会显示
function hyprland::trait::description() {
    package_manager::package_description "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function hyprland::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function hyprland::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function hyprland::trait::do_install() {
    package_manager::install "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function hyprland::trait::post_install() {
    cmd::run_cmd_with_history mkdir -p "${XDG_CONFIG_HOME}" || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history cp -r "${SCRIPT_DIR_c084e0be}/hypr" "${XDG_CONFIG_HOME}" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function hyprland::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function hyprland::trait::do_uninstall() {
    package_manager::uninstall "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function hyprland::trait::post_uninstall() {
    cmd::run_cmd_with_history rm -rf "${XDG_CONFIG_HOME}/hypr" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function hyprland::trait::finally() {
    println_info "${PM_APP_NAME}: TODO: Detecting real environments to generate monitor configurations"
    println_info "${PM_APP_NAME}: you should run 'Hyprland' to start it"

    if ! process::is_running "Hyprland"; then
        println_warn "${PM_APP_NAME}: some settings not configed, you should run 'Hyprland' and run finally command again."
    fi
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function hyprland::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # pacman:vim
    # yay:vim
    # pamac:vim
    # custom:vim   自定义，也就是通过本脚本进行安装
    # TODO: 这些依赖需要处理，处理到swaync
    local apps=("custom:fonts" "pacman:polkit-kde-agent" "custom:fcitx5" "custom:wezterm" "custom:yazi" "custom:rofi" "custom:swaync" "custom:anyrun" "custom:ags")

    # xdg-desktop-portal
    apps+=("default:xdg-desktop-portal-hyprland" "default:xdg-desktop-portal-gtk")

    # 截图需要的
    apps+=("default:grim" "default:slurp" "flatpak:org.ksnip.ksnip")
    # 邮箱
    apps+=("default:thunderbird" "default:thunderbird-i18n-zh-cn")
    # 翻译软件
    apps+=("custom:pot")
    # 取色软件
    apps+=("default:hyprpicker")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function hyprland::trait::features() {
    # TODO: 这些依赖需要处理
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function hyprland::trait::main() {
    return "$SHELL_TRUE"
}

hyprland::trait::main
