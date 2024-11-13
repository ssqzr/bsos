#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_c084e0be="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function hyprland::trait::config::install() {
    local src
    local dst
    local files
    local filename

    hyprland::hyprctl::autoreload::disable || return "${SHELL_FALSE}"

    # 先备份配置
    fs::directory::safe_delete "${BUILD_TEMP_DIR}/hypr" || return "${SHELL_FALSE}"
    if fs::path::is_exists "${XDG_CONFIG_HOME}/hypr"; then
        fs::directory::copy --force "${XDG_CONFIG_HOME}/hypr" "${BUILD_TEMP_DIR}/hypr" || return "${SHELL_FALSE}"
    fi

    fs::directory::safe_delete "${XDG_CONFIG_HOME}/hypr" || return "${SHELL_FALSE}"
    fs::directory::copy --force "${SCRIPT_DIR_c084e0be}/hypr" "${XDG_CONFIG_HOME}/hypr" || return "${SHELL_FALSE}"

    if fs::path::is_exists "${BUILD_TEMP_DIR}/hypr/conf.d"; then
        fs::directory::read files "${BUILD_TEMP_DIR}/hypr/conf.d" || return "${SHELL_FALSE}"
        for src in "${files[@]}"; do
            filename="$(fs::path::basename "$src")"
            dst="${XDG_CONFIG_HOME}/hypr/conf.d/${filename}"
            if fs::path::is_exists "${dst}"; then
                continue
            fi
            if fs::path::is_file "${src}"; then
                fs::file::copy "${src}" "${dst}" || return "${SHELL_FALSE}"
            elif fs::path::is_directory "${src}"; then
                fs::directory::copy "${src}" "${dst}" || return "${SHELL_FALSE}"
            else
                lerror "file(${src}) is not file and directory"
                return "${SHELL_FALSE}"
            fi
        done
    fi

    hyprland::hyprctl::autoreload::enable || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function hyprland::trait::config::uninstall() {
    fs::directory::safe_delete "${XDG_CONFIG_HOME}/hypr" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function hyprland::settings::cursors() {
    # 反复安装直接覆盖就可以了
    local config_filepath="$XDG_CONFIG_HOME/hypr/conf.d/020-cursor.conf"

    if os::is_vm; then
        cmd::run_cmd_with_history -- sed -i "'s/no_hardware_cursors = .*/no_hardware_cursors = true/g'" "$config_filepath"
        if [ "$?" -ne "${SHELL_TRUE}" ]; then
            lerror "hyprland setting cursors failed"
            return "$SHELL_FALSE"
        fi
    fi
    linfo "hyprland setting cursors success"
    return "${SHELL_TRUE}"
}

function hyprland::settings::monitor() {
    if os::is_vm; then
        fs::file::delete "${XDG_CONFIG_HOME}/hypr/conf.d/050-monitor.conf" || return "${SHELL_FALSE}"
    fi
    linfo "hyprland setting monitor success"
    return "${SHELL_TRUE}"
}

function hyprland::hyprpm::install() {
    if ! hyprland::hyprctl::is_can_connect; then
        lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${PM_APP_NAME}: can not connect to hyprland, do not install hyprpm"
        return "${SHELL_TRUE}"
    fi

    local hyprpm_state="$HOME/.local/share/hyprpm/state.toml"
    cmd::run_cmd_with_history -- rm -f "$hyprpm_state" || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history -- echo -e '"[state]\ndont_warn_install = true"' '>' "$hyprpm_state" || return "${SHELL_FALSE}"

    # 先更新，安装 hyprland headers
    hyprland::hyprpm::update || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function hyprland::trait::xdg_desktop_portal::install() {
    fs::file::copy --force "${SCRIPT_DIR_c084e0be}/xdg-desktop-portal/hyprland-portals.conf" "$XDG_CONFIG_HOME/xdg-desktop-portal/hyprland-portals.conf" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

function hyprland::trait::xdg_desktop_portal::uninstall() {
    # 不删除目录，这个目录并不是 Hyprland 独有的，而是属于 xdg-desktop-portal 的
    fs::file::delete "$XDG_CONFIG_HOME/xdg-desktop-portal/hyprland-portals.conf" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 指定使用的包管理器
function hyprland::trait::package_manager() {
    echo "pacman"
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
function hyprland::trait::install() {
    package_manager::install "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)" || return "${SHELL_FALSE}"

    hyprland::hyprpm::install || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function hyprland::trait::post_install() {
    hyprland::trait::config::install || return "${SHELL_FALSE}"

    # 处理 xdg-desktop-portal
    hyprland::trait::xdg_desktop_portal::install || return "${SHELL_FALSE}"

    hyprland::settings::cursors || return "${SHELL_FALSE}"
    if hyprland::hyprctl::is_can_connect; then
        hyprland::hyprctl::reload || return "$SHELL_FALSE"
    fi

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function hyprland::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function hyprland::trait::uninstall() {
    package_manager::uninstall "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function hyprland::trait::post_uninstall() {
    hyprland::trait::config::uninstall || return "${SHELL_FALSE}"
    hyprland::trait::xdg_desktop_portal::uninstall || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function hyprland::trait::upgrade() {
    package_manager::upgrade "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function hyprland::trait::fixme() {
    lwarn --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${PM_APP_NAME}: TODO: Detecting real environments to generate monitor configurations"

    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function hyprland::trait::unfixme() {
    linfo --handler="+${LOG_HANDLER_STREAM}" --stream-handler-formatter="${LOG_HANDLER_STREAM_FORMATTER}" "${PM_APP_NAME}: start undo fixme..."

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
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()

    apps+=("custom:fonts" "pacman:polkit-kde-agent")

    # xdg-desktop-portal
    apps+=("pacman:xdg-desktop-portal-hyprland" "pacman:xdg-desktop-portal-gtk")

    # 插件hyprpm需要的
    apps+=("pacman:cpio")
    apps+=("pacman:hyprwayland-scanner")

    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function hyprland::trait::features() {
    local apps=()

    # 状态栏
    apps+=("custom:anyrun" "custom:ags")

    # hyprfocus 插件
    apps+=("custom:hyprfocus")

    apps+=("custom:audio")

    # 截图
    apps+=("pacman:grim" "pacman:slurp")

    array::print apps
    return "${SHELL_TRUE}"
}

function hyprland::trait::main() {
    return "${SHELL_TRUE}"
}

hyprland::trait::main
