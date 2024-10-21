#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_6e66a585="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function gnome_keyring::trait::package_manager() {
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function gnome_keyring::trait::package_name() {
    # https://rtfm.co.ua/en/what-is-linux-keyring-gnome-keyring-secret-service-and-d-bus/
    # https://wiki.archlinuxcn.org/wiki/GNOME/Keyring
    echo "gnome-keyring"
}

# 简短的描述信息，查看包的信息的时候会显示
function gnome_keyring::trait::description() {
    package_manager::package_description "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function gnome_keyring::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function gnome_keyring::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function gnome_keyring::trait::install() {
    package_manager::install "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function gnome_keyring::trait::post_install() {
    # https://wiki.archlinuxcn.org/wiki/GNOME/Keyring#%E7%94%A8PAM%E7%9A%84%E6%96%B9%E6%B3%95
    # https://stackoverflow.com/questions/37909388/append-line-after-last-match-with-sed
    # 本来想使用sed解决的，但是网上给的方案都没有说明，出现问题也不好排查
    # cmd::run_cmd_with_history -- sudo sed -i -e "'1h;1!H;$!d;x;s/.*auth [^\n]*/&\nauth optional pam_gnome_keyring.so/'" -e "'1h;1!H;$!d;x;s/.*session [^\n]*/&\nsession optional pam_gnome_keyring.so auto_start/'" /etc/pam.d/login || return "${SHELL_FALSE}"
    local tmp_pam_login_file="${BUILD_TEMP_DIR}/login.tmp"

    local line
    local found=""

    while read -r line; do
        # 空行和注释行直接处理
        if [ -z "${line}" ]; then
            echo "${line}" >>"${tmp_pam_login_file}"
            continue
        fi
        if [[ "${line}" == "#"* ]]; then
            echo "${line}" >>"${tmp_pam_login_file}"
            continue
        fi

        if [[ "${found}" == "auth"* ]] && [[ "${line}" != "auth"* ]]; then
            echo "auth optional pam_gnome_keyring.so" >>"${tmp_pam_login_file}"
        fi

        if [[ "${found}" == "session"* ]] && [[ "${line}" != "session"* ]]; then
            echo "session optional pam_gnome_keyring.so auto_start" >>"${tmp_pam_login_file}"
        fi

        found="${line}"
        echo "${line}" >>"${tmp_pam_login_file}"

    done </etc/pam.d/login

    cmd::run_cmd_with_history -- sudo cp -f "${tmp_pam_login_file}" /etc/pam.d/login || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function gnome_keyring::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function gnome_keyring::trait::uninstall() {
    package_manager::uninstall "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function gnome_keyring::trait::post_uninstall() {
    cmd::run_cmd_with_history -- sudo sed -i -e "'/pam_gnome_keyring.so/d'" /etc/pam.d/login || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 更新应用
# 绝大部分应用都是通过包管理器进行更新
# 但是有部分自己安装的应用需要手动更新，比如通过源码进行安装的
# 说明：
# - 更新的操作和版本无关，也就是说所有版本更新方法都一样
# - 更新的操作不应该做配置转换之类的操作，这个应该是应用需要处理的
# - 更新的指责和包管理器类似，只负责更新
function gnome_keyring::trait::upgrade() {
    package_manager::upgrade "$(gnome_keyring::trait::package_manager)" "$(gnome_keyring::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
# NOTE: 注意重复安装是否会覆盖fixme做的修改
function gnome_keyring::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function gnome_keyring::trait::unfixme() {
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function gnome_keyring::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # "pacman:vim"
    # "yay:vim"
    # "pamac:vim"
    # "custom:vim"   自定义，也就是通过本脚本进行安装
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function gnome_keyring::trait::features() {
    # "pacman:libsecret" 预装在系统，不需要额外安装。
    # pacman 也依赖 libsecret，所以不能填写依赖，不然卸载的时候会因为依赖关系一起卸载pacman，pacman因为HoldPkg配置是不允许卸载的
    # 导致卸载 libsecret 失败
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function gnome_keyring::trait::main() {
    return "$SHELL_TRUE"
}

gnome_keyring::trait::main
