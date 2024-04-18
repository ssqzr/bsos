#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_b3956090="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"


# 指定使用的包管理器
function ryujinx::trait::package_manager() {
    echo "flatpak"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function ryujinx::trait::package_name() {
    echo "org.ryujinx.Ryujinx"
}

# 简短的描述信息，查看包的信息的时候会显示
function ryujinx::trait::description() {
    package_manager::package_description "$(ryujinx::trait::package_manager)" "$(ryujinx::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function ryujinx::trait::install_guide() {
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function ryujinx::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function ryujinx::trait::do_install() {
    package_manager::install "$(ryujinx::trait::package_manager)" "$(ryujinx::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function ryujinx::trait::post_install() {
    # local ryujinx_config_dir="${HOME}/.var/app/org.ryujinx.Ryujinx/config/Ryujinx"

    # local firmware_filepath="${BUILD_TEMP_DIR}/Firmware.zip"
    # cmd::run_cmd_with_history curl -k -L "https://archive.org/download/nintendo-switch-global-firmwares/Firmware%2017.0.0.zip" -o "$firmware_filepath" || return "${SHELL_FALSE}"

    # cmd::run_cmd_with_history 7z x "$firmware_filepath" -o"${BUILD_TEMP_DIR}/Firmware" || return "${SHELL_FALSE}"
    # cmd::run_cmd_with_history find "${BUILD_TEMP_DIR}/Firmware" -mindepth 1 -maxdepth 1 -exec cp -rf {} "${ryujinx_config_dir}/" "\;" || return "${SHELL_FALSE}"

    cmd::run_cmd_with_history echo "vm.max_map_count=524288" "|" sudo tee "/etc/sysctl.d/ryujinx.conf" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function ryujinx::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function ryujinx::trait::do_uninstall() {
    package_manager::uninstall "$(ryujinx::trait::package_manager)" "$(ryujinx::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function ryujinx::trait::post_uninstall() {
    # cmd::run_cmd_with_history rm -rf "${HOME}/.var/app/org.ryujinx.Ryujinx"
    cmd::run_cmd_with_history sudo rm -f "/etc/sysctl.d/ryujinx.conf" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 全部安装完成后的操作
function ryujinx::trait::finally() {
    # firmware 文件太大了，下载很耗时。没有一个免费的支持直链下载的网站存储 firmware
    println_info "${PM_APP_NAME}: you should install firmware manually."
    # keys 文件不大，但是需要和firmware配套，就不自动处理了
    println_info "${PM_APP_NAME}: you should install keys manually."
    println_info "${PM_APP_NAME}: view https://theprodkeys.com/ to get more infomation."

    println_info "${PM_APP_NAME}: you should add games manually."
    println_info "${PM_APP_NAME}: you should add games update and DLC manually."
    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function ryujinx::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # pacman:vim
    # yay:vim
    # pamac:vim
    # custom:vim   自定义，也就是通过本脚本进行安装
    local apps=("default:p7zip")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function ryujinx::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function ryujinx::trait::main() {
    return "$SHELL_TRUE"
}

ryujinx::trait::main
