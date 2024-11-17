#!/bin/bash

# 接口命名参考 python 的 dict 和 array 接口命名

if [ -n "${SCRIPT_DIR_18b3f205}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_18b3f205="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_18b3f205}/../../utest.sh"

# json 默认不支持注释，但是也有支持注释的 JSON 格式
# 目前这个没有用到
declare CFG_TRAIT_JSON_DEFAULT_COMMENT=""
# 数组的分割副
declare CFG_TRAIT_JSON_DEFAULT_SEPARATOR=","
# 缩进等级
declare CFG_TRAIT_JSON_DEFAULT_INDENT=4

######################################## map 相关的接口 ########################################

# 获取指定 path 下的值
# 说明：
#   1. path 不存在的时候，表示失败
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
#   --indent=INDENT                 int                 指定缩进的个数
# 位置参数：
#   path                            string              map 上级的路径
#   data                            string              配置数据
# 标准输出： 获取的值
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::trait::json::map::get() {
    local path
    local data

    local comment="${CFG_TRAIT_JSON_DEFAULT_COMMENT}"

    local value=""
    local param

    for param in "$@"; do
        case "$param" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_COMMENT}" --option="$param" comment || return "${SHELL_FALSE}"
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

    value=$(echo "$data" | yq "${path}") || return "${SHELL_FALSE}"

    if string::is_equal "${value}" "null"; then
        lerror "path is not exists. path=${path}, value=${value}"
        return "$SHELL_FALSE"
    fi

    echo "${value}"
    return "${SHELL_TRUE}"
}

# 判断 map 中是否存在指定 path
# 说明：
#   无
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
#   --indent=INDENT                 int                 指定缩进的个数
# 位置参数：
#   path                            string              map 上级的路径
#   data                            string              配置数据
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示存在
#   ${SHELL_FALSE} 表示不存在
function cfg::trait::json::map::is_exists() {
    local path
    local data

    local comment="${CFG_TRAIT_JSON_DEFAULT_COMMENT}"
    local value=""
    local param

    for param in "$@"; do
        case "$param" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_COMMENT}" --option="$param" comment || return "${SHELL_FALSE}"
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

    value=$(echo "$data" | yq "${path}") || return "${SHELL_FALSE}"

    if string::is_equal "${value}" "null"; then
        return "$SHELL_FALSE"
    fi

    return "${SHELL_TRUE}"
}

# 更新指定 path 下的值
# 说明：
#   1. 不存在 path 的时候，会创建 path
#   2. 存在 path 的时候，会更新 path 的 value
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
#   --indent=INDENT                 int                 指定缩进的个数
# 位置参数：
#   path                            string              map 上级的路径
#   value                           string              更新的值
#   data                            string 引用          配置数据，修改后的配置数据也会存放在这里
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::json::map::update() {
    local path_fd649aae
    local value_fd649aae
    local -n data_fd649aae

    local comment_fd649aae="${CFG_TRAIT_JSON_DEFAULT_COMMENT}"
    local indent_fd649aae="${CFG_TRAIT_JSON_DEFAULT_INDENT}"
    local param_fd649aae

    local temp_fd649aae

    for param_fd649aae in "$@"; do
        case "$param_fd649aae" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_COMMENT}" --option="$param_fd649aae" comment_fd649aae || return "${SHELL_FALSE}"
            ;;
        --indent=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_INDENT}" --option="$param_fd649aae" indent_fd649aae || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_fd649aae"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_fd649aae ]; then
                path_fd649aae="$param_fd649aae"
                continue
            fi

            if [ ! -v value_fd649aae ]; then
                value_fd649aae="$param_fd649aae"
                continue
            fi

            if [ ! -R data_fd649aae ]; then
                data_fd649aae="$param_fd649aae"
                continue
            fi

            lerror "invalid param: $param_fd649aae"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_fd649aae ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v value_fd649aae ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_fd649aae ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_fd649aae}, value=${value_fd649aae}, comment=${comment_fd649aae}"
    ldebug "param data ref=${!data_fd649aae}, data=${data_fd649aae}"

    temp_fd649aae=$(echo "$data_fd649aae" | VAL="${value_fd649aae}" yq -o j -I "${indent_fd649aae}" "${path_fd649aae} = strenv(VAL)")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "set map value failed, path=${path_fd649aae}, value=${value_fd649aae}, err=${temp_fd649aae}"
        return "$SHELL_FALSE"
    fi

    data_fd649aae="${temp_fd649aae}"

    linfo "set map value success, path=${path_fd649aae}, value=${value_fd649aae}"

    return "${SHELL_TRUE}"
}

# 删除指定 path 并返回它的值
# 说明：
#   1. 不存在 path 的时候，认为失败
# 可选参数：
#   --comment=COMMENT               string              指定注释的字符串
#   --indent=INDENT                 int                 指定缩进的个数
# 位置参数：
#   path                            string              map 上级的路径
#   value                           string 引用         pop 的值
#   data                            string 引用         配置数据，修改后的配置数据也会存放在这里
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::json::map::pop() {
    local path_73cdb471
    # shellcheck disable=SC2034
    local -n value_73cdb471
    local -n data_73cdb471

    local comment_73cdb471="${CFG_TRAIT_JSON_DEFAULT_COMMENT}"
    local indent_73cdb471="${CFG_TRAIT_JSON_DEFAULT_INDENT}"
    local param_73cdb471

    local temp_73cdb471

    for param_73cdb471 in "$@"; do
        case "$param_73cdb471" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_COMMENT}" --option="$param_73cdb471" comment_73cdb471 || return "${SHELL_FALSE}"
            ;;
        --indent=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_INDENT}" --option="$param_73cdb471" indent_73cdb471 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_73cdb471"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_73cdb471 ]; then
                path_73cdb471="$param_73cdb471"
                continue
            fi

            if [ ! -R value_73cdb471 ]; then
                value_73cdb471="$param_73cdb471"
                continue
            fi

            if [ ! -R data_73cdb471 ]; then
                data_73cdb471="$param_73cdb471"
                continue
            fi

            lerror "invalid param: $param_73cdb471"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_73cdb471 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R value_73cdb471 ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_73cdb471 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_73cdb471}, comment=${comment_73cdb471}"
    ldebug "param data=${data_73cdb471}"

    cfg::trait::json::map::is_exists "${path_73cdb471}" "${data_73cdb471}"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "pop failed, path not exists, path=${path_73cdb471}"
        return "${SHELL_FALSE}"
    fi

    value_73cdb471=$(cfg::trait::json::map::get "${path_73cdb471}" "${data_73cdb471}") || return "${SHELL_FALSE}"

    temp_73cdb471=$(echo "$data_73cdb471" | yq -o j -I "${indent_73cdb471}" "del(${path_73cdb471})")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "pop map key failed, path=${path_73cdb471}, value=${value_73cdb471}, err=${temp_73cdb471}"
        return "$SHELL_FALSE"
    fi

    data_73cdb471="${temp_73cdb471}"

    linfo "set map value success, path=${path_73cdb471}, pop value=${value_73cdb471}"

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
function cfg::trait::json::array::all() {
    local -n all_36823607
    local path_36823607
    local data_36823607

    local param_36823607
    local separator_36823607="${CFG_TRAIT_JSON_DEFAULT_SEPARATOR}"
    local comment_36823607="${CFG_TRAIT_JSON_DEFAULT_COMMENT}"

    local temp_36823607

    for param_36823607 in "$@"; do
        case "$param_36823607" in
        --separator=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_SEPARATOR}" --option="$param_36823607" separator_36823607 || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_COMMENT}" --option="$param_36823607" comment_36823607 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_36823607"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R all_36823607 ]; then
                all_36823607="$param_36823607"
                continue
            fi

            if [ ! -v path_36823607 ]; then
                path_36823607="$param_36823607"
                continue
            fi

            if [ ! -v data_36823607 ]; then
                data_36823607="$param_36823607"
                continue
            fi

            lerror "invalid param: $param_36823607"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R all_36823607 ]; then
        lerror "param all is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v path_36823607 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data_36823607 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param all=${!all_36823607} path=${path_36823607},  separator=${separator_36823607}, comment=${comment_36823607}"
    ldebug "param data=${data_36823607}"

    temp_36823607=$(echo "${data_36823607}" | yq -o s "${path_36823607}" | awk -F '=' '{print $2}')
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror "get array failed, path=${path_36823607}, err=${temp_36823607}"
        return "${SHELL_FALSE}"
    fi

    if [ "${temp_36823607}" == "null" ]; then
        all_36823607=()
        return "${SHELL_TRUE}"
    fi

    array::readarray all_36823607 <<<"$temp_36823607"

    return "${SHELL_TRUE}"
}

# 更新指定 path 下所有列表元素
# 说明：
# 可选参数：
#   --separator=[,]                 string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','。
#   --comment=COMMENT               string              指定注释的字符串
#   --indent=INDENT                 int                 指定缩进的个数
# 位置参数：
#   path                            string              map 上级的路径
#   new                             数组引用              更新的列表引用
#   data                            string 引用          配置数据，修改后的配置数据也会存放在这里
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 表示更新成功
#   ${SHELL_FALSE} 表示更新失败
function cfg::trait::json::array::update_all() {
    local path_2c318009
    local -n new_2c318009
    local -n data_2c318009

    local param_2c318009
    local separator_2c318009="${CFG_TRAIT_JSON_DEFAULT_SEPARATOR}"
    local comment_2c318009="${CFG_TRAIT_JSON_DEFAULT_COMMENT}"
    local indent_2c318009="${CFG_TRAIT_JSON_DEFAULT_INDENT}"
    local item_2c318009
    local output_2c318009
    local data_copy_2c318009

    for param_2c318009 in "$@"; do
        case "$param_2c318009" in
        --separator=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_SEPARATOR}" --option="$param_2c318009" separator_2c318009 || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_COMMENT}" --option="$param_2c318009" comment_2c318009 || return "${SHELL_FALSE}"
            ;;
        --indent=*)
            parameter::parse_string --default="${CFG_TRAIT_JSON_DEFAULT_INDENT}" --option="$param_2c318009" indent_2c318009 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_2c318009"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v path_2c318009 ]; then
                path_2c318009="$param_2c318009"
                continue
            fi

            if [ ! -R new_2c318009 ]; then
                new_2c318009="$param_2c318009"
                continue
            fi

            if [ ! -R data_2c318009 ]; then
                data_2c318009="$param_2c318009"
                continue
            fi

            lerror "invalid param: $param_2c318009"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_2c318009 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R new_2c318009 ]; then
        lerror "param new is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_2c318009 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_2c318009}, new=${!new_2c318009}, separator=${separator_2c318009}, comment=${comment_2c318009}"
    ldebug "param data=${data_2c318009}"

    data_copy_2c318009="${data_2c318009}"
    if cfg::trait::json::map::is_exists "${path_2c318009}" "${data_copy_2c318009}"; then
        output_2c318009=$(echo "${data_copy_2c318009}" | yq -o j -I "${indent_2c318009}" "${path_2c318009} = []")
        if [ $? -ne "${SHELL_TRUE}" ]; then
            lerror "clear array failed, path=${path_2c318009}, err=${output_2c318009}"
            return "${SHELL_FALSE}"
        fi
        data_copy_2c318009="${output_2c318009}"
    fi

    for item_2c318009 in "${new_2c318009[@]}"; do
        output_2c318009=$(echo "${data_copy_2c318009}" | VAL="${item_2c318009}" yq -o j -I "${indent_2c318009}" "${path_2c318009} += [strenv(VAL)]" 2>&1)
        if [ $? -ne "${SHELL_TRUE}" ]; then
            lerror "array rpush failed, path=${path_2c318009}, value=${item_2c318009}, err=${output_2c318009}"
            return "${SHELL_FALSE}"
        fi
        data_copy_2c318009="${output_2c318009}"
    done

    data_2c318009="${data_copy_2c318009}"

    return "${SHELL_TRUE}"
}

######################################## map 测试代码 ########################################

function TEST::cfg::trait::json::map::get() {
    local data
    local result

    # path 不存在
    data=$'{}'
    result=$(cfg::trait::json::map::get ".name" "${data}")
    utest::assert_fail $?
    utest::assert_equal "${result}" ""

    # path 存在
    data=$'{"name": "xxx"}'
    result=$(cfg::trait::json::map::get ".name" "${data}")
    utest::assert $?
    utest::assert_equal "${result}" "xxx"

}

function TEST::cfg::trait::json::map::is_exists() {
    local data

    # path 不存在
    data=$'{}'
    cfg::trait::json::map::is_exists ".name" "${data}"
    utest::assert_fail $?

    # path 存在
    data=$'{"name": "xxx"}'
    cfg::trait::json::map::is_exists ".name" "${data}"
    utest::assert $?

}

function TEST::cfg::trait::json::map::update() {
    local data

    # path 不存在
    data=$'{}'
    cfg::trait::json::map::update --indent=0 ".name" "xxx" data
    utest::assert $?
    utest::assert_equal "${data}" '{"name":"xxx"}'

    # path 存在
    data=$'{"name": "xxx"}'
    cfg::trait::json::map::update --indent=0 ".name" "yyy" data
    utest::assert $?
    utest::assert_equal "${data}" '{"name":"yyy"}'

    # path 存在，嵌套路径
    data=$'{"person": {"name": "xxx"}}'
    cfg::trait::json::map::update --indent=0 ".person.name" "yyy" data
    utest::assert $?
    utest::assert_equal "${data}" $'{"person":{"name":"yyy"}}'
}

function TEST::cfg::trait::json::map::pop() {
    local data
    local value

    # path 不存在
    data=$'{}'
    cfg::trait::json::map::pop --indent=0 ".name" value data
    utest::assert_fail $?
    utest::assert_equal "${value}" ""
    utest::assert_equal "${data}" $'{}'

    # path 存在
    data=$'{"name": "xxx"}'
    cfg::trait::json::map::pop --indent=0 ".name" value data
    utest::assert $?
    utest::assert_equal "${value}" "xxx"
    utest::assert_equal "${data}" $'{}'

    # path 存在，嵌套路径
    data=$'{"person": {"name": "xxx"}}'
    cfg::trait::json::map::pop --indent=0 ".person.name" value data
    utest::assert $?
    utest::assert_equal "${value}" "xxx"
    utest::assert_equal "${data}" $'{"person":{}}'
}

######################################## array 测试代码 ########################################

function TEST::cfg::trait::json::array::all() {
    local data
    local result

    # path 不存在
    data=$'{}'
    cfg::trait::json::array::all result ".name" "${data}"
    utest::assert $?
    utest::assert_equal "${result[*]}" ""

    # path 存在
    data=$'{"name": ["xxx", "yyy"]}'
    cfg::trait::json::array::all result ".name" "${data}"
    utest::assert $?
    utest::assert_equal "${result[*]}" "xxx yyy"

    # path 存在，嵌套路径
    data=$'{"person": {"name": ["xxx", "yyy"]}}'
    cfg::trait::json::array::all result ".person.name" "${data}"
    utest::assert $?
    utest::assert_equal "${result[*]}" "xxx yyy"
}

function TEST::cfg::trait::json::array::update_all() {
    local data
    local new

    # path 不存在
    data=$'{}'
    # shellcheck disable=SC2034
    new=("abc" "123" "!@#" "def")
    cfg::trait::json::array::update_all --indent=0 ".name" new data
    utest::assert $?
    utest::assert_equal "${data}" '{"name":["abc","123","!@#","def"]}'

    # path 存在
    data=$'{"name": ["xxx", "yyy"]}'
    # shellcheck disable=SC2034
    new=("abc" "123" "!@#" "def")
    cfg::trait::json::array::update_all --indent=0 ".name" new data
    utest::assert $?
    utest::assert_equal "${data}" '{"name":["abc","123","!@#","def"]}'
}
