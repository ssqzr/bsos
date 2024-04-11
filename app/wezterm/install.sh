#!/bin/bash

# NOTE: 这个脚本负责安装的框架流程，如果模板有变动，所有模块的脚本都会同步修改
# 所以实际的安装功能单独额外的一个 trait.sh 的脚本，这个脚本除非自己修改，自动生成代码不会修改它
# 为什么每个模块安装都复制一个这个脚本，而不是放在一个公共的地方共同使用呢？
# 1. 不能 source 进行引入，不然会有函数名冲突的问题。所以需要一个独立的安装脚本，后面发现冲突是可以解决的，可以在函数名前面加模块名，比如app::test()，模块名可以通过自动生成脚本自动添加
# 2. 既然是独立的安装脚本，那么模块的安装功能也尽可能完整、独立。最好是不需要额外的依赖就可以运行
# 3. 如果采用 source 引入的方式，那么就需要引入太多的模块了，并且每次添加一个模块都需要source一次，也就需要修改一次这个脚本

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_69fc9612="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 因为 source 需要用到路径，所以这个只能在最开始判断
if [ -z "${SRC_ROOT_DIR}" ]; then
    printf "\033[1;31m%s\033[0m" "env SRC_ROOT_DIR is not set\n"
    # 还没有 source，所以$SHELL_FALSE还不可用
    exit 1
fi

# shellcheck source=/dev/null
source "${SRC_ROOT_DIR}/lib/utils/all.sh" || exit 1
# shellcheck source=/dev/null
source "${SRC_ROOT_DIR}/lib/package_manager/pacman.sh" || exit 1

# NOTE: 一些全局的变量必须已经初始化，后面会用到
# NOTE: 可以用到的环境变量如下：
# 1. HOME 用户主目录
# 1. SRC_ROOT_DIR 代码的根目录
# 2. PM_APP_NAME 模板
# 3. BUILD_TEMP_DIR 安装流程的临时构建根目录
# 4. XDG_CONFIG_HOME 用户配置文件的根目录
# 5. ROOT_PASSWORD root用户的密码
function wezterm::_env() {

    if [ -z "$HOME" ]; then
        println_error "env HOME is not set"
        return "$SHELL_FALSE"
    fi

    if [ -z "$XDG_CONFIG_HOME" ]; then
        export XDG_CONFIG_HOME="$HOME/.config"
    fi

    if [ -z "$ROOT_PASSWORD" ]; then
        println_error "env ROOT_PASSWORD is not set"
        return "$SHELL_FALSE"
    fi

    # export PM_APP_NAME
    local name
    name="$(basename "${SCRIPT_DIR_69fc9612}")"
    export PM_APP_NAME="custom:${name}"

    # export BUILD_TEMP_DIR
    if [ -z "${BUILD_ROOT_DIR}" ]; then
        println_error "env BUILD_ROOT_DIR is not set"
        return "$SHELL_FALSE"
    fi
    # 路径中包含特殊字符可能导致一些问题，例如：
    # 安装yay时，报错：go: GOPATH entry is relative; must be absolute path: "yay/yay/src/gopath".
    # 但是真实的路径是 "custom:yay/yay/src/gopath"，解析有问题
    # 所以使用没有特殊字符的路径
    export BUILD_TEMP_DIR="${BUILD_ROOT_DIR}/${PM_APP_NAME//:/_}"
    unset BUILD_ROOT_DIR

    return "$SHELL_TRUE"
}

function wezterm::_clean_build() {
    file::delete_dir_safe "${BUILD_TEMP_DIR}" || return "$SHELL_FALSE"
    file::create_dir_recursive "${BUILD_TEMP_DIR}" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 安装需要保证如下几点
# 1. 可以反复执行安装，不会冲突
# 2. 安装失败需要负责回滚，回滚直接调用卸载函数
function wezterm::_install() {

    linfo "clean app(${PM_APP_NAME}) build env..."
    wezterm::_clean_build || return "$SHELL_FALSE"
    linfo "clean app(${PM_APP_NAME}) build env success."

    linfo "pre install app(${PM_APP_NAME})..."
    wezterm::trait::pre_install || return "$SHELL_FALSE"
    linfo "pre install app(${PM_APP_NAME}) success."

    linfo "do install app(${PM_APP_NAME})..."
    wezterm::trait::do_install || return "$SHELL_FALSE"
    linfo "do install app(${PM_APP_NAME}) success."

    linfo "post install app(${PM_APP_NAME})..."
    wezterm::trait::post_install || return "$SHELL_FALSE"
    linfo "post install app(${PM_APP_NAME}) success."

    linfo "install app(${PM_APP_NAME}) success."
    return "${SHELL_TRUE}"
}

function wezterm::install() {
    wezterm::_install
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror "install app(${PM_APP_NAME}) failed"
        linfo "clean app(${PM_APP_NAME})..."
        wezterm::uninstall

        return "$SHELL_FALSE"
    fi

    return "${SHELL_TRUE}"
}

# 卸载需要保证如下几点
# 1. 承担清理的工作，安装在任何一个步骤失败后都需要保证清理工作
# 2. 可以反复执行
function wezterm::_uninstall() {
    linfo "pre uninstall app(${PM_APP_NAME})..."
    wezterm::trait::pre_uninstall || return "$SHELL_FALSE"
    linfo "pre uninstall app(${PM_APP_NAME}) success."

    linfo "do uninstall app(${PM_APP_NAME})..."
    wezterm::trait::do_uninstall || return "$SHELL_FALSE"
    linfo "do uninstall app(${PM_APP_NAME}) success."

    linfo "post uninstall app(${PM_APP_NAME})..."
    wezterm::trait::post_uninstall || return "$SHELL_FALSE"
    linfo "post uninstall app(${PM_APP_NAME}) success."

    linfo "uninstall app(${PM_APP_NAME}) success."
    return "${SHELL_TRUE}"
}

function wezterm::uninstall() {
    wezterm::_uninstall
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror "uninstall app(${PM_APP_NAME}) failed"

        return "$SHELL_FALSE"
    fi

    return "${SHELL_TRUE}"
}

function wezterm::package_name() {
    wezterm::trait::package_name
}

function wezterm::description() {
    wezterm::trait::description
}

function wezterm::dependencies() {
    wezterm::trait::dependencies
}

function wezterm::features() {
    wezterm::trait::features
}

function wezterm::install_guide() {
    wezterm::trait::install_guide
}

function wezterm::finally() {
    wezterm::trait::finally
}

function wezterm::main() {

    wezterm::_env || return 1

    # shellcheck source=/dev/null
    source "${SCRIPT_DIR_69fc9612}/trait.sh" || return "$SHELL_FALSE"

    local subcommand="$1"
    if [ -z "${subcommand}" ]; then
        lerrror "param subcommand is empty"
        return "$SHELL_FALSE"
    fi

    case "${subcommand}" in

    "install")
        wezterm::install
        return $?
        ;;

    "uninstall")
        wezterm::uninstall
        return $?
        ;;

    "package_name")
        wezterm::package_name
        return $?
        ;;

    "description")
        wezterm::description
        return $?
        ;;

    "dependencies")
        wezterm::dependencies
        return $?
        ;;

    "features")
        wezterm::features
        return $?
        ;;

    "install_guide")
        wezterm::install_guide
        return $?
        ;;

    "finally")
        wezterm::finally
        return $?
        ;;
    *)
        lerror "unknown cmd: $1"
        return $?
        ;;
    esac

}

wezterm::main "$@"
