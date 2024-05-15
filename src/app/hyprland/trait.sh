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

function hyprland::settings::hyprland_config_filepath() {
    echo "$XDG_CONFIG_HOME/hypr/hyprland.conf"
}

function hyprland::settings::base_config_filepath() {
    echo "$XDG_CONFIG_HOME/hypr/conf.d/base.conf"
}

# 根据已有的配置进行修改
function hyprland::settings::modify_hyprland_config() {
    local config_filepath
    config_filepath="$(hyprland::settings::hyprland_config_filepath)"

    if [ ! -e "$config_filepath" ]; then
        # sed 不能操作空文件
        cmd::run_cmd_with_history echo '>' "$config_filepath" || return "${SHELL_FALSE}"
    fi

    # 处理全部变量
    grep -q "variables.conf" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        # 全局变量必须是第一个引入的
        cmd::run_cmd_with_history sed -i "'1a\\source = conf.d/variables.conf'" "$config_filepath" || return "${SHELL_FALSE}"
    fi

    # 处理基础的设置
    grep -q "base.conf" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        cmd::run_cmd_with_history sed -i "'/variables.conf/a\\source = conf.d/base.conf'" "$config_filepath" || return "${SHELL_FALSE}"
    fi

    # 处理显示器的设置
    grep -q "monitor.conf" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        cmd::run_cmd_with_history sed -i "'\$a\\source = conf.d/monitor.conf'" "$config_filepath" || return "${SHELL_FALSE}"
    fi

    # 处理工作空间的设置
    grep -q "workspace.conf" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        cmd::run_cmd_with_history sed -i "'\$a\\source = conf.d/workspace.conf'" "$config_filepath" || return "${SHELL_FALSE}"
    fi

    # 处理最小化窗口功能的设置
    grep -q "minimized.conf" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        cmd::run_cmd_with_history sed -i "'\$a\\source = conf.d/minimized.conf'" "$config_filepath" || return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function hyprland::settings::cursors() {
    # 反复安装直接覆盖就可以了
    local config_filepath
    config_filepath="$(hyprland::settings::base_config_filepath)"

    if os::is_vm; then
        cmd::run_cmd_with_history sed -i "'s/^# \(env = WLR_NO_HARDWARE_CURSORS, 1\)/\\1/g'" "$config_filepath"
        if [ "$?" -ne "${SHELL_TRUE}" ]; then
            lerror "hyprland setting cursors failed"
            return "$SHELL_FALSE"
        fi
    fi
    linfo "hyprland setting cursors success"
    return "${SHELL_TRUE}"
}

function hyprland::settings::terminal() {
    # 反复安装直接覆盖就可以了
    local terminal
    local config_filepath
    config_filepath="$(hyprland::settings::base_config_filepath)"
    if os::is_vm; then
        terminal="terminator"
    else
        # 虚拟机里面不支持 wezterm
        terminal="wezterm"
    fi
    cmd::run_cmd_with_history sed -i "'s/__terminal__/$terminal/g'" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        lerror "hyprland setting terminal failed"
        return "$SHELL_FALSE"
    fi
    linfo "hyprland setting terminal success"
    return "${SHELL_TRUE}"
}

function hyprland::settings::file_manager() {
    # 反复安装直接覆盖就可以了
    local file_manager
    local config_filepath
    config_filepath="$(hyprland::settings::base_config_filepath)"
    if os::is_vm; then
        file_manager="terminator -e yazi"
    else
        # 虚拟机里面不支持 wezterm
        file_manager="wezterm start -- yazi"
    fi
    cmd::run_cmd_with_history sed -i "'s/__file_manager__/$file_manager/g'" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        lerror "hyprland setting file manager failed"
        return "$SHELL_FALSE"
    fi
    linfo "hyprland setting file manager success"
    return "${SHELL_TRUE}"
}

function hyprland::settings::monitor() {
    local config_filepath
    config_filepath="$(hyprland::settings::hyprland_config_filepath)"
    if os::is_vm; then
        # 反复安装也不会有问题
        cmd::run_cmd_with_history sed -i "'s%^\(source = conf.d/monitor.conf\)%# \\1%g'" "$config_filepath"
        if [ "$?" -ne "${SHELL_TRUE}" ]; then
            lerror "hyprland setting monitor failed"
            return "$SHELL_FALSE"
        fi
    fi
    linfo "hyprland setting monitor success"
    return "${SHELL_TRUE}"
}

function hyprland::settings::workspace() {
    local config_filepath
    config_filepath="$(hyprland::settings::hyprland_config_filepath)"
    if os::is_vm; then
        # 反复安装也不会有问题
        # 还有一个直接的方式就是清空 monitor 设置文件内容
        cmd::run_cmd_with_history sed -i "'s%^\(source = conf.d/workspace.conf\)%# \\1%g'" "$config_filepath"
        if [ "$?" -ne "${SHELL_TRUE}" ]; then
            lerror "hyprland setting workspace failed"
            return "$SHELL_FALSE"
        fi
    fi
    linfo "hyprland setting workspace success"
    return "${SHELL_TRUE}"
}

function hyprland::settings::hypridle() {
    local config_filepath
    config_filepath="$(hyprland::settings::base_config_filepath)"
    if os::is_vm; then
        # 反复安装也不会有问题
        # 还有一个直接的方式就是清空 monitor 设置文件内容
        cmd::run_cmd_with_history sed -i "'s%^\(exec-once = hypridle\)%# \\1%g'" "$config_filepath"
        if [ "$?" -ne "${SHELL_TRUE}" ]; then
            lerror "hyprland setting hypridle failed"
            return "$SHELL_FALSE"
        fi
    fi
    linfo "hyprland setting hypridle success"
    return "${SHELL_TRUE}"
}

function hyprland::plugins::clean() {
    local config_filepath
    config_filepath="$(hyprland::settings::hyprland_config_filepath)"

    if ! hyprctl::is_can_connect; then
        println_warn "${PM_APP_NAME}: can not connect to hyprland, do not clean plugin"
        return "${SHELL_TRUE}"
    fi

    linfo "start clean hyprland plugins"

    # 修改配置文件
    cmd::run_cmd_with_history sed -i "'s%^\(source = conf.d/hycov.conf\)%# \\1%g'" "$config_filepath" || return "${SHELL_FALSE}"

    # 删除插件
    local repository
    local temp_str
    local item
    temp_str=$(hyprpm list | grep -o -E "Repository [^:]+" | awk '{print $2}')
    array::readarray repository < <(echo "${temp_str}")

    for item in "${repository[@]}"; do
        cmd::run_cmd_with_history printf y '|' hyprpm -v remove "${item}" || return "${SHELL_FALSE}"
        linfo "hyprpm remove ${item} success"
    done

    linfo "clean hyprland plugins success"
    return "${SHELL_TRUE}"
}

function hyprland::plugins::install() {
    local config_filepath
    config_filepath="$(hyprland::settings::hyprland_config_filepath)"

    if ! hyprctl::is_can_connect; then
        println_warn "${PM_APP_NAME}: can not connect to hyprland, do not install plugin"
        return "${SHELL_TRUE}"
    fi

    # 先清理
    hyprland::plugins::clean || return "${SHELL_FALSE}"

    local hyprpm_state="$HOME/.local/share/hyprpm/state.toml"
    cmd::run_cmd_with_history rm -f "$hyprpm_state" || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history echo -e '"[state]\ndont_warn_install = true"' '>' "$hyprpm_state" || return "${SHELL_FALSE}"

    # 先更新，安装 hyprland headers
    cmd::run_cmd_with_history hyprpm update -v || return "${SHELL_FALSE}" || return "${SHELL_TRUE}"
    linfo "hyprpm update success"

    # 添加
    cmd::run_cmd_with_history printf "y" '|' hyprpm -v add https://github.com/hyprwm/hyprland-plugins || return "${SHELL_FALSE}"
    linfo "hyprpm add hyprland-plugins plugin success"

    # 添加 hycov
    cmd::run_cmd_with_history printf "y" '|' hyprpm -v add https://github.com/DreamMaoMao/hycov || return "${SHELL_FALSE}"
    linfo "hyprpm add hycov plugin success"
    cmd::run_cmd_with_history hyprpm -v enable hycov || return "${SHELL_FALSE}"
    # 处理hycov插件的设置
    grep -q "hycov.conf" "$config_filepath"
    if [ "$?" -ne "${SHELL_TRUE}" ]; then
        cmd::run_cmd_with_history sed -i "'\$a\\source = conf.d/hycov.conf'" "$config_filepath" || return "${SHELL_FALSE}"
    fi
    linfo "hyprpm enable hycov plugin success"

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
function hyprland::trait::do_install() {
    package_manager::install "$(hyprland::trait::package_manager)" "$(hyprland::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function hyprland::trait::post_install() {
    local config_filepath
    config_filepath="$(hyprland::settings::hyprland_config_filepath)"

    cmd::run_cmd_with_history mkdir -p "${XDG_CONFIG_HOME}" || return "${SHELL_FALSE}"

    # 先备份配置
    cmd::run_cmd_with_history rm -rf "${BUILD_TEMP_DIR}/hypr" || return "${SHELL_FALSE}"
    if [ -e "${XDG_CONFIG_HOME}/hypr" ]; then
        cmd::run_cmd_with_history cp -rf "${XDG_CONFIG_HOME}/hypr" "${BUILD_TEMP_DIR}/hypr" || return "${SHELL_FALSE}"
    fi

    cmd::run_cmd_with_history rm -rf "${XDG_CONFIG_HOME}/hypr" || return "${SHELL_FALSE}"
    cmd::run_cmd_with_history cp -r "${SCRIPT_DIR_c084e0be}/hypr" "${XDG_CONFIG_HOME}" || return "${SHELL_FALSE}"

    # 恢复主要的配置
    if [ -e "${BUILD_TEMP_DIR}/hypr/hyprland.conf" ]; then
        cmd::run_cmd_with_history cp -f "${BUILD_TEMP_DIR}/hypr/hyprland.conf" "${config_filepath}" || return "${SHELL_FALSE}"
    fi

    hyprland::settings::modify_hyprland_config || return "${SHELL_FALSE}"

    hyprland::settings::terminal || return "${SHELL_FALSE}"
    hyprland::settings::file_manager || return "${SHELL_FALSE}"
    hyprland::settings::monitor || return "${SHELL_FALSE}"
    hyprland::settings::workspace || return "${SHELL_FALSE}"
    hyprland::settings::cursors || return "${SHELL_FALSE}"
    hyprland::settings::hypridle || return "${SHELL_FALSE}"
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

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function hyprland::trait::fixme() {
    println_warn "${PM_APP_NAME}: TODO: Detecting real environments to generate monitor configurations"

    hyprland::plugins::install || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function hyprland::trait::unfixme() {
    println_info "${PM_APP_NAME}: start undo fixme..."

    hyprland::plugins::clean || return "${SHELL_FALSE}"

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
    local apps=("custom:fonts" "pacman:polkit-kde-agent")

    # xdg-desktop-portal
    apps+=("pacman:xdg-desktop-portal-hyprland" "pacman:xdg-desktop-portal-gtk")

    # 插件hyprpm需要的
    apps+=("pacman:cpio")

    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function hyprland::trait::features() {
    local apps=()

    # 输入法
    apps+=("custom:fcitx5")

    # 文件浏览器
    apps+=("custom:yazi")

    # 程序启动器
    apps+=("custom:rofi")

    # 通知
    apps+=("custom:swaync")

    # 状态栏
    apps+=("custom:anyrun" "custom:ags")

    # wallust 根据图片生成颜色主题
    apps+=("custom:wallust")
    # 壁纸
    # bing 壁纸需要解析json字符串
    apps+=("pacman:wget" "pacman:go-yq" "pacman:hyprpaper")

    # 锁屏
    apps+=("pacman:hyprlock")

    # 截图需要的
    apps+=("pacman:grim" "pacman:slurp" "flatpak:org.ksnip.ksnip")

    # 邮箱
    apps+=("pacman:thunderbird" "pacman:thunderbird-i18n-zh-cn")

    # 翻译软件
    apps+=("custom:pot")

    # 取色软件
    apps+=("yay:hyprpicker")

    # 终端软件
    apps+=("custom:wezterm")
    if os::is_vm; then
        apps+=("pacman:terminator")
    fi

    # logout
    apps+=("custom:wlogout")

    # hypridle 会用到 brightnessctl
    apps+=("pacman:brightnessctl" "pacman:hypridle")

    # 音乐舞动程序
    apps+=("custom:cavasik")

    array::print apps
    return "${SHELL_TRUE}"
}

function hyprland::trait::main() {
    return "${SHELL_TRUE}"
}

hyprland::trait::main
