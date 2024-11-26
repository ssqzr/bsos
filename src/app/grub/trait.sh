#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_c49d4082="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

function grub::theme::unset() {
    local theme="$1"
    if [ -z "${theme}" ]; then
        lerror "param theme is empty"
        return "$SHELL_FALSE"
    fi
    local grub_default_config_file="/etc/default/grub"
    local grub_theme_dir="/boot/grub/themes"

    # 删除我们设置的 GRUB_THEME 字段
    cmd::run_cmd_with_history --sudo -- sed -i "'/^GRUB_THEME=.*${theme}.*/d'" "'$grub_default_config_file'" || return "${SHELL_FALSE}"

    # 还原以前的 GRUB_THEME
    cmd::run_cmd_with_history --sudo -- sed -i "'s/^# __backup__flag__ GRUB_THEME=\\(.*\\)/GRUB_THEME=\\1/g'" "'$grub_default_config_file'" || return "${SHELL_FALSE}"

    # 删除我们设置的 GRUB_GFXMODE 字段
    cmd::run_cmd_with_history --sudo -- sed -i "'/^GRUB_GFXMODE=1920x1080,auto/d'" "'$grub_default_config_file'" || return "${SHELL_FALSE}"
    # 还原以前的 GRUB_GFXMODE
    cmd::run_cmd_with_history --sudo -- sed -i "'s/^# __backup__flag__ GRUB_GFXMODE=\\(.*\\)/GRUB_GFXMODE=\\1/g'" "'$grub_default_config_file'" || return "${SHELL_FALSE}"

    fs::directory::safe_delete --sudo "${grub_theme_dir}/${theme}" || return "${SHELL_FALSE}"

    return "$SHELL_TRUE"
}

function grub::theme::set() {
    local theme="$1"
    if [ -z "${theme}" ]; then
        lerror "param theme is empty"
        return "$SHELL_FALSE"
    fi
    local grub_default_config_file="/etc/default/grub"
    local grub_theme_dir="/boot/grub/themes"

    grub::theme::unset "${theme}" || return "${SHELL_FALSE}"

    fs::directory::copy --sudo --force "/usr/share/grub/themes/${theme}" "${grub_theme_dir}/${theme}" || return "${SHELL_FALSE}"
    # 备份 GRUB_THEME 字段
    cmd::run_cmd_with_history --sudo -- sed -i "'s/^GRUB_THEME=\\(.*\\)/# __backup__flag__ GRUB_THEME=\\1/g'" "'${grub_default_config_file}'" || return "${SHELL_FALSE}"
    # 设置 GRUB_THEME 字段
    cmd::run_cmd_with_history --sudo -- echo "'GRUB_THEME=${grub_theme_dir}/${theme}/theme.txt'" ">>" "${grub_default_config_file}" || return "${SHELL_FALSE}"

    # 设置分辨率，默认的分辨率可能不对
    # 备份 GRUB_GFXMODE 字段
    cmd::run_cmd_with_history --sudo -- sed -i "'s/^GRUB_GFXMODE=\\(.*\\)/# __backup__flag__ GRUB_GFXMODE=\\1/g'" "'${grub_default_config_file}'" || return "${SHELL_FALSE}"
    # 设置 GRUB_GFXMODE 字段
    cmd::run_cmd_with_history --sudo -- echo "'GRUB_GFXMODE=1920x1080,auto'" ">>" "${grub_default_config_file}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

function grub::mkconfig() {
    local grub_config_file="/boot/grub/grub.cfg"
    cmd::run_cmd_with_history --sudo -- grub-mkconfig -o "$grub_config_file" || return "${SHELL_FALSE}"
    return "$SHELL_TRUE"
}

# 指定使用的包管理器
function grub::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function grub::trait::package_name() {
    echo "grub"
}

# 简短的描述信息，查看包的信息的时候会显示
function grub::trait::description() {
    package_manager::package_description "$(grub::trait::package_manager)" "$(grub::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function grub::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function grub::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function grub::trait::do_install() {
    # 安装系统已经安装了
    # package_manager::install "$(grub::trait::package_manager)" "$(grub::trait::package_name)" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function grub::trait::post_install() {

    cmd::run_cmd_with_history --sudo -- sed -i "'s/^#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/g'" "/etc/default/grub" || return "${SHELL_FALSE}"

    grub::theme::set "whitesur-whitesur-1080p" || return "${SHELL_FALSE}"

    grub::mkconfig || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function grub::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function grub::trait::do_uninstall() {
    # 不卸载，卸载系统就引导不了了
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function grub::trait::post_uninstall() {
    cmd::run_cmd_with_history --sudo -- sed -i "'s/^GRUB_DISABLE_OS_PROBER/#GRUB_DISABLE_OS_PROBER/g'" "/etc/default/grub" || return "${SHELL_FALSE}"
    grub::theme::unset "whitesur-whitesur-1080p" || return "${SHELL_FALSE}"
    grub::mkconfig || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function grub::trait::upgrade() {
    package_manager::upgrade "$(grub::trait::package_manager)" "$(grub::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function grub::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function grub::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function grub::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()

    apps+=("pacman:os-prober")

    # 主题
    apps+=("yay:grub-theme-whitesur-whitesur-1080p-git")

    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function grub::trait::features() {
    local apps=()

    array::print apps
    return "${SHELL_TRUE}"
}

function grub::trait::main() {
    return "$SHELL_TRUE"
}

grub::trait::main
