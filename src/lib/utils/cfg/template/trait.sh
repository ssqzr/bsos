#!/bin/bash

# 接口命名参考 python 的 dict 和 array 接口命名

if [ -n "${SCRIPT_DIR_7396f210}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_7396f210="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_7396f210}/../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_7396f210}/../../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_7396f210}/../../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_7396f210}/../../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_7396f210}/../../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_7396f210}/../../log/log.sh"

declare CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT="#"
declare CFG_TRAIT_TEMPLATE_DEFAULT_SEPARATOR=","

######################################## map 相关的接口 ########################################

# 获取指定 path 下的值
# 说明：
#   1. path 不存在的时候，表示失败
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
# 位置参数：
#   path                            string              map 上级的路径
#   data                            string              配置数据
# 标准输出： 获取的值
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::trait::template::map::get() {
    local path
    local data

    local comment="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}"

    local value=""
    local param

    for param in "$@"; do
        case "$param" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}" --option="$param" comment || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path ]; then
                path="$param"
                continue
            fi

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path}, comment=${comment}"
    ldebug "param data=${data}"

    echo "${value}"
    return "${SHELL_TRUE}"
}

# 判断 map 中是否存在指定 path
# 说明：
#   无
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
# 位置参数：
#   path                            string              map 上级的路径
#   data                            string              配置数据
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示存在
#   ${SHELL_FALSE} 表示不存在
function cfg::trait::template::map::is_exists() {
    local path
    local data

    local comment="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}"
    local param

    for param in "$@"; do
        case "$param" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}" --option="$param" comment || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path ]; then
                path="$param"
                continue
            fi

            if [ ! -v data ]; then
                data="$param"
                continue
            fi

            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path}, comment=${comment}"
    ldebug "param data=${data}"

    return "${SHELL_TRUE}"
}

# 更新指定 path 下的值
# 说明：
#   1. 不存在 path 的时候，会创建 path
#   2. 存在 path 的时候，会更新 path 的 value
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
# 位置参数：
#   path                            string              map 上级的路径
#   value                           string              更新的值
#   data                            string 引用          配置数据，修改后的配置数据也会存放在这里
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::template::map::update() {
    # FIXME: 重新生成 uuid 。 生成命令： uuidgen |awk -F '-' '{print $1}'
    local path_fd38c827
    local value_fd38c827
    local -n data_fd38c827

    local comment_fd38c827="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}"
    local param_fd38c827

    for param_fd38c827 in "$@"; do
        case "$param_fd38c827" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}" --option="$param_fd38c827" comment_fd38c827 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_fd38c827"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_fd38c827 ]; then
                path_fd38c827="$param_fd38c827"
                continue
            fi

            if [ ! -v value_fd38c827 ]; then
                value_fd38c827="$param_fd38c827"
                continue
            fi

            if [ ! -R data_fd38c827 ]; then
                data_fd38c827="$param_fd38c827"
                continue
            fi

            lerror "invalid param: $param_fd38c827"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_fd38c827 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v value_fd38c827 ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_fd38c827 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_fd38c827}, value=${value_fd38c827}, comment=${comment_fd38c827}"
    ldebug "param data ref=${!data_fd38c827}, data=${data_fd38c827}"

    return "${SHELL_TRUE}"
}

# 删除指定 path 并返回它的值
# 说明：
#   1. 不存在 path 的时候，认为失败
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
# 位置参数：
#   path                            string              map 上级的路径
#   value                           string 引用         pop 的值
#   data                            string 引用         配置数据，修改后的配置数据也会存放在这里
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::template::map::pop() {
    # FIXME: 重新生成 uuid 。 生成命令： uuidgen |awk -F '-' '{print $1}'
    local path_fc1aecc2
    # shellcheck disable=SC2034
    local -n value_fc1aecc2
    local -n data_fc1aecc2

    local comment_fc1aecc2="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}"
    local param_fc1aecc2

    for param_fc1aecc2 in "$@"; do
        case "$param_fc1aecc2" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}" --option="$param_fc1aecc2" comment_fc1aecc2 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_fc1aecc2"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_fc1aecc2 ]; then
                path_fc1aecc2="$param_fc1aecc2"
                continue
            fi

            if [ ! -R value_fc1aecc2 ]; then
                value_fc1aecc2="$param_fc1aecc2"
                continue
            fi

            if [ ! -R data_fc1aecc2 ]; then
                data_fc1aecc2="$param_fc1aecc2"
                continue
            fi

            lerror "invalid param: $param_fc1aecc2"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_fc1aecc2 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R value_fc1aecc2 ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_fc1aecc2 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_fc1aecc2}, comment=${comment_fc1aecc2}"
    ldebug "param data=${data_fc1aecc2}"

    return "${SHELL_TRUE}"
}

######################################## array 相关的接口 ########################################

# 获取指定 path 的数组的所有元素
# 说明：
#   1. 不存在 path 的时候，认为成功，返回空数组
# 可选参数：
#   --separator=[,]                 string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','。
#   --comment=COMMENT               string              指定注释的字符串
# 位置参数：
#   all                             数组引用              存放所有元素的数组的引用
#   path                            string              map 上级的路径
#   data                            string              配置数据
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::template::array::all() {
    # FIXME: 重新生成 uuid 。 生成命令： uuidgen |awk -F '-' '{print $1}'
    local -n all_584e4812
    local path_584e4812
    local data_584e4812

    local param_584e4812
    local separator_584e4812="${CFG_TRAIT_TEMPLATE_DEFAULT_SEPARATOR}"
    local comment_584e4812="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}"

    for param_584e4812 in "$@"; do
        case "$param_584e4812" in
        --separator=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_SEPARATOR}" --option="$param_584e4812" separator_584e4812 || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}" --option="$param_584e4812" comment_584e4812 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_584e4812"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R all_584e4812 ]; then
                all_584e4812="$param_584e4812"
                continue
            fi

            if [ ! -v path_584e4812 ]; then
                path_584e4812="$param_584e4812"
                continue
            fi

            if [ ! -v data_584e4812 ]; then
                data_584e4812="$param_584e4812"
                continue
            fi

            lerror "invalid param: $param_584e4812"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R all_584e4812 ]; then
        lerror "param all is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v path_584e4812 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data_584e4812 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param all=${!all_584e4812} path=${path_584e4812},  separator=${separator_584e4812}, comment=${comment_584e4812}"
    ldebug "param data=${data_584e4812}"

    return "${SHELL_TRUE}"
}

# 更新指定 path 下所有列表元素
# 说明：
# 可选参数：
#   --separator=[,]                 string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','。
#   --comment=COMMENT               string              指定注释的字符串
# 位置参数：
#   path                            string              map 上级的路径
#   new                             数组引用              更新的列表引用
#   data                            string 引用          配置数据，修改后的配置数据也会存放在这里
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::template::array::update_all() {
    # FIXME: 重新生成 uuid 。 生成命令： uuidgen |awk -F '-' '{print $1}'
    local path_ba4851ea
    local -n new_ba4851ea
    local -n data_ba4851ea

    local param_ba4851ea
    local separator_ba4851ea="${CFG_TRAIT_TEMPLATE_DEFAULT_SEPARATOR}"
    local comment_ba4851ea="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}"

    for param_ba4851ea in "$@"; do
        case "$param_ba4851ea" in
        --separator=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_SEPARATOR}" --option="$param_ba4851ea" separator_ba4851ea || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_TEMPLATE_DEFAULT_COMMENT}" --option="$param_ba4851ea" comment_ba4851ea || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_ba4851ea"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v path_ba4851ea ]; then
                path_ba4851ea="$param_ba4851ea"
                continue
            fi

            if [ ! -R new_ba4851ea ]; then
                new_ba4851ea="$param_ba4851ea"
                continue
            fi

            if [ ! -R data_ba4851ea ]; then
                data_ba4851ea="$param_ba4851ea"
                continue
            fi

            lerror "invalid param: $param_ba4851ea"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_ba4851ea ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R new_ba4851ea ]; then
        lerror "param new is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_ba4851ea ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_ba4851ea}, new=${!new_ba4851ea}, separator=${separator_ba4851ea}, comment=${comment_ba4851ea}"
    ldebug "param data=${data_ba4851ea}"

    return "${SHELL_TRUE}"
}

######################################## map 测试代码 ########################################
######################################## array 测试代码 ########################################
