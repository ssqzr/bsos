#!/bin/bash

# 接口命名参考 python 的 dict 和 array 接口命名

if [ -n "${SCRIPT_DIR_fbbcbbca}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_fbbcbbca="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/../../utest.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_fbbcbbca}/parser.sh"

declare CFG_TRAIT_INI_DEFAULT_COMMENT=";"
declare CFG_TRAIT_INI_DEFAULT_SEPARATOR=","

######################################## 整体说明       ########################################

# 1. ini 配置只支持 map 和 array 两种数据结构
# 2. section 下的 key = value ，value 不能是 map
# 3. ini 不支持数组，数组是通过分隔符连接的字符串，例如： a,b,c
# 4. 上层已经检查了基本的 path 格式，所以这里检查针对 ini 的限制

function cfg::trait::ini::utils::check_path() {
    local path="$1"
    shift

    local items=()
    local section
    string::split_with items "${path}" "." || return "${SHELL_FALSE}"

    if [ "$(array::length items)" -ne 3 ]; then
        lerror "invalid path: ${path}"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::utils::parse_section() {
    local path="$1"
    shift

    local items=()
    local section
    string::split_with items "${path}" "." || return "${SHELL_FALSE}"

    section="${items[1]}"

    if string::is_empty "${section}"; then
        lerror "can not parse section, invalid path: ${path}"
        return "${SHELL_FALSE}"
    fi

    echo "${section}"
    return "${SHELL_TRUE}"
}

function cfg::trait::ini::utils::parse_key() {
    local path="$1"
    shift

    local items=()
    local key
    string::split_with items "${path}" "." || return "${SHELL_FALSE}"

    key="${items[-1]}"

    if string::is_empty "${key}"; then
        lerror "can not parse key name, invalid path: ${path}"
        return "${SHELL_FALSE}"
    fi

    echo "${key}"
    return "${SHELL_TRUE}"
}

######################################## map 相关的接口 ########################################
# API 整体说明：
# 1. 所有 API 内部变量使用 uuid 的格式，因为 extra 往往会有引用的存在，防止重名，就算没有也防止后面添加后没有注意到。所以最开始就规避掉。

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
function cfg::trait::ini::map::get() {
    local path_237f9215
    local data_237f9215

    local comment_237f9215="${CFG_TRAIT_INI_DEFAULT_COMMENT}"

    # shellcheck disable=SC2034
    local value_237f9215
    local section_in_path_237f9215
    local key_in_path_237f9215

    declare -A extra_237f9215=()
    declare -A callback_237f9215=()
    local is_done_237f9215="${SHELL_FALSE}"

    local param_237f9215

    for param_237f9215 in "$@"; do
        case "$param_237f9215" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_COMMENT}" --option="$param_237f9215" comment_237f9215 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_237f9215"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_237f9215 ]; then
                path_237f9215="$param_237f9215"
                continue
            fi

            if [ ! -v data_237f9215 ]; then
                data_237f9215="$param_237f9215"
                continue
            fi

            lerror "invalid param: $param_237f9215"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_237f9215 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data_237f9215 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_237f9215}, comment=${comment_237f9215}"
    ldebug "param data=${data_237f9215}"

    cfg::trait::ini::utils::check_path "${path_237f9215}" || return "${SHELL_FALSE}"

    section_in_path_237f9215=$(cfg::trait::ini::parser::path::parse_section "${path_237f9215}") || return "${SHELL_FALSE}"
    key_in_path_237f9215=$(cfg::trait::ini::parser::path::parse_key "${path_237f9215}") || return "${SHELL_FALSE}"

    extra_237f9215["section_in_path"]="${section_in_path_237f9215}"
    extra_237f9215["key_in_path"]="${key_in_path_237f9215}"
    extra_237f9215["value"]=value_237f9215
    # shellcheck disable=SC2034
    extra_237f9215["is_done"]=is_done_237f9215

    cfg::trait::ini::parser::factory::callback::default callback_237f9215 || return "${SHELL_FALSE}"
    # shellcheck disable=SC2034
    # 覆盖自己写的回调
    callback_237f9215["line::kv"]="cfg::trait::ini::map::get::callback::line::kv"

    cfg::trait::ini::parser::parser data_237f9215 "${comment_237f9215}" "" callback_237f9215 extra_237f9215 || return "${SHELL_FALSE}"

    if [ "${is_done_237f9215}" != "${SHELL_TRUE}" ]; then
        lerror "map section=${section_in_path_237f9215}, key=${key_in_path_237f9215}, is not exists."
        return "${SHELL_FALSE}"
    fi

    echo "${value_237f9215}"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::map::get::callback::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_28a2a700="$1"

    if array::is_not_associative_array "${!params_28a2a700}"; then
        lerror "invalid params: ref name ${!params_28a2a700} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n result_28a2a700="${params_28a2a700["result"]}"
    local -n extra_28a2a700="${params_28a2a700["extra"]}"
    local -n line_28a2a700="${params_28a2a700["line"]}"
    local line_content_28a2a700="${line_28a2a700["content"]}"
    local line_section_28a2a700="${line_28a2a700["section"]}"
    local line_number_28a2a700="${line_28a2a700["number"]}"
    local section_in_path_28a2a700="${extra_28a2a700["section_in_path"]}"
    local key_in_path_28a2a700="${extra_28a2a700["key_in_path"]}"
    local -n extra_is_done_28a2a700="${extra_28a2a700["is_done"]}"
    local -n extra_value_28a2a700="${extra_28a2a700["value"]}"
    local line_key_28a2a700
    local line_value_28a2a700

    line_key_28a2a700=$(cfg::trait::ini::parser::line::parse_key "${line_content_28a2a700}") || return "${SHELL_FALSE}"
    line_value_28a2a700=$(cfg::trait::ini::parser::line::parse_value "${line_content_28a2a700}") || return "${SHELL_FALSE}"

    ldebug "line_content=${line_content_28a2a700}, line_section=${line_section_28a2a700}, line_number=${line_number_28a2a700}, section_in_path=${section_in_path_28a2a700}, key_in_path=${key_in_path_28a2a700}, key=${line_key_28a2a700}, value=${line_value_28a2a700}"

    result_28a2a700+="${line_content_28a2a700}"$'\n'

    if [ "${line_section_28a2a700}" != "${section_in_path_28a2a700}" ] || [ "${line_key_28a2a700}" != "${key_in_path_28a2a700}" ]; then
        # 不是需要处理的 section 下的 key-value
        return "${SHELL_TRUE}"
    fi

    if [ "${extra_is_done_28a2a700}" == "${SHELL_TRUE}" ]; then
        ldebug "get already done, skip. section=${line_section_28a2a700}, line_content=${line_content_28a2a700}, line_number=${line_number_28a2a700}"
        return "${SHELL_TRUE}"
    fi

    extra_is_done_28a2a700="${SHELL_TRUE}"
    extra_value_28a2a700="${line_value_28a2a700}"

    ldebug "get map key value success, section=${section_in_path_28a2a700}, key=${key_in_path_28a2a700}, is_done=$(string::print_yes_no "${extra_is_done_28a2a700}"), value=${extra_value_28a2a700}"

    return "${SHELL_TRUE}"
}

########################################################################################################################

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
function cfg::trait::ini::map::is_exists() {
    local path_a87c1e96
    local data_a87c1e96

    local comment_a87c1e96="${CFG_TRAIT_INI_DEFAULT_COMMENT}"

    local section_in_path_a87c1e96
    local key_in_path_a87c1e96

    local is_done_a87c1e96="${SHELL_FALSE}"

    declare -A extra_a87c1e96=()
    declare -A callback_a87c1e96=()

    local param_a87c1e96

    for param_a87c1e96 in "$@"; do
        case "$param_a87c1e96" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_COMMENT}" --option="$param_a87c1e96" comment_a87c1e96 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_a87c1e96"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_a87c1e96 ]; then
                path_a87c1e96="$param_a87c1e96"
                continue
            fi

            if [ ! -v data_a87c1e96 ]; then
                data_a87c1e96="$param_a87c1e96"
                continue
            fi

            lerror "invalid param: $param_a87c1e96"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_a87c1e96 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data_a87c1e96 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_a87c1e96}, comment=${comment_a87c1e96}"
    ldebug "param data=${data_a87c1e96}"

    cfg::trait::ini::utils::check_path "${path_a87c1e96}" || return "${SHELL_FALSE}"

    section_in_path_a87c1e96=$(cfg::trait::ini::parser::path::parse_section "${path_a87c1e96}") || return "${SHELL_FALSE}"
    key_in_path_a87c1e96=$(cfg::trait::ini::parser::path::parse_key "${path_a87c1e96}") || return "${SHELL_FALSE}"

    extra_a87c1e96["section_in_path"]="${section_in_path_a87c1e96}"
    extra_a87c1e96["key_in_path"]="${key_in_path_a87c1e96}"
    # shellcheck disable=SC2034
    extra_a87c1e96["is_done"]=is_done_a87c1e96

    cfg::trait::ini::parser::factory::callback::default callback_a87c1e96 || return "${SHELL_FALSE}"
    # shellcheck disable=SC2034
    # 覆盖自己写的回调
    callback_a87c1e96["line::kv"]="cfg::trait::ini::map::is_exists::callback::line::kv"

    cfg::trait::ini::parser::parser data_a87c1e96 "${comment_a87c1e96}" "" callback_a87c1e96 extra_a87c1e96 || return "${SHELL_FALSE}"

    if [ "${is_done_a87c1e96}" != "${SHELL_TRUE}" ]; then
        lerror "map section=${section_in_path_a87c1e96}, key=${key_in_path_a87c1e96}, is not exists."
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::map::is_exists::callback::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_5ae042fa="$1"

    if array::is_not_associative_array "${!params_5ae042fa}"; then
        lerror "invalid params: ref name ${!params_5ae042fa} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n result_5ae042fa="${params_5ae042fa["result"]}"
    local -n extra_5ae042fa="${params_5ae042fa["extra"]}"
    local -n line_5ae042fa="${params_5ae042fa["line"]}"
    local line_content_5ae042fa="${line_5ae042fa["content"]}"
    local line_section_5ae042fa="${line_5ae042fa["section"]}"
    local line_number_5ae042fa="${line_5ae042fa["number"]}"
    local section_in_path_5ae042fa="${extra_5ae042fa["section_in_path"]}"
    local key_in_path_5ae042fa="${extra_5ae042fa["key_in_path"]}"
    local -n extra_is_done_5ae042fa="${extra_5ae042fa["is_done"]}"
    local line_key_5ae042fa
    local line_value_5ae042fa

    line_key_5ae042fa=$(cfg::trait::ini::parser::line::parse_key "${line_content_5ae042fa}") || return "${SHELL_FALSE}"
    line_value_5ae042fa=$(cfg::trait::ini::parser::line::parse_value "${line_content_5ae042fa}") || return "${SHELL_FALSE}"

    ldebug "line_content=${line_content_5ae042fa}, line_section=${line_section_5ae042fa}, line_number=${line_number_5ae042fa}, section_in_path=${section_in_path_5ae042fa}, key_in_path=${key_in_path_5ae042fa}, key=${line_key_5ae042fa}, value=${line_value_5ae042fa}"

    result_5ae042fa+="${line_content_5ae042fa}"$'\n'

    if [ "${line_section_5ae042fa}" != "${section_in_path_5ae042fa}" ] || [ "${line_key_5ae042fa}" != "${key_in_path_5ae042fa}" ]; then
        # 不是需要处理的 section 下的 key-value
        return "${SHELL_TRUE}"
    fi

    if [ "${extra_is_done_5ae042fa}" == "${SHELL_TRUE}" ]; then
        ldebug "find already done, skip. section=${line_section_5ae042fa}, line_content=${line_content_5ae042fa}, line_number=${line_number_5ae042fa}"
        return "${SHELL_TRUE}"
    fi

    extra_is_done_5ae042fa="${SHELL_TRUE}"

    ldebug "map key is exists, section=${section_in_path_5ae042fa}, key=${key_in_path_5ae042fa}, is_done=$(string::print_yes_no "${extra_is_done_5ae042fa}")"

    return "${SHELL_TRUE}"
}

########################################################################################################################

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
function cfg::trait::ini::map::update() {
    local path_fbf44aec
    local value_fbf44aec
    local -n data_fbf44aec

    local comment_fbf44aec="${CFG_TRAIT_INI_DEFAULT_COMMENT}"

    local section_in_path_fbf44aec
    local key_in_path_fbf44aec
    declare -A extra_fbf44aec=()
    declare -A callback_fbf44aec=()
    local is_done_fbf44aec="${SHELL_FALSE}"

    local param_fbf44aec

    for param_fbf44aec in "$@"; do
        case "$param_fbf44aec" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_COMMENT}" --option="$param_fbf44aec" comment_fbf44aec || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_fbf44aec"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_fbf44aec ]; then
                path_fbf44aec="$param_fbf44aec"
                continue
            fi

            if [ ! -v value_fbf44aec ]; then
                value_fbf44aec="$param_fbf44aec"
                continue
            fi

            if [ ! -R data_fbf44aec ]; then
                data_fbf44aec="$param_fbf44aec"
                continue
            fi

            lerror "invalid param: $param_fbf44aec"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_fbf44aec ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v value_fbf44aec ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_fbf44aec ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_fbf44aec}, value=${value_fbf44aec}, comment=${comment_fbf44aec}"
    ldebug "param data ref=${!data_fbf44aec}, data=${data_fbf44aec}"

    cfg::trait::ini::utils::check_path "${path_fbf44aec}" || return "${SHELL_FALSE}"

    section_in_path_fbf44aec=$(cfg::trait::ini::parser::path::parse_section "${path_fbf44aec}") || return "${SHELL_FALSE}"
    key_in_path_fbf44aec=$(cfg::trait::ini::parser::path::parse_key "${path_fbf44aec}") || return "${SHELL_FALSE}"

    extra_fbf44aec["section_in_path"]="${section_in_path_fbf44aec}"
    extra_fbf44aec["key_in_path"]="${key_in_path_fbf44aec}"
    extra_fbf44aec["value"]="${value_fbf44aec}"
    # shellcheck disable=SC2034
    extra_fbf44aec["is_done"]=is_done_fbf44aec

    cfg::trait::ini::parser::factory::callback::default callback_fbf44aec || return "${SHELL_FALSE}"
    # 覆盖自己写的回调
    callback_fbf44aec["line::kv"]="cfg::trait::ini::map::update::callback::line::kv"
    callback_fbf44aec["data::end"]="cfg::trait::ini::map::update::callback::data::end"
    # shellcheck disable=SC2034
    callback_fbf44aec["section::end"]="cfg::trait::ini::map::update::callback::section::end"

    cfg::trait::ini::parser::parser "${!data_fbf44aec}" "${comment_fbf44aec}" "" callback_fbf44aec extra_fbf44aec || return "${SHELL_FALSE}"

    if [ "${is_done_fbf44aec}" = "${SHELL_FALSE}" ]; then
        lerror "map update failed, section=${section_in_path_fbf44aec}, key=${key_in_path_fbf44aec}, value=${value_fbf44aec}"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::map::update::callback::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_fc439f47="$1"

    if array::is_not_associative_array "${!params_fc439f47}"; then
        lerror "invalid params: ref name ${!params_fc439f47} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_fc439f47="${params_fc439f47["line"]}"
    local -n result_fc439f47="${params_fc439f47["result"]}"
    local -n extra_fc439f47="${params_fc439f47["extra"]}"
    local line_content_fc439f47="${line_fc439f47["content"]}"
    local line_section_fc439f47="${line_fc439f47["section"]}"
    local line_number_fc439f47="${line_fc439f47["number"]}"
    local section_in_path_fc439f47="${extra_fc439f47["section_in_path"]}"
    local key_in_path_fc439f47="${extra_fc439f47["key_in_path"]}"
    local extra_value_fc439f47="${extra_fc439f47["value"]}"
    local -n extra_is_done_fc439f47="${extra_fc439f47["is_done"]}"
    local line_key_fc439f47
    local line_value_fc439f47

    ldebug "line_content=${line_content_fc439f47}, line_section=${line_section_fc439f47}, line_number=${line_number_fc439f47}, section_in_path=${section_in_path_fc439f47}, key_in_path=${key_in_path_fc439f47}"

    line_key_fc439f47=$(cfg::trait::ini::parser::line::parse_key "${line_content_fc439f47}") || return "${SHELL_FALSE}"
    line_value_fc439f47=$(cfg::trait::ini::parser::line::parse_value "${line_content_fc439f47}") || return "${SHELL_FALSE}"

    ldebug "line_content=${line_content_fc439f47}, line_section=${line_section_fc439f47}, line_number=${line_number_fc439f47}, section_in_path=${section_in_path_fc439f47}, key_in_path=${key_in_path_fc439f47}, key=${line_key_fc439f47}, value=${line_value_fc439f47}"

    if [ "${line_section_fc439f47}" != "${section_in_path_fc439f47}" ] || [ "${line_key_fc439f47}" != "${key_in_path_fc439f47}" ]; then
        # 不是需要处理的 section 下的 key-value
        result_fc439f47+="${line_content_fc439f47}"$'\n'
        return "${SHELL_TRUE}"
    fi

    if [ "${extra_is_done_fc439f47}" == "${SHELL_TRUE}" ]; then
        ldebug "update already done, skip. section=${line_section_fc439f47}, line_content=${line_content_fc439f47}, line_number=${line_number_fc439f47}"
        return "${SHELL_TRUE}"
    fi

    result_fc439f47+="${line_key_fc439f47}=${extra_value_fc439f47}"$'\n'

    # shellcheck disable=SC2034
    extra_is_done_fc439f47="${SHELL_TRUE}"
    linfo "section=${line_section_fc439f47}, key=${line_key_fc439f47}, old value=${line_value_fc439f47}, new value=${extra_value_fc439f47}"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::map::update::callback::section::end() {
    # 需要传递 associative array 的引用
    local -n params_63fa4a72="$1"

    if array::is_not_associative_array "${!params_63fa4a72}"; then
        lerror "invalid params: ref name ${!params_63fa4a72} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量

    local -n result_63fa4a72="${params_63fa4a72["result"]}"
    local -n extra_63fa4a72="${params_63fa4a72["extra"]}"
    local -n line_63fa4a72="${params_63fa4a72["line"]}"
    local line_section_63fa4a72="${line_63fa4a72["section"]}"
    local line_number_63fa4a72="${line_63fa4a72["number"]}"
    local section_in_path_63fa4a72="${extra_63fa4a72["section_in_path"]}"
    local key_in_path_63fa4a72="${extra_63fa4a72["key_in_path"]}"
    local extra_value_63fa4a72="${extra_63fa4a72["value"]}"
    local -n extra_is_done_63fa4a72="${extra_63fa4a72["is_done"]}"

    ldebug "line_section=${line_section_63fa4a72}, line_number=${line_number_63fa4a72}, section_in_path=${section_in_path_63fa4a72}, key_in_path=${key_in_path_63fa4a72}, update value=${extra_value_63fa4a72}, is_done=$(string::print_yes_no "${extra_is_done_63fa4a72}")"

    if [ "${line_section_63fa4a72}" != "${section_in_path_63fa4a72}" ]; then
        # 不是需要处理的 section 下的 key-value
        return "${SHELL_TRUE}"
    fi

    if [ "${extra_is_done_63fa4a72}" == "${SHELL_TRUE}" ]; then
        ldebug "update already done, skip. section=${line_section_63fa4a72}, line_number=${line_number_63fa4a72}"
        return "${SHELL_TRUE}"
    fi

    linfo "can not found key(${key_in_path_63fa4a72}) in section(${section_in_path_63fa4a72}), add key-value(${key_in_path_63fa4a72}=${extra_value_63fa4a72})."
    result_63fa4a72+="${key_in_path_63fa4a72}=${extra_value_63fa4a72}"$'\n'
    extra_is_done_63fa4a72="${SHELL_TRUE}"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::map::update::callback::data::end() {
    # 需要传递 associative array 的引用
    local -n params_1e90f61d="$1"

    if array::is_not_associative_array "${!params_1e90f61d}"; then
        lerror "invalid params: ref name ${!params_1e90f61d} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量

    local -n result_1e90f61d="${params_1e90f61d["result"]}"
    local -n extra_1e90f61d="${params_1e90f61d["extra"]}"

    local section_in_path_1e90f61d="${extra_1e90f61d["section_in_path"]}"
    local key_in_path_1e90f61d="${extra_1e90f61d["key_in_path"]}"
    local extra_value_1e90f61d="${extra_1e90f61d["value"]}"
    local -n extra_is_done_1e90f61d="${extra_1e90f61d["is_done"]}"

    ldebug "section_in_path=${section_in_path_1e90f61d}, key_in_path=${key_in_path_1e90f61d}, update value=${extra_value_1e90f61d}, is_done=$(string::print_yes_no "${extra_is_done_1e90f61d}")"

    if [ "${extra_is_done_1e90f61d}" == "${SHELL_TRUE}" ]; then
        ldebug "update already done, skip. section_in_path=${section_in_path_1e90f61d}, key_in_path=${key_in_path_1e90f61d}, value=${extra_value_1e90f61d}"
        return "${SHELL_TRUE}"
    fi

    linfo "can not found section(${section_in_path_1e90f61d}), create section and add key-value(${key_in_path_1e90f61d}=${extra_value_1e90f61d})."
    result_1e90f61d+="[${section_in_path_1e90f61d}]"$'\n'
    result_1e90f61d+="${key_in_path_1e90f61d}=${extra_value_1e90f61d}"$'\n'
    extra_is_done_1e90f61d="${SHELL_TRUE}"

    return "${SHELL_TRUE}"
}

########################################################################################################################

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
function cfg::trait::ini::map::pop() {
    local path_d9a26cf6
    # shellcheck disable=SC2034
    local -n value_d9a26cf6
    local -n data_d9a26cf6

    local comment_d9a26cf6="${CFG_TRAIT_INI_DEFAULT_COMMENT}"

    local section_in_path_d9a26cf6
    local key_in_path_d9a26cf6
    declare -A extra_d9a26cf6=()
    declare -A callback_d9a26cf6=()
    # 判断是否 pop 了
    local is_done_d9a26cf6="${SHELL_FALSE}"

    local param_d9a26cf6

    for param_d9a26cf6 in "$@"; do
        case "$param_d9a26cf6" in
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_COMMENT}" --option="$param_d9a26cf6" comment_d9a26cf6 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_d9a26cf6"
            return "${SHELL_FALSE}"
            ;;
        *)

            if [ ! -v path_d9a26cf6 ]; then
                path_d9a26cf6="$param_d9a26cf6"
                continue
            fi

            if [ ! -R value_d9a26cf6 ]; then
                value_d9a26cf6="$param_d9a26cf6"
                continue
            fi

            if [ ! -R data_d9a26cf6 ]; then
                data_d9a26cf6="$param_d9a26cf6"
                continue
            fi

            lerror "invalid param: $param_d9a26cf6"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_d9a26cf6 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R value_d9a26cf6 ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R data_d9a26cf6 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_d9a26cf6}, comment=${comment_d9a26cf6}"
    ldebug "param data=${data_d9a26cf6}"

    cfg::trait::ini::utils::check_path "${path_d9a26cf6}" || return "${SHELL_FALSE}"

    section_in_path_d9a26cf6=$(cfg::trait::ini::parser::path::parse_section "${path_d9a26cf6}") || return "${SHELL_FALSE}"
    key_in_path_d9a26cf6=$(cfg::trait::ini::parser::path::parse_key "${path_d9a26cf6}") || return "${SHELL_FALSE}"

    extra_d9a26cf6["section_in_path"]="${section_in_path_d9a26cf6}"
    extra_d9a26cf6["key_in_path"]="${key_in_path_d9a26cf6}"
    extra_d9a26cf6["result_value"]="${!value_d9a26cf6}"
    # shellcheck disable=SC2034
    extra_d9a26cf6["is_done"]=is_done_d9a26cf6

    cfg::trait::ini::parser::factory::callback::default callback_d9a26cf6 || return "${SHELL_FALSE}"
    # 覆盖自己写的回调
    # shellcheck disable=SC2034
    callback_d9a26cf6["line::kv"]="cfg::trait::ini::map::pop::callback::line::kv"

    cfg::trait::ini::parser::parser "${!data_d9a26cf6}" "${comment_d9a26cf6}" "" callback_d9a26cf6 extra_d9a26cf6 || return "${SHELL_FALSE}"

    if [ "${is_done_d9a26cf6}" = "${SHELL_FALSE}" ]; then
        lerror "pop failed, not found, section=${section_in_path_d9a26cf6}, key=${key_in_path_d9a26cf6}"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::map::pop::callback::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_74857bc9="$1"

    if array::is_not_associative_array "${!params_74857bc9}"; then
        lerror "invalid params: ref name ${!params_74857bc9} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_74857bc9="${params_74857bc9["line"]}"
    local -n result_74857bc9="${params_74857bc9["result"]}"
    local -n extra_74857bc9="${params_74857bc9["extra"]}"
    local line_content_74857bc9="${line_74857bc9["content"]}"
    local line_section_74857bc9="${line_74857bc9["section"]}"
    local line_number_74857bc9="${line_74857bc9["number"]}"
    local section_in_path_74857bc9="${extra_74857bc9["section_in_path"]}"
    local key_in_path_74857bc9="${extra_74857bc9["key_in_path"]}"
    local -n extra_result_value_74857bc9="${extra_74857bc9["result_value"]}"
    local -n extra_is_done_74857bc9="${extra_74857bc9["is_done"]}"
    local line_key_74857bc9
    local line_value_74857bc9

    ldebug "line_content=${line_content_74857bc9}, line_section=${line_section_74857bc9}, line_number=${line_number_74857bc9}, section_in_path=${section_in_path_74857bc9}, key_in_path=${key_in_path_74857bc9}"

    line_key_74857bc9=$(cfg::trait::ini::parser::line::parse_key "${line_content_74857bc9}") || return "${SHELL_FALSE}"
    line_value_74857bc9=$(cfg::trait::ini::parser::line::parse_value "${line_content_74857bc9}") || return "${SHELL_FALSE}"

    ldebug "line_content=${line_content_74857bc9}, line_section=${line_section_74857bc9}, line_number=${line_number_74857bc9}, section_in_path=${section_in_path_74857bc9}, key_in_path=${key_in_path_74857bc9}, key=${line_key_74857bc9}, value=${line_value_74857bc9}"

    if [ "${line_section_74857bc9}" != "${section_in_path_74857bc9}" ] || [ "${line_key_74857bc9}" != "${key_in_path_74857bc9}" ]; then
        # 不是需要处理的 section 下的 key-value
        result_74857bc9+="${line_content_74857bc9}"$'\n'
        return "${SHELL_TRUE}"
    fi

    if [ "${extra_is_done_74857bc9}" == "${SHELL_TRUE}" ]; then
        ldebug "pop already done, skip. section=${line_section_74857bc9}, line_content=${line_content_74857bc9}, line_number=${line_number_74857bc9}"
        return "${SHELL_TRUE}"
    fi

    extra_result_value_74857bc9="${line_value_74857bc9}"
    # shellcheck disable=SC2034
    extra_is_done_74857bc9="${SHELL_TRUE}"
    linfo "section=${line_section_74857bc9}, key=${line_key_74857bc9}, value=${line_value_74857bc9}, result_value=${extra_result_value_74857bc9}"

    return "${SHELL_TRUE}"
}

########################################################################################################################

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
function cfg::trait::ini::array::all() {
    local -n result_array_6b33bf94
    local path_6b33bf94
    local data_6b33bf94

    local param_6b33bf94
    local separator_6b33bf94="${CFG_TRAIT_INI_DEFAULT_SEPARATOR}"
    local comment_6b33bf94="${CFG_TRAIT_INI_DEFAULT_COMMENT}"

    local section_in_path_6b33bf94
    local key_in_path_6b33bf94

    # shellcheck disable=SC2034
    declare -A callback_6b33bf94=()
    declare -A extra_6b33bf94=()

    for param_6b33bf94 in "$@"; do
        case "$param_6b33bf94" in
        --separator=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_SEPARATOR}" --option="$param_6b33bf94" separator_6b33bf94 || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_COMMENT}" --option="$param_6b33bf94" comment_6b33bf94 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_6b33bf94"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R result_array_6b33bf94 ]; then
                result_array_6b33bf94="$param_6b33bf94"
                continue
            fi

            if [ ! -v path_6b33bf94 ]; then
                path_6b33bf94="$param_6b33bf94"
                continue
            fi

            if [ ! -v data_6b33bf94 ]; then
                data_6b33bf94="$param_6b33bf94"
                continue
            fi

            lerror "invalid param: $param_6b33bf94"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R result_array_6b33bf94 ]; then
        lerror "param all is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v path_6b33bf94 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data_6b33bf94 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param all=${!result_array_6b33bf94} path=${path_6b33bf94},  separator=${separator_6b33bf94}, comment=${comment_6b33bf94}"
    ldebug "param data=${data_6b33bf94}"

    cfg::trait::ini::utils::check_path "${path_6b33bf94}" || return "${SHELL_FALSE}"

    section_in_path_6b33bf94=$(cfg::trait::ini::parser::path::parse_section "${path_6b33bf94}") || return "${SHELL_FALSE}"
    key_in_path_6b33bf94=$(cfg::trait::ini::parser::path::parse_key "${path_6b33bf94}") || return "${SHELL_FALSE}"

    extra_6b33bf94["section_in_path"]="${section_in_path_6b33bf94}"
    extra_6b33bf94["key_in_path"]="${key_in_path_6b33bf94}"
    result_array_6b33bf94=()
    # shellcheck disable=SC2034
    extra_6b33bf94["result_array"]="${!result_array_6b33bf94}"

    cfg::trait::ini::parser::factory::callback::default callback_6b33bf94 || return "${SHELL_FALSE}"
    # 覆盖自己写的回调
    # shellcheck disable=SC2034
    callback_6b33bf94["line::kv"]="cfg::trait::ini::array::all::callback::line::kv"

    cfg::trait::ini::parser::parser data_6b33bf94 "${comment_6b33bf94}" "${separator_6b33bf94}" callback_6b33bf94 extra_6b33bf94 || return "${SHELL_FALSE}"

    linfo "result array=(${result_array_6b33bf94[*]})"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::array::all::callback::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_bba79196="$1"

    if array::is_not_associative_array "${!params_bba79196}"; then
        lerror "invalid params: ref name ${!params_bba79196} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local separator_bba79196="${params_bba79196["separator"]}"
    local -n line_bba79196="${params_bba79196["line"]}"
    local -n result_bba79196="${params_bba79196["result"]}"
    local -n extra_bba79196="${params_bba79196["extra"]}"
    local line_content_bba79196="${line_bba79196["content"]}"
    local line_section_bba79196="${line_bba79196["section"]}"
    local line_number_bba79196="${line_bba79196["number"]}"
    local section_in_path_bba79196="${extra_bba79196["section_in_path"]}"
    local key_in_path_bba79196="${extra_bba79196["key_in_path"]}"
    local -n extra_result_array_bba79196="${extra_bba79196["result_array"]}"
    local line_key_bba79196
    local line_value_bba79196

    ldebug "separator=${separator_bba79196}, line_content=${line_content_bba79196}, line_section=${line_section_bba79196}, line_number=${line_number_bba79196}, section_in_path=${section_in_path_bba79196}, key_in_path=${key_in_path_bba79196}"

    line_key_bba79196=$(cfg::trait::ini::parser::line::parse_key "${line_content_bba79196}") || return "${SHELL_FALSE}"
    line_value_bba79196=$(cfg::trait::ini::parser::line::parse_value "${line_content_bba79196}") || return "${SHELL_FALSE}"

    ldebug "separator=${separator_bba79196}, line_content=${line_content_bba79196}, line_section=${line_section_bba79196}, line_number=${line_number_bba79196}, section_in_path=${section_in_path_bba79196}, key_in_path=${key_in_path_bba79196}, key=${line_key_bba79196}, value=${line_value_bba79196}"

    # 不管怎么样都回写
    result_bba79196+="${line_content_bba79196}"$'\n'

    if [ "${line_section_bba79196}" != "${section_in_path_bba79196}" ] || [ "${line_key_bba79196}" != "${key_in_path_bba79196}" ]; then
        # 不是需要处理的 section 下的 key-value
        return "${SHELL_TRUE}"
    fi

    linfo "section=${line_section_bba79196}, key=${line_key_bba79196}, value=${line_value_bba79196}"
    string::split_with "${!extra_result_array_bba79196}" "${line_value_bba79196}" "${separator_bba79196}" || return "${SHELL_FALSE}"
    linfo "section=${line_section_bba79196}, key=${line_key_bba79196}, value=${line_value_bba79196}, parse array result=${extra_result_array_bba79196[*]}"

    return "${SHELL_TRUE}"
}
########################################################################################################################

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
function cfg::trait::ini::array::update_all() {
    local path_ece25cf2
    local -n new_ece25cf2
    local -n data_ece25cf2

    # 防止后面调用的函数覆盖上级的变量名，通过这里代理，保证后面使用的变量引用是本函数定义的变量名，不会重名
    # 也防止内部修改 new 变量
    # shellcheck disable=SC2034
    local new_copy_ece25cf2
    local data_copy_ece25cf2

    local param_ece25cf2
    local separator_ece25cf2="${CFG_TRAIT_INI_DEFAULT_SEPARATOR}"
    local comment_ece25cf2="${CFG_TRAIT_INI_DEFAULT_COMMENT}"

    local section_in_path_ece25cf2
    local key_in_path_ece25cf2
    declare -A extra_ece25cf2=()
    declare -A callback_ece25cf2=()
    # shellcheck disable=SC2034
    local is_done_ece25cf2="${SHELL_FALSE}"

    for param_ece25cf2 in "$@"; do
        case "$param_ece25cf2" in
        --separator=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_SEPARATOR}" --option="$param_ece25cf2" separator_ece25cf2 || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --default="${CFG_TRAIT_INI_DEFAULT_COMMENT}" --option="$param_ece25cf2" comment_ece25cf2 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_ece25cf2"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v path_ece25cf2 ]; then
                path_ece25cf2="$param_ece25cf2"
                continue
            fi

            if [ ! -v new_ece25cf2 ]; then
                new_ece25cf2="$param_ece25cf2"
                continue
            fi

            if [ ! -v data_ece25cf2 ]; then
                data_ece25cf2="$param_ece25cf2"
                continue
            fi

            lerror "invalid param: $param_ece25cf2"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v path_ece25cf2 ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v new_ece25cf2 ]; then
        lerror "param new is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v data_ece25cf2 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    linfo "param path=${path_ece25cf2}, new=${!new_ece25cf2}, separator=${separator_ece25cf2}, comment=${comment_ece25cf2}"
    ldebug "param data=${data_ece25cf2}"

    array::copy new_copy_ece25cf2 "${!new_ece25cf2}" || return "${SHELL_FALSE}"
    data_copy_ece25cf2="${data_ece25cf2}"

    cfg::trait::ini::utils::check_path "${path_ece25cf2}" || return "${SHELL_FALSE}"

    section_in_path_ece25cf2=$(cfg::trait::ini::parser::path::parse_section "${path_ece25cf2}") || return "${SHELL_FALSE}"
    key_in_path_ece25cf2=$(cfg::trait::ini::parser::path::parse_key "${path_ece25cf2}") || return "${SHELL_FALSE}"

    extra_ece25cf2["section_in_path"]="${section_in_path_ece25cf2}"
    extra_ece25cf2["key_in_path"]="${key_in_path_ece25cf2}"
    extra_ece25cf2["is_done"]=is_done_ece25cf2
    # shellcheck disable=SC2034
    extra_ece25cf2["new_array"]=new_copy_ece25cf2

    cfg::trait::ini::parser::factory::callback::default callback_ece25cf2 || return "${SHELL_FALSE}"
    # 覆盖自己写的回调
    callback_ece25cf2["line::kv"]="cfg::trait::ini::array::update_all::callback::line::kv"
    callback_ece25cf2["section::end"]="cfg::trait::ini::array::update_all::callback::section::end"
    # shellcheck disable=SC2034
    callback_ece25cf2["data::end"]="cfg::trait::ini::array::update_all::callback::data::end"

    cfg::trait::ini::parser::parser data_copy_ece25cf2 "${comment_ece25cf2}" "${separator_ece25cf2}" callback_ece25cf2 extra_ece25cf2 || return "${SHELL_FALSE}"

    data_ece25cf2="${data_copy_ece25cf2}"
    linfo "update array success. section=${section_in_path_ece25cf2}, key=${key_in_path_ece25cf2}"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::array::update_all::callback::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_f9b6a329="$1"

    if array::is_not_associative_array "${!params_f9b6a329}"; then
        lerror "invalid params: ref name ${!params_f9b6a329} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local separator_f9b6a329="${params_f9b6a329["separator"]}"
    local -n result_f9b6a329="${params_f9b6a329["result"]}"
    local -n extra_f9b6a329="${params_f9b6a329["extra"]}"
    local -n line_f9b6a329="${params_f9b6a329["line"]}"
    local line_content_f9b6a329="${line_f9b6a329["content"]}"
    local line_section_f9b6a329="${line_f9b6a329["section"]}"
    local line_number_f9b6a329="${line_f9b6a329["number"]}"
    local section_in_path_f9b6a329="${extra_f9b6a329["section_in_path"]}"
    local key_in_path_f9b6a329="${extra_f9b6a329["key_in_path"]}"
    local -n extra_new_array_f9b6a329="${extra_f9b6a329["new_array"]}"
    local -n is_done_f9b6a329="${extra_f9b6a329["is_done"]}"
    local line_key_f9b6a329
    local line_value_f9b6a329
    local old_array_f9b6a329=()
    local new_line_value_f9b6a329

    line_key_f9b6a329=$(cfg::trait::ini::parser::line::parse_key "${line_content_f9b6a329}") || return "${SHELL_FALSE}"
    line_value_f9b6a329=$(cfg::trait::ini::parser::line::parse_value "${line_content_f9b6a329}") || return "${SHELL_FALSE}"

    ldebug "separator=${separator_f9b6a329}, line_content=${line_content_f9b6a329}, line_section=${line_section_f9b6a329}, line_number=${line_number_f9b6a329}, section_in_path=${section_in_path_f9b6a329}, key_in_path=${key_in_path_f9b6a329}, line_key=${line_key_f9b6a329}, line_value=${line_value_f9b6a329}, new_array=${extra_new_array_f9b6a329[*]}"

    if [ "${line_section_f9b6a329}" != "${section_in_path_f9b6a329}" ] || [ "${line_key_f9b6a329}" != "${key_in_path_f9b6a329}" ]; then
        # 不是需要处理的 section 下的 key-value
        result_f9b6a329+="${line_content_f9b6a329}"$'\n'
        return "${SHELL_TRUE}"
    fi

    if [ "${is_done_b671e36f}" == "${SHELL_TRUE}" ]; then
        ldebug "update is done, skip. section=${line_section_f9b6a329}, line_content=${line_content_f9b6a329}, line_number=${line_number_f9b6a329}"
        return "${SHELL_TRUE}"
    fi

    linfo "section=${line_section_f9b6a329}, line_key=${line_key_f9b6a329}, line_value=${line_value_f9b6a329}"
    string::split_with old_array_f9b6a329 "${line_value_f9b6a329}" "${separator_f9b6a329}" || return "${SHELL_FALSE}"

    new_line_value_f9b6a329="$(array::join_with "${!extra_new_array_f9b6a329}" "${separator_f9b6a329}")" || return "${SHELL_FALSE}"
    result_f9b6a329+="${line_key_f9b6a329}=${new_line_value_f9b6a329}"$'\n'
    is_done_f9b6a329="${SHELL_TRUE}"

    linfo "update array success. section=${line_section_f9b6a329}, line_key=${line_key_f9b6a329}, line_value=${line_value_f9b6a329}, old array=${old_array_f9b6a329[*]}, new_array=${extra_new_array_f9b6a329[*]}, is_done=$(string::print_yes_no "${is_done_f9b6a329}")"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::array::update_all::callback::section::end() {
    # 需要传递 associative array 的引用
    local -n params_b671e36f="$1"

    if array::is_not_associative_array "${!params_b671e36f}"; then
        lerror "invalid params: ref name ${!params_b671e36f} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local separator_b671e36f="${params_b671e36f["separator"]}"
    local -n result_b671e36f="${params_b671e36f["result"]}"
    local -n extra_b671e36f="${params_b671e36f["extra"]}"
    local -n line_b671e36f="${params_b671e36f["line"]}"
    local line_section_b671e36f="${line_b671e36f["section"]}"
    local line_number_b671e36f="${line_b671e36f["number"]}"
    local section_in_path_b671e36f="${extra_b671e36f["section_in_path"]}"
    local key_in_path_b671e36f="${extra_b671e36f["key_in_path"]}"
    local -n extra_new_array_b671e36f="${extra_b671e36f["new_array"]}"
    local -n is_done_b671e36f="${extra_b671e36f["is_done"]}"
    local new_line_value_b671e36f

    ldebug "separator=${separator_b671e36f}, line_section=${line_section_b671e36f}, line_number=${line_number_b671e36f}, section_in_path=${section_in_path_b671e36f}, key_in_path=${key_in_path_b671e36f} new_array=${extra_new_array_b671e36f[*]}"

    if [ "${line_section_b671e36f}" != "${section_in_path_b671e36f}" ]; then
        # 不是需要处理的 section 下的 key-value
        return "${SHELL_TRUE}"
    fi

    if [ "${is_done_b671e36f}" == "${SHELL_TRUE}" ]; then
        ldebug "update is done, skip. section=${line_section_b671e36f}, line_number=${line_number_b671e36f}"
        return "${SHELL_TRUE}"
    fi

    new_line_value_b671e36f="$(array::join_with "${!extra_new_array_b671e36f}" "${separator_b671e36f}")" || return "${SHELL_FALSE}"
    result_b671e36f+="${key_in_path_b671e36f}=${new_line_value_b671e36f}"$'\n'
    is_done_b671e36f="${SHELL_TRUE}"

    linfo "key is not in section, create success. section=${line_section_b671e36f}, key=${key_in_path_b671e36f}, value=${new_line_value_b671e36f}, new_array=${extra_new_array_b671e36f[*]}, is_done=$(string::print_yes_no "${is_done_b671e36f}")"

    return "${SHELL_TRUE}"
}

function cfg::trait::ini::array::update_all::callback::data::end() {
    # 需要传递 associative array 的引用
    local -n params_35a51ca6="$1"

    if array::is_not_associative_array "${!params_35a51ca6}"; then
        lerror "invalid params: ref name ${!params_35a51ca6} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local separator_35a51ca6="${params_35a51ca6["separator"]}"
    local -n result_35a51ca6="${params_35a51ca6["result"]}"
    local -n extra_35a51ca6="${params_35a51ca6["extra"]}"
    local section_in_path_35a51ca6="${extra_35a51ca6["section_in_path"]}"
    local key_in_path_35a51ca6="${extra_35a51ca6["key_in_path"]}"
    local -n extra_new_array_35a51ca6="${extra_35a51ca6["new_array"]}"
    local -n is_done_35a51ca6="${extra_35a51ca6["is_done"]}"
    local new_line_value_35a51ca6

    ldebug "separator=${separator_35a51ca6}, section_in_path=${section_in_path_35a51ca6}, key_in_path=${key_in_path_35a51ca6} new_array=${extra_new_array_35a51ca6[*]}"

    if [ "${is_done_35a51ca6}" == "${SHELL_TRUE}" ]; then
        ldebug "update is done, skip. section_in_path=${section_in_path_35a51ca6}, key_in_path=${key_in_path_35a51ca6}"
        return "${SHELL_TRUE}"
    fi

    new_line_value_35a51ca6="$(array::join_with "${!extra_new_array_35a51ca6}" "${separator_35a51ca6}")" || return "${SHELL_FALSE}"
    result_35a51ca6+="[${section_in_path_35a51ca6}]"$'\n'
    result_35a51ca6+="${key_in_path_35a51ca6}=${new_line_value_35a51ca6}"$'\n'
    is_done_35a51ca6="${SHELL_TRUE}"

    linfo "section is not exists, create success. section=${section_in_path_35a51ca6}, key=${key_in_path_35a51ca6}, value=${new_line_value_35a51ca6}, new_array=${extra_new_array_35a51ca6[*]}, is_done=$(string::print_yes_no "${is_done_35a51ca6}")"

    return "${SHELL_TRUE}"
}

########################################################################################################################

######################################## map 测试代码 ########################################

function TEST::cfg::trait::ini::map::get() {
    local value

    # 不存在 section
    value=$(cfg::trait::ini::map::get ".a.b" $'\n')
    utest::assert_fail $?
    utest::assert_equal "${value}" ""

    # 存在 section，不存在 key ， section 后面没有其他的 section
    value=$(cfg::trait::ini::map::get ".test2.name" $'[test1]\nname=abc\n[test2]\nage=12\n')
    utest::assert_fail $?
    utest::assert_equal "${value}" ""

    # 存在 section，不存在 key， section 后面存在其他的 section
    value=$(cfg::trait::ini::map::get ".test1.name" $'[test1]\nname1=abc\n[test2]\nname=123\n')
    utest::assert_fail $?
    utest::assert_equal "${value}" ""

    # 存在 section，存在 key， section 后面没有其他的 section
    value=$(cfg::trait::ini::map::get ".test2.name" $'[test1]\nname=abc\n[test2]\nname=123\n')
    utest::assert $?
    utest::assert_equal "${value}" "123"

    # 存在 section，存在 key， section 后面存在其他的 section
    value=$(cfg::trait::ini::map::get ".test1.name" $'[test1]\nname=abc\n[test2]\nname=123\n')
    utest::assert $?
    utest::assert_equal "${value}" "abc"

    # 测试 value 前后有空格
    value=$(cfg::trait::ini::map::get ".a.b" $'[a]\n    b   =  1   ')
    utest::assert $?
    utest::assert_equal "${value}" "  1   "

    value=$(cfg::trait::ini::map::get ".test2.name" $'[test1]\n    name   =  123   \n[test2]\nname=xxx')
    utest::assert $?
    utest::assert_equal "${value}" "xxx"

    value=$(cfg::trait::ini::map::get ".test3.name" $'[test1]\n    name   =  123   \n[test2]\nname=xxx')
    utest::assert_fail $?
    utest::assert_equal "${value}" ""
}

function TEST::cfg::trait::ini::map::is_exists() {
    # 不存在 section
    cfg::trait::ini::map::is_exists ".test1.name" $'\n'
    utest::assert_fail $?

    # 存在 section，不存在 key ， section 后面没有其他的 section
    cfg::trait::ini::map::is_exists ".test1.name" $'[test]\nname=abc\n[test1]\nage=12\n'
    utest::assert_fail $?

    # 存在 section，不存在 key， section 后面存在其他的 section
    cfg::trait::ini::map::is_exists ".test1.name" $'[test1]\nname1=abc\n[test2]\nname=xxx\nage=12\n'
    utest::assert_fail $?

    # 存在 section，存在 key， section 后面没有其他的 section
    cfg::trait::ini::map::is_exists ".test1.name" $'[test]\n[test1]\nname=abc\n'
    utest::assert $?

    # 存在 section，存在 key， section 后面存在其他的 section
    cfg::trait::ini::map::is_exists ".test1.name" $'[test1]\n    name   =  123   \n[test2]\nname1=xxx'
    utest::assert $?
}

function TEST::cfg::trait::ini::map::update() {
    local data
    # 不存在 section
    data=$''
    cfg::trait::ini::map::update ".test3.name" "xxx" data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname=xxx\n'

    # 存在 section，不存在 key， section 后面还有其他的 section
    data=$'[test3]\n[test4]\n'
    cfg::trait::ini::map::update ".test3.name" "xxx" data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname=xxx\n[test4]\n'

    # 存在 section，不存在 key， section 后面没有其他的 section
    data=$'[test3]\n'
    cfg::trait::ini::map::update ".test3.name" "xxx" data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname=xxx\n'

    # 存在 section，存在 key， section 后面还有其他的 section
    data=$'[test3]\nname=abc\n[test4]'
    cfg::trait::ini::map::update ".test3.name" "xxx" data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname=xxx\n[test4]\n'

    # 存在 section，存在 key， section 后面没有其他的 section
    data=$'[test3]\nname=abc'
    cfg::trait::ini::map::update ".test3.name" "xxx" data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname=xxx\n'

}

function TEST::cfg::trait::ini::map::pop() {
    local value
    local data

    # 不存在 section
    data=$'[test1]\n'
    cfg::trait::ini::map::pop ".test3.name" value data
    utest::assert_fail $?
    utest::assert_equal "$value" ""
    utest::assert_equal "$data" $'[test1]\n'

    # 存在 section，不存在 key， section 后面没有其他的 section
    data=$'[test3]\n'
    cfg::trait::ini::map::pop ".test3.name" value data
    utest::assert_fail $?
    utest::assert_equal "$value" ""
    utest::assert_equal "$data" $'[test3]\n'

    # 存在 section，不存在 key， section 后面存在其他的 section
    data=$'[test3]\n[test4]\n'
    cfg::trait::ini::map::pop ".test3.name" value data
    utest::assert_fail $?
    utest::assert_equal "$value" ""
    utest::assert_equal "$data" $'[test3]\n[test4]\n'

    # 存在 section，存在 key， section 后面没有其他的 section
    data=$'[test3]\nname=abc'
    cfg::trait::ini::map::pop ".test3.name" value data
    utest::assert $?
    utest::assert_equal "$value" "abc"
    utest::assert_equal "$data" $'[test3]\n'

    # 存在 section，存在 key， section 后面还有其他的 section
    data=$'[test3]\nname=abc\n[test4]'
    cfg::trait::ini::map::pop ".test3.name" value data
    utest::assert $?
    utest::assert_equal "$value" "abc"
    utest::assert_equal "$data" $'[test3]\n[test4]\n'
}
######################################## array 测试代码 ########################################

function TEST::cfg::trait::ini::array::all() {
    local data
    local result

    # 不存在 section
    data=$'[test4]'
    cfg::trait::ini::array::all result ".test3.name" "$data"
    utest::assert $?
    utest::assert_equal "${result[*]}" ""

    # 存在 section，不存在 key， section 后面没有其他的 section
    data=$'[test3]\nname1=abc'
    cfg::trait::ini::array::all result ".test3.name" "$data"
    utest::assert $?
    utest::assert_equal "${result[*]}" ""

    # 存在 section，不存在 key， section 后面存在其他的 section
    data=$'[test3]\nname1=abc\n[test4]\nname=123'
    cfg::trait::ini::array::all result ".test3.name" "$data"
    utest::assert $?
    utest::assert_equal "${result[*]}" ""

    # 存在 section，存在 key， section 后面没有其他的 section
    data=$'[test3]\nname=abc,  12  ,  34   \nname1=1234'
    result=()
    cfg::trait::ini::array::all result ".test3.name" "$data"
    utest::assert $?
    utest::assert_equal "${result[*]}" "abc   12     34   "

    # 存在 section，存在 key， section 后面还有其他的 section
    data=$'[test3]\nname=abc,12,34\n[test4]\nname=123'
    cfg::trait::ini::array::all result ".test3.name" "$data"
    utest::assert $?
    utest::assert_equal "${result[*]}" "abc 12 34"

    # 存在 section，存在 key， 数组使用不同的分隔符
    data=$'[test3]\nname=abc;12;34\n[test4]\nname=123'
    cfg::trait::ini::array::all --separator=';' result ".test3.name" "$data"
    utest::assert $?
    utest::assert_equal "${result[*]}" "abc 12 34"
}

function TEST::cfg::trait::ini::array::update_all() {
    local data
    local new_array

    # 不存在 section
    data=$'[test4]'
    new_array=("abc" "123" "!@#")
    cfg::trait::ini::array::update_all ".test3.name" new_array data
    utest::assert $?
    utest::assert_equal "$data" $'[test4]\n[test3]\nname=abc,123,!@#\n'

    # 存在 section，不存在 key， section 后面没有其他的 section
    data=$'[test3]\nname1=abc\n'
    new_array=("abc" "123" "!@#")
    cfg::trait::ini::array::update_all ".test3.name" new_array data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname1=abc\nname=abc,123,!@#\n'

    # 存在 section，不存在 key， section 后面存在其他的 section
    data=$'[test3]\nname1=abc\n[test4]\nname=123'
    new_array=("abc" "123" "!@#")
    cfg::trait::ini::array::update_all ".test3.name" new_array data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname1=abc\nname=abc,123,!@#\n[test4]\nname=123\n'

    # 存在 section，存在 key， section 后面没有其他的 section
    data=$'[test3]\nname=abc,  12  ,  34   \nname1=1234'
    new_array=("abc" "123" "!@#")
    cfg::trait::ini::array::update_all ".test3.name" new_array data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nname=abc,123,!@#\nname1=1234\n'

    # 存在 section，存在 key， section 后面还有其他的 section
    data=$'[test3]\nid=#####\nname=abc,12,34\nage=23\n[test4]\nname=123\n'
    new_array=("abc" "123" "!@#")
    cfg::trait::ini::array::update_all ".test3.name" new_array data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nid=#####\nname=abc,123,!@#\nage=23\n[test4]\nname=123\n'

    # 存在 section，存在 key， 数组使用不同的分隔符
    data=$'[test3]\nid=#####\nname=abc;12;34\nage=23\n[test4]\nname=123\n'
    new_array=("abc" "123" "!@#")
    cfg::trait::ini::array::update_all --separator=';' ".test3.name" new_array data
    utest::assert $?
    utest::assert_equal "$data" $'[test3]\nid=#####\nname=abc;123;!@#\nage=23\n[test4]\nname=123\n'
}
