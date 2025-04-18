#!/bin/bash

if [ -n "${SCRIPT_DIR_11590d6c}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_11590d6c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_11590d6c}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_11590d6c}/../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_11590d6c}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_11590d6c}/../parameter.sh"

declare __valid_type_11590d6c=()
declare __default_type_11590d6c="json"
declare __cfg_temp_11590d6c
declare __cfg_files_11590d6c

fs::directory::read __cfg_files_11590d6c "${SCRIPT_DIR_11590d6c}" || exit "${SHELL_FALSE}"

for __cfg_temp_11590d6c in "${__cfg_files_11590d6c[@]}"; do
    if fs::path::is_not_directory "${__cfg_temp_11590d6c}"; then
        continue
    fi
    if string::is_ends_with "${__cfg_temp_11590d6c}" "template"; then
        continue
    fi

    __valid_type_11590d6c+=("$(fs::path::basename "${__cfg_temp_11590d6c}")")

    # shellcheck source=/dev/null
    source "${__cfg_temp_11590d6c}/trait.sh" || exit "${SHELL_FALSE}"
done

function cfg::utils::_check_type() {
    local type="$1"
    shift

    if array::is_not_contain __valid_type_11590d6c "$type"; then
        lerror "invalid config type: $type"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function cfg::utils::_check_path() {
    local path="$1"
    shift

    local length

    length="$(string::length "$path")"

    if string::is_empty "${path}"; then
        lerror "invalid path(${path}), path must be non-empty"
        return "${SHELL_FALSE}"
    fi

    if [ "${path:0:1}" != "." ]; then
        lerror "invalid path(${path}), path must start with ."
        return "${SHELL_FALSE}"
    fi

    if [ "${length}" -gt 1 ] && [ "${path:$length-1}" == "." ]; then
        lerror "invalid path(${path}), path must not end with ."
        return "${SHELL_FALSE}"
    fi

    # 是否包含连续的 ..
    if [ "${path//../}" != "$path" ]; then
        lerror "invalid path(${path}), path must not contain .."
        return "${SHELL_FALSE}"
    fi
    return "${SHELL_TRUE}"
}

# 赋值字符串或者数组
function cfg::utils::_write_ref() {
    local -n ref_cef213e6="$1"
    shift
    # 需要支持赋值数组，所以使用引用
    local -n ref_value_cef213e6="$1"
    shift

    if array::is_array ref_value_cef213e6; then
        ref_cef213e6=("${ref_value_cef213e6[@]}")
    else
        # shellcheck disable=SC2178
        # shellcheck disable=SC2034
        ref_cef213e6="$ref_value_cef213e6"
    fi
    return "${SHELL_TRUE}"
}

# https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html
# 使用命令替换会删除最后的所有换行符，返回的数据和真实的数据是有差异的
function cfg::utils::_read_data() {
    local -n return_data_ref_556e8434="$1"
    shift
    local -n data_556e8434="$1"
    shift
    local filepath_556e8434="$1"
    shift

    # 数据可能有但是是空字符串，所以判断原始变量是否初始化
    if [ ! -v "${!data_556e8434}" ] && string::is_empty "$filepath_556e8434"; then
        lerror "param data_ref_name or filepath is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -v "${!data_556e8434}" ]; then
        fs::file::read "$filepath_556e8434" "${!return_data_ref_556e8434}" || return "${SHELL_FALSE}"
        return "${SHELL_TRUE}"
    fi

    # shellcheck disable=SC2034
    return_data_ref_556e8434="$data_556e8434"

    return "${SHELL_TRUE}"
}

function cfg::utils::_write_data() {
    # 虽然定义的变量都不是引用 但是函数内部会使用引用，所以变量名不能重复
    local is_sudo_96af4982="${SHELL_FALSE}"
    local is_write_file="${SHELL_FALSE}"
    local filepath_96af4982
    local write_data_ref_name_96af4982
    local data_96af4982
    local param_96af4982

    for param_96af4982 in "$@"; do
        case "$param_96af4982" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param_96af4982" is_sudo_96af4982 || return "$SHELL_FALSE"
            ;;
        --write-file=*)
            parameter::parse_bool --default=y --option="$param_96af4982" is_write_file || return "$SHELL_FALSE"
            ;;
        --filepath=*)
            parameter::parse_string --option="$param_96af4982" filepath_96af4982 || return "${SHELL_FALSE}"
            ;;
        --write-data-ref=*)
            parameter::parse_string --option="$param_96af4982" write_data_ref_name_96af4982 || return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v data_96af4982 ]; then
                data_96af4982="$param_96af4982"
                continue
            fi

            lerror "invalid param: $param_96af4982"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v data_96af4982 ]; then
        lerror "param data is required"
        return "${SHELL_FALSE}"
    fi

    if [ "${is_write_file}" == "${SHELL_TRUE}" ] && string::is_empty "$filepath_96af4982"; then
        lerror "param filepath is required when write file"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$write_data_ref_name_96af4982"; then
        cfg::utils::_write_ref "$write_data_ref_name_96af4982" data_96af4982 || return "${SHELL_FALSE}"
    fi

    if [ "${is_write_file}" == "${SHELL_TRUE}" ]; then
        fs::file::write --sudo="$(string::print_yes_no "$is_sudo_96af4982")" --force "$filepath_96af4982" "${data_96af4982}" || return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

function cfg::utils::_parse_common_parameter() {
    local -n is_sudo_7cc07bcb="$1"
    shift
    local -n type_7cc07bcb="$1"
    shift
    local -n path_7cc07bcb="$1"
    shift
    local -n data_7cc07bcb="$1"
    shift
    local -n filepath_7cc07bcb="$1"
    shift
    local -n remain_param_7cc07bcb="$1"
    shift

    local param_7cc07bcb
    local temp_params_7cc07bcb=()

    type_7cc07bcb="${__default_type_11590d6c}"

    for param_7cc07bcb in "${remain_param_7cc07bcb[@]}"; do
        case "$param_7cc07bcb" in
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --default=y --option="$param_7cc07bcb" "${!is_sudo_7cc07bcb}" || return "$SHELL_FALSE"
            ;;
        --type=*)
            parameter::parse_string --default="${__default_type_11590d6c}" --option="$param_7cc07bcb" "${!type_7cc07bcb}" || return "${SHELL_FALSE}"
            ;;
        --filepath=*)
            parameter::parse_string --option="$param_7cc07bcb" "${!filepath_7cc07bcb}" || return "${SHELL_FALSE}"
            ;;
        --data=*)
            parameter::parse_string --option="$param_7cc07bcb" "${!data_7cc07bcb}" || return "${SHELL_FALSE}"
            ;;
        -*)
            temp_params_7cc07bcb+=("$param_7cc07bcb")
            ;;
        *)
            if [ ! -v path_7cc07bcb ]; then
                path_7cc07bcb="$param_7cc07bcb"
                continue
            fi

            temp_params_7cc07bcb+=("$param_7cc07bcb")
            ;;
        esac
    done

    # 判断原始变量是否初始化
    if [ ! -v path_7cc07bcb ]; then
        lerror "param path is required"
        return "${SHELL_FALSE}"
    fi

    # 判断原始变量是否初始化
    if [ ! -v data_7cc07bcb ] && [ ! -v filepath_7cc07bcb ]; then
        lerror "param data or filepath is required"
        return "${SHELL_FALSE}"
    fi

    path_7cc07bcb="$(string::trim "${path_7cc07bcb}")"

    cfg::utils::_check_type "$type_7cc07bcb" || return "${SHELL_FALSE}"

    cfg::utils::_check_path "$path_7cc07bcb" || return "${SHELL_FALSE}"

    remain_param_7cc07bcb=("${temp_params_7cc07bcb[@]}")

    return "${SHELL_TRUE}"
}

######################################## 整体说明 ########################################
#   - 所有 API 支持从命令行参数中读取数据
#   - 所有 API 支持从文件中读取数据
#   - 所有 API 同时指定多个数据源时，优先级为： 命令行参数 > 文件
#   - 所有 API 不检查数据是否为空字符串，因为有些配置是允许为空的
#   - 所有 API 如果不指定配置类型，则默认为 ${__default_type_11590d6c}
#   - NOTE: 使用变量引用时，通过管道符以及命令替换等子进程调用时，引用的变量可以传递值，但是对引用的修改并不会影响到原值。因为是两个进程。
#   - NOTE: API 使用引用时，不管是否修改原变量，都不要使用命令替换，避免误操作。API 就不要输出任何东西了，避免误调用。
#   - NOTE: 有使用引用的函数，变量名必须使用 xxx_uuid 的形式，避免变量名重复覆盖引用。所以所有 API 的变量名都使用 uuid 的形式。
#   - NOTE: 所有 API 的 --data 都是原始配置数据
#   - NOTE: 所有 API 的 --result-data-ref 都是修改后配置数据的引用，虽然 get 请求不会修改原数据，但是为了统一get函数也提供这个参数。调用时统一也减少出错率。所有 API 的这个参数都是可选的，因为指定 filepath 时是可以不返回修改后的数据的。
#   - NOTE: 所有 API 的 --result-value-ref 都是返回值的变量的引用名字，可选参数。 如果必须返回，那么应该定义位置参数。
######################################## map 相关的接口 ########################################

# 获取 map 中指定 path 的值
# 说明：
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定原始配置数据
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   value                           string引用           指定返回值的变量的引用
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::map::get() {
    local is_sudo_9f1f6f02="${SHELL_FALSE}"
    local type_9f1f6f02
    local data_9f1f6f02
    local filepath_9f1f6f02
    local path_9f1f6f02
    local -n value_9f1f6f02

    local remain_param_9f1f6f02
    local param_9f1f6f02
    local extra_params_9f1f6f02=()

    remain_param_9f1f6f02=("$@")
    cfg::utils::_parse_common_parameter is_sudo_9f1f6f02 type_9f1f6f02 path_9f1f6f02 data_9f1f6f02 filepath_9f1f6f02 remain_param_9f1f6f02 || return "${SHELL_FALSE}"

    for param_9f1f6f02 in "${remain_param_9f1f6f02[@]}"; do
        case "$param_9f1f6f02" in
        --comment=*)
            extra_params_9f1f6f02+=("$param_9f1f6f02")
            ;;
        -*)
            lerror "invalid option: $param_9f1f6f02"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R value_9f1f6f02 ]; then
                value_9f1f6f02="$param_9f1f6f02"
                continue
            fi

            lerror "invalid param: $param_9f1f6f02"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R value_9f1f6f02 ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_9f1f6f02 data_9f1f6f02 "$filepath_9f1f6f02" || return "${SHELL_FALSE}"

    value_9f1f6f02=$("cfg::trait::$type_9f1f6f02::map::get" "$path_9f1f6f02" "$data_9f1f6f02" "${extra_params_9f1f6f02[@]}") || return "${SHELL_FALSE}"

    linfo "map get  value success. path=$path_9f1f6f02, value=$value_9f1f6f02"
    return "${SHELL_TRUE}"
}

# 判断 map 中是否存在指定 path
# 说明：
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::map::is_exists() {
    local is_sudo_0794c0f0="${SHELL_FALSE}"
    local type_0794c0f0
    local path_0794c0f0
    local data_0794c0f0
    local filepath_0794c0f0
    local remain_param_0794c0f0

    local param_0794c0f0
    local extra_params_0794c0f0=()

    remain_param_0794c0f0=("$@")
    cfg::utils::_parse_common_parameter is_sudo_0794c0f0 type_0794c0f0 path_0794c0f0 data_0794c0f0 filepath_0794c0f0 remain_param_0794c0f0 || return "${SHELL_FALSE}"

    for param_0794c0f0 in "${remain_param_0794c0f0[@]}"; do
        case "$param_0794c0f0" in
        --comment=*)
            extra_params_0794c0f0+=("$param_0794c0f0")
            ;;
        -*)
            lerror "invalid option: $param_0794c0f0"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param_0794c0f0"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    cfg::utils::_read_data data_0794c0f0 data_0794c0f0 "$filepath_0794c0f0" || return "${SHELL_FALSE}"

    "cfg::trait::$type_0794c0f0::map::is_exists" "$path_0794c0f0" "$data_0794c0f0" "${extra_params_0794c0f0[@]}" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 参考 cfg::map::is_exists
function cfg::map::is_not_exists() {
    ! cfg::map::is_exists "$@"
}

# 更新 map 中是指定 path 的值
# 说明：
# 1. 如果 map 中不存在指定 path，会创建相应的 path
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --write-file                    bool                是否将修改后的配置数据写入文件，默认为 false
#   --data                          string              指定配置数据
#   --result-data-ref               string 引用          保存修改后的配置数据的变量的引用
#   --result-value-ref              string 引用          保存旧的值的变量的引用
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   value                           string              需要更新的值
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::map::update() {
    local is_sudo_57a86f5d="${SHELL_FALSE}"
    local type_57a86f5d
    local data_57a86f5d
    local filepath_57a86f5d
    local is_write_file_57a86f5d="${SHELL_FALSE}"
    local result_data_ref_name_57a86f5d
    local result_ref_name_57a86f5d
    local path_57a86f5d
    local value_57a86f5d

    local result_data_shadow_57a86f5d
    local -n result_ref_57a86f5d
    local result_shadow_57a86f5d

    local remain_param_57a86f5d
    local old_value_57a86f5d

    local param_57a86f5d
    local extra_params_57a86f5d=()

    remain_param_57a86f5d=("$@")
    cfg::utils::_parse_common_parameter is_sudo_57a86f5d type_57a86f5d path_57a86f5d data_57a86f5d filepath_57a86f5d remain_param_57a86f5d || return "${SHELL_FALSE}"

    for param_57a86f5d in "${remain_param_57a86f5d[@]}"; do
        case "$param_57a86f5d" in
        --write-file | --write-file=*)
            parameter::parse_bool --default=y --option="$param_57a86f5d" is_write_file_57a86f5d || return "$SHELL_FALSE"
            ;;
        --comment=*)
            extra_params_57a86f5d+=("$param_57a86f5d")
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_57a86f5d" result_data_ref_name_57a86f5d || return "${SHELL_FALSE}"
            ;;
        --result-value-ref=*)
            parameter::parse_string --no-empty --option="$param_57a86f5d" result_ref_name_57a86f5d || return "${SHELL_FALSE}"
            result_ref_57a86f5d="$result_ref_name_57a86f5d"
            ;;
        -*)
            lerror "invalid option: $param_57a86f5d"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v value_57a86f5d ]; then
                value_57a86f5d="$param_57a86f5d"
                continue
            fi

            lerror "invalid param_57a86f5d: $param_57a86f5d"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v value_57a86f5d ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_57a86f5d data_57a86f5d "$filepath_57a86f5d" || return "${SHELL_FALSE}"

    "cfg::trait::$type_57a86f5d::map::update" --old-value-ref=result_shadow_57a86f5d result_data_shadow_57a86f5d "${path_57a86f5d}" "${value_57a86f5d}" "${data_57a86f5d}" "${extra_params_57a86f5d[@]}" || return "${SHELL_FALSE}"

    if [ -R result_ref_57a86f5d ] && [ -v result_shadow_57a86f5d ]; then
        cfg::utils::_write_ref result_ref_57a86f5d result_shadow_57a86f5d || return "${SHELL_FALSE}"
    fi

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_57a86f5d")" --write-file="$(string::print_yes_no "$is_write_file_57a86f5d")" --write-data-ref="$result_data_ref_name_57a86f5d" --filepath="$filepath_57a86f5d" "$result_data_shadow_57a86f5d" || return "${SHELL_FALSE}"

    linfo "map update path success. path=${path_57a86f5d}, value=${value_57a86f5d}, old_value=${old_value_57a86f5d}"
    return "${SHELL_TRUE}"
}

# map 中 pop 指定 path 的值
# 说明：
#   1. path 不存在时，返回失败
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --result-data-ref               string 引用          保存修改后的配置数据的变量的引用
#   --result-value-ref              string 引用          保存旧的值
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::map::pop() {
    local is_sudo_0985aadb="${SHELL_FALSE}"
    local type_0985aadb
    local filepath_0985aadb
    local data_0985aadb
    local result_data_ref_name_0985aadb
    local result_ref_name_0985aadb
    local path_0985aadb
    local remain_param_0985aadb

    local -n result_ref_0985aadb
    local result_shadow_0985aadb
    local result_data_shadow_0985aadb

    local param_0985aadb
    local extra_params_0985aadb=()

    remain_param_0985aadb=("$@")
    cfg::utils::_parse_common_parameter is_sudo_0985aadb type_0985aadb path_0985aadb data_0985aadb filepath_0985aadb remain_param_0985aadb || return "${SHELL_FALSE}"

    for param_0985aadb in "${remain_param_0985aadb[@]}"; do
        case "$param_0985aadb" in
        --comment=*)
            extra_params_0985aadb+=("$param_0985aadb")
            ;;
        --result-value-ref=*)
            parameter::parse_string --no-empty --option="$param_0985aadb" result_ref_name_0985aadb || return "${SHELL_FALSE}"
            result_ref_0985aadb="${result_ref_name_0985aadb}"
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_0985aadb" result_data_ref_name_0985aadb || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_0985aadb"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param_0985aadb"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    cfg::utils::_read_data data_0985aadb data_0985aadb "$filepath_0985aadb" || return "${SHELL_FALSE}"

    "cfg::trait::$type_0985aadb::map::pop" --old-value-ref=result_shadow_0985aadb result_data_shadow_0985aadb "${path_0985aadb}" "${data_0985aadb}" "${extra_params_0985aadb[@]}" || return "${SHELL_FALSE}"

    if [ -R result_ref_0985aadb ] && [ -v result_shadow_0985aadb ]; then
        cfg::utils::_write_ref result_ref_0985aadb result_shadow_0985aadb || return "${SHELL_FALSE}"
    fi

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_0985aadb")" --write-data-ref="$result_data_ref_name_0985aadb" --filepath="$filepath_0985aadb" "$result_data_shadow_0985aadb" || return "${SHELL_FALSE}"

    linfo "map pop path success. path=${path_0985aadb}, value=${result_shadow_0985aadb}"
    return "${SHELL_TRUE}"
}

# 删除 map 中指定 path
# 说明：
#   1. path 不存在时，返回成功
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --result-data-ref               string 引用          指定保存修改后的配置数据的变量的引用
#   --result-value-ref              string 引用         保存旧的值
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::map::delete() {
    local is_sudo_192676fa="${SHELL_FALSE}"
    local type_192676fa
    local filepath_192676fa
    local result_data_ref_name_192676fa
    local result_ref_name_192676fa
    local data_192676fa
    local path_192676fa
    local remain_param_192676fa

    local -n result_ref_192676fa
    local result_shadow_192676fa
    local -n result_data_ref_192676fa
    local result_data_shadow_192676fa

    local param_192676fa
    local extra_params_192676fa=()

    remain_param_192676fa=("$@")
    cfg::utils::_parse_common_parameter is_sudo_192676fa type_192676fa path_192676fa data_192676fa filepath_192676fa remain_param_192676fa || return "${SHELL_FALSE}"

    for param_192676fa in "${remain_param_192676fa[@]}"; do
        case "$param_192676fa" in
        --comment=*)
            extra_params_192676fa+=("$param_192676fa")
            ;;
        --result-value-ref=*)
            parameter::parse_string --no-empty --option="$param_192676fa" result_ref_name_192676fa || return "${SHELL_FALSE}"
            result_ref_192676fa="$result_ref_name_192676fa"
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_192676fa" result_data_ref_name_192676fa || return "${SHELL_FALSE}"
            result_data_ref_192676fa="$result_data_ref_name_192676fa"
            ;;
        -*)
            lerror "invalid option: $param_192676fa"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param_192676fa"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    cfg::utils::_read_data data_192676fa data_192676fa "$filepath_192676fa" || return "${SHELL_FALSE}"

    if ! "cfg::trait::$type_192676fa::map::is_exists" "${path_192676fa}" "${data_192676fa}" "${extra_params_192676fa[@]}"; then
        linfo "delete path success, path=(${path_192676fa}) not exists, ignore delete"
        if [ -R result_data_ref_192676fa ]; then
            result_data_ref_192676fa="${data_192676fa}"
        fi
        return "${SHELL_TRUE}"
    fi

    "cfg::trait::$type_192676fa::map::pop" --old-value-ref="result_shadow_192676fa" result_data_shadow_192676fa "${path_192676fa}" "${data_192676fa}" "${extra_params_192676fa[@]}" || return "${SHELL_FALSE}"

    if [ -R result_ref_192676fa ] && [ -v result_shadow_192676fa ]; then
        cfg::utils::_write_ref result_ref_192676fa result_shadow_192676fa || return "${SHELL_FALSE}"
    fi

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_192676fa")" --write-data-ref="$result_data_ref_name_192676fa" --filepath="$filepath_192676fa" "$result_data_shadow_192676fa" || return "${SHELL_FALSE}"

    linfo "map delete path success. path=${path_192676fa}, value=${result_shadow_192676fa}"
    return "${SHELL_TRUE}"
}

######################################## array 相关的接口 ########################################

# 获取数组全部的值
# 说明：
#   1. 当 path 不存在时，返回空数组
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   all                             数组的引用            存放所有元素的数组的引用
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::all() {
    local is_sudo_21234601="${SHELL_FALSE}"
    local type_21234601
    local data_21234601
    local filepath_21234601
    local path_21234601
    local remain_param_21234601
    local -n all_21234601

    local extra_params_21234601=()

    local param_21234601

    remain_param_21234601=("$@")
    cfg::utils::_parse_common_parameter is_sudo_21234601 type_21234601 path_21234601 data_21234601 filepath_21234601 remain_param_21234601 || return "${SHELL_FALSE}"

    for param_21234601 in "${remain_param_21234601[@]}"; do
        case "$param_21234601" in
        --separator=*)
            extra_params_21234601+=("$param_21234601")
            ;;
        --comment=*)
            extra_params_21234601+=("$param_21234601")
            ;;
        -*)
            lerror "invalid option: $param_21234601"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R all_21234601 ]; then
                all_21234601="$param_21234601"
                continue
            fi

            lerror "invalid param: $param_21234601"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R all_21234601 ]; then
        lerror "param all ref is required"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_21234601 data_21234601 "$filepath_21234601" || return "${SHELL_FALSE}"

    "cfg::trait::${type_21234601}::array::all" "${!all_21234601}" "${path_21234601}" "${data_21234601}" "${extra_params_21234601[@]}" || return "${SHELL_FALSE}"

    linfo "array get all item success. path=${path_21234601}"
    return "${SHELL_TRUE}"
}

# 获取数组的长度
# 说明：
#   1. 当 path 不存在时，认为数组为空数组，输出长度为 0
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   length                          int 引用             存放长度的引用
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::length() {
    local is_sudo_1a406daa="${SHELL_FALSE}"
    local type_1a406daa
    local data_1a406daa
    local filepath_1a406daa
    local path_1a406daa
    # shellcheck disable=SC2034
    local -n length_1a406daa

    local remain_param_1a406daa
    local extra_params_1a406daa=()
    # shellcheck disable=SC2034
    local items_1a406daa=()

    local param_1a406daa

    remain_param_1a406daa=("$@")
    cfg::utils::_parse_common_parameter is_sudo_1a406daa type_1a406daa path_1a406daa data_1a406daa filepath_1a406daa remain_param_1a406daa || return "${SHELL_FALSE}"

    for param_1a406daa in "${remain_param_1a406daa[@]}"; do
        case "$param_1a406daa" in
        --separator=*)
            extra_params_1a406daa+=("$param_1a406daa")
            ;;
        --comment=*)
            extra_params_1a406daa+=("$param_1a406daa")
            ;;
        -*)
            lerror "invalid option: $param_1a406daa"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R length_1a406daa ]; then
                length_1a406daa="$param_1a406daa"
                continue
            fi

            lerror "invalid param: $param_1a406daa"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R length_1a406daa ]; then
        lerror "param length is required"
        return "${SHELL_FALSE}"
    fi

    cfg::array::all --type="${type_1a406daa}" --filepath="${filepath_1a406daa}" --data="${data_1a406daa}" "$path_1a406daa" items_1a406daa "${extra_params_1a406daa[@]}" || return "${SHELL_FALSE}"

    length_1a406daa=$(array::length items_1a406daa) || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 获取数组指定下标的值
# 说明：
#   1. 当 path 不存在时，认为数组为空数组
#   2. 当 index 为正数且超过数组长度时，返回失败
#   3. 当 index 为负数时，可以从数组尾部开始计算，比如 -1 表示最后一个元素。负数会循环，所以不会超过数组范围
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   index                           int                 数组的下标
#   value                           string 引用         存放值的引用
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::get() {
    local is_sudo_62d33794="${SHELL_FALSE}"
    local type_62d33794
    local filepath_62d33794
    local data_62d33794

    local path_62d33794
    local index_62d33794
    local -n value_62d33794

    local remain_param_62d33794
    local convert_index_62d33794
    # shellcheck disable=SC2034
    local items_62d33794=()
    local length_62d33794
    local param_62d33794
    local extra_params_62d33794=()

    remain_param_62d33794=("$@")
    cfg::utils::_parse_common_parameter is_sudo_62d33794 type_62d33794 path_62d33794 data_62d33794 filepath_62d33794 remain_param_62d33794 || return "${SHELL_FALSE}"

    for param_62d33794 in "${remain_param_62d33794[@]}"; do
        case "$param_62d33794" in
        --separator=*)
            extra_params_62d33794+=("$param_62d33794")
            ;;
        --comment=*)
            extra_params_62d33794+=("$param_62d33794")
            ;;
        -*)
            # 负数是 - 开头的，所以这里需要判断一下
            if string::is_integer "${param_62d33794:1}" && [ ! -v index_62d33794 ]; then
                index_62d33794="$param_62d33794"
                continue
            fi
            lerror "invalid option: $param_62d33794"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v index_62d33794 ]; then
                index_62d33794="$param_62d33794"
                continue
            fi

            if [ ! -R value_62d33794 ]; then
                value_62d33794="$param_62d33794"
                continue
            fi

            lerror "invalid param: $param_62d33794"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v index_62d33794 ]; then
        lerror "param index is required"
        return "${SHELL_FALSE}"
    fi

    if [ ! -R value_62d33794 ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_integer "${index_62d33794}"; then
        lerror "param index=($index_62d33794) must be integer"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_62d33794 data_62d33794 "$filepath_62d33794" || return "${SHELL_FALSE}"

    "cfg::trait::${type_62d33794}::array::all" items_62d33794 "${path_62d33794}" "${data_62d33794}" "${extra_params_62d33794[@]}" || return "${SHELL_FALSE}"

    # 检查 index 是否合法
    length_62d33794=$(array::length items_62d33794) || return "${SHELL_FALSE}"
    if ! convert_index_62d33794=$(array::convert_index items_62d33794 "${index_62d33794}"); then
        lerror "index($index_62d33794) convert to ${convert_index_62d33794} is out of range, array length=${length_62d33794}."
        return "${SHELL_FALSE}"
    fi

    value_62d33794=$(array::get items_62d33794 "${convert_index_62d33794}") || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 更新数组成新的数组
# 说明：
#   1. 当 path 不存在时，会创建新的数组
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --result-data-ref               string 引用         保存修改后的配置数据的变量的引用
#   --result-value-ref              string 引用         保存旧的值
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   new                             数组引用             新的数组的引用
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::update_all() {
    local is_sudo_321b1217="${SHELL_FALSE}"
    local type_321b1217
    local data_321b1217
    local filepath_321b1217
    local result_ref_name_321b1217
    local result_data_ref_name_321b1217
    local path_321b1217
    local -n new_321b1217

    local result_shadow_321b1217
    local result_data_shadow_321b1217
    local remain_param_321b1217

    # shellcheck disable=SC2034
    local temp_321b1217

    local param_321b1217
    local extra_params_321b1217=()

    remain_param_321b1217=("$@")
    cfg::utils::_parse_common_parameter is_sudo_321b1217 type_321b1217 path_321b1217 data_321b1217 filepath_321b1217 remain_param_321b1217 "$@" || return "${SHELL_FALSE}"

    for param_321b1217 in "${remain_param_321b1217[@]}"; do
        case "$param_321b1217" in
        --separator=*)
            extra_params_321b1217+=("$param_321b1217")
            ;;
        --comment=*)
            extra_params_321b1217+=("$param_321b1217")
            ;;
        --result-value-ref=*)
            parameter::parse_string --no-empty --option="$param_321b1217" result_ref_name_321b1217 || return "${SHELL_FALSE}"
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_321b1217" result_data_ref_name_321b1217 || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_321b1217"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R new_321b1217 ]; then
                new_321b1217="$param_321b1217"
                continue
            fi

            lerror "invalid param: $param_321b1217"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R new_321b1217 ]; then
        lerror "param new is required"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_321b1217 data_321b1217 "$filepath_321b1217" || return "${SHELL_FALSE}"

    "cfg::trait::${type_321b1217}::array::update_all" --old-value-ref=result_shadow_321b1217 result_data_shadow_321b1217 "${path_321b1217}" "${!new_321b1217}" "${data_321b1217}" "${extra_params_321b1217[@]}" || return "${SHELL_FALSE}"

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_321b1217")" --write-data-ref="$result_data_ref_name_321b1217" --filepath="$filepath_321b1217" "$result_data_shadow_321b1217" || return "${SHELL_FALSE}"

    if string::is_not_empty "$result_ref_name_321b1217" && [ -v result_shadow_321b1217 ]; then
        cfg::utils::_write_ref "$result_ref_name_321b1217" result_shadow_321b1217 || return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# 删除指定下标的数组元素
# 说明：
#   1. 当 path 不存在时，数组不存在，删除失败
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --result-data-ref               string 引用          保存修改后的配置数据的变量的引用
#   --result-value-ref              string 引用          保存旧的值
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string              JSONPath
#   index                           int                 删除元素的下标
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::remove_at() {
    local is_sudo_9f528442="${SHELL_FALSE}"
    local type_9f528442
    local data_9f528442
    local filepath_9f528442
    local result_data_ref_name_9f528442
    local result_ref_name_9f528442
    local path_9f528442
    local index_9f528442

    local result_data_shadow_9f528442
    local remain_param_9f528442
    local convert_index_9f528442
    # shellcheck disable=SC2034
    local items_9f528442
    local length_9f528442

    local param_9f528442
    local extra_params_9f528442=()

    remain_param_9f528442=("$@")
    cfg::utils::_parse_common_parameter is_sudo_9f528442 type_9f528442 path_9f528442 data_9f528442 filepath_9f528442 remain_param_9f528442 || return "${SHELL_FALSE}"

    for param_9f528442 in "${remain_param_9f528442[@]}"; do
        case "$param_9f528442" in
        --separator=*)
            extra_params_9f528442+=("$param_9f528442")
            ;;
        --comment=*)
            extra_params_9f528442+=("$param_9f528442")
            ;;
        --result-value-ref=*)
            parameter::parse_string --no-empty --option="$param_9f528442" result_ref_name_9f528442 || return "${SHELL_FALSE}"
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_9f528442" result_data_ref_name_9f528442 || return "${SHELL_FALSE}"
            ;;
        -*)
            if string::is_integer "${param_9f528442:1}" && [ ! -v index_9f528442 ]; then
                index_9f528442="$param_9f528442"
                continue
            fi
            lerror "invalid option: $param_9f528442"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v index_9f528442 ]; then
                index_9f528442="$param_9f528442"
                continue
            fi

            lerror "invalid param: $param_9f528442"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v index_9f528442 ]; then
        lerror "param index is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_integer "${index_9f528442}"; then
        lerror "param index=($index_9f528442) must be integer"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_9f528442 data_9f528442 "$filepath_9f528442" || return "${SHELL_FALSE}"

    "cfg::trait::${type_9f528442}::array::all" items_9f528442 "${path_9f528442}" "${data_9f528442}" "${extra_params_9f528442[@]}" || return "${SHELL_FALSE}"

    length_9f528442=$(array::length items_9f528442) || return "${SHELL_FALSE}"
    if ! convert_index_9f528442=$(array::convert_index items_9f528442 "${index_9f528442}"); then
        lerror "index($index_9f528442) convert to ${convert_index_9f528442} is out of range, array length=${length_9f528442}."
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "${result_ref_name_9f528442}"; then
        array::remove_at "${result_ref_name_9f528442}" items_9f528442 "${convert_index_9f528442}" || return "${SHELL_FALSE}"
    else
        array::remove_at REF_PLACEHOLDER items_9f528442 "${convert_index_9f528442}" || return "${SHELL_FALSE}"
    fi

    "cfg::trait::${type_9f528442}::array::update_all" result_data_shadow_9f528442 "${path_9f528442}" items_9f528442 "${data_9f528442}" "${extra_params_9f528442[@]}" || return "${SHELL_FALSE}"

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_9f528442")" --write-data-ref="$result_data_ref_name_9f528442" --filepath="$filepath_9f528442" "$result_data_shadow_9f528442" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 删除数组中相等的元素
# 说明：
#   1. 当 path 不存在时，数组不存在，删除成功
#   2. 数组中没有相等的元素时，删除成功
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --comment                       string              指定注释的字符串
#   --result-data-ref               string 引用         保存修改后的配置数据的变量的引用
# 位置参数：
#   path                            string              JSONPath
#   value                           string              需要删除的值
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::remove() {
    local is_sudo_3441cf8e="${SHELL_FALSE}"
    local type_3441cf8e
    local filepath_3441cf8e
    local data_3441cf8e
    local result_data_ref_name_3441cf8e
    local comment_3441cf8e
    local path_3441cf8e
    local value_3441cf8e

    local -n result_data_ref_3441cf8e
    local result_data_shadow_3441cf8e

    local remain_param_3441cf8e
    # shellcheck disable=SC2034
    local items_3441cf8e

    local param_3441cf8e
    local extra_params_3441cf8e=()

    remain_param_3441cf8e=("$@")
    cfg::utils::_parse_common_parameter is_sudo_3441cf8e type_3441cf8e path_3441cf8e data_3441cf8e filepath_3441cf8e remain_param_3441cf8e || return "${SHELL_FALSE}"

    for param_3441cf8e in "${remain_param_3441cf8e[@]}"; do
        case "$param_3441cf8e" in
        --separator=*)
            extra_params_3441cf8e+=("$param_3441cf8e")
            ;;
        --comment=*)
            parameter::parse_string --option="$param_3441cf8e" comment_3441cf8e || return "${SHELL_FALSE}"
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_3441cf8e" result_data_ref_name_3441cf8e || return "${SHELL_FALSE}"
            result_data_ref_3441cf8e="$result_data_ref_name_3441cf8e"
            ;;
        -*)
            lerror "invalid option: $param_3441cf8e"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v value_3441cf8e ]; then
                value_3441cf8e="$param_3441cf8e"
                continue
            fi

            lerror "invalid param: $param_3441cf8e"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v value_3441cf8e ]; then
        lerror "param value is required"
        return "${SHELL_FALSE}"
    fi

    cfg::utils::_read_data data_3441cf8e data_3441cf8e "$filepath_3441cf8e" || return "${SHELL_FALSE}"

    if [ -R result_data_ref_3441cf8e ]; then
        # 先赋值原始的数据，保证有一些不需要修改的场景直接返回正确时，也需要返回配置数据
        result_data_ref_3441cf8e="${data_3441cf8e}"
    fi

    if ! "cfg::trait::$type_3441cf8e::map::is_exists" "${path_3441cf8e}" "${data_3441cf8e}" "--comment=${comment_3441cf8e}"; then
        linfo "path in data not exists, path=${path_3441cf8e}"
        return "${SHELL_TRUE}"
    fi

    "cfg::trait::${type_3441cf8e}::array::all" items_3441cf8e "${path_3441cf8e}" "${data_3441cf8e}" "--comment=${comment_3441cf8e}" "${extra_params_3441cf8e[@]}" || return "${SHELL_FALSE}"

    if array::is_not_contain items_3441cf8e "${value_3441cf8e}"; then
        linfo "item(${value_3441cf8e}) is not exists in array, skip remove"
        return "${SHELL_TRUE}"
    fi

    array::remove items_3441cf8e "${value_3441cf8e}" || return "${SHELL_FALSE}"

    "cfg::trait::${type_3441cf8e}::array::update_all" result_data_shadow_3441cf8e "${path_3441cf8e}" items_3441cf8e "${data_3441cf8e}" "--comment=${comment_3441cf8e}" "${extra_params_3441cf8e[@]}" || return "${SHELL_FALSE}"

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_3441cf8e")" --write-data-ref="$result_data_ref_name_3441cf8e" --filepath="$filepath_3441cf8e" "$result_data_shadow_3441cf8e" || return "${SHELL_FALSE}"

    return "${SHELL_TRUE}"
}

# 删除数组所有的元素
# 说明：
#   1. 当 path 不存在时，数组不存在，删除成功
# 可选参数：
#   --sudo                          string              指定是否使用 sudo
#   --type                          string              指定配置类型，默认为 json
#   --filepath                      string              指定配置文件路径
#   --data                          string              指定配置数据
#   --separator                     string              用于某些配置格式将字符串解析数组时的分隔符，默认为 ','
#   --result-data-ref               string 引用         保存修改后的配置数据的变量的引用
#   --result-value-ref              string 引用         保存旧的值
#   --comment                       string              指定注释的字符串
# 位置参数：
#   path                            string      JSONPath
# 标准输出： 无
# 返回值：
#   ${SHELL_TRUE} 成功
#   ${SHELL_FALSE} 失败
function cfg::array::clear() {
    local is_sudo_0c36228e="${SHELL_FALSE}"
    local type_0c36228e
    local data_0c36228e
    local filepath_0c36228e
    local result_ref_name_0c36228e
    local result_data_ref_name_0c36228e
    local separator_0c36228e
    local comment_0c36228e
    local path_0c36228e

    local -n result_data_ref_0c36228e
    local result_data_shadow_0c36228e
    local result_shadow_0c36228e
    local remain_param_0c36228e
    # shellcheck disable=SC2034
    local items_0c36228e

    local param_0c36228e

    remain_param_0c36228e=("$@")
    cfg::utils::_parse_common_parameter is_sudo_0c36228e type_0c36228e path_0c36228e data_0c36228e filepath_0c36228e remain_param_0c36228e || return "${SHELL_FALSE}"

    for param_0c36228e in "${remain_param_0c36228e[@]}"; do
        case "$param_0c36228e" in
        --separator=*)
            parameter::parse_string --option="$param_0c36228e" separator_0c36228e || return "${SHELL_FALSE}"
            ;;
        --comment=*)
            parameter::parse_string --option="$param_0c36228e" comment_0c36228e || return "${SHELL_FALSE}"
            ;;
        --result-value-ref=*)
            parameter::parse_string --no-empty --option="$param_0c36228e" result_ref_name_0c36228e || return "${SHELL_FALSE}"
            ;;
        --result-data-ref=*)
            parameter::parse_string --no-empty --option="$param_0c36228e" result_data_ref_name_0c36228e || return "${SHELL_FALSE}"
            result_data_ref_0c36228e="${result_data_ref_name_0c36228e}"
            ;;
        -*)
            lerror "invalid option: $param_0c36228e"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param_0c36228e"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    cfg::utils::_read_data data_0c36228e data_0c36228e "$filepath_0c36228e" || return "${SHELL_FALSE}"

    if ! "cfg::trait::$type_0c36228e::map::is_exists" "${path_0c36228e}" "${data_0c36228e}" "--comment=${comment_0c36228e}"; then
        linfo "path in data not exists, path=${path_0c36228e}"

        if [ -R result_data_ref_0c36228e ]; then
            result_data_ref_0c36228e="${data_0c36228e}"
        fi
        return "${SHELL_TRUE}"
    fi

    "cfg::trait::${type_0c36228e}::array::all" items_0c36228e "${path_0c36228e}" "${data_0c36228e}" "--comment=${comment_0c36228e}" "--separator=${separator_0c36228e}" || return "${SHELL_FALSE}"

    if string::is_not_empty "${result_ref_name_0c36228e}"; then
        cfg::utils::_write_ref "${result_ref_name_0c36228e}" items_0c36228e || return "${SHELL_FALSE}"
    fi

    "cfg::trait::${type_0c36228e}::map::pop" --old-value-ref=result_shadow_0c36228e result_data_shadow_0c36228e "${path_0c36228e}" "${data_0c36228e}" "--comment=${comment_0c36228e}" || return "${SHELL_FALSE}"

    cfg::utils::_write_data --sudo="$(string::print_yes_no "$is_sudo_0c36228e")" --write-data-ref="$result_data_ref_name_0c36228e" --filepath="$filepath_0c36228e" "$result_data_shadow_0c36228e" || return "${SHELL_FALSE}"

    if string::is_not_empty "${result_ref_name_0c36228e}"; then
        string::split_with items_0c36228e "${result_shadow_0c36228e}" "${separator_0c36228e}" || return "${SHELL_FALSE}"
        cfg::utils::_write_ref "${result_ref_name_0c36228e}" items_0c36228e || return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# ====================================== trait json 测试代码 ======================================
######################################## map 测试代码 ########################################
######################################## array 测试代码 ########################################

# ====================================== trait ini 测试代码 ======================================

######################################## map 测试代码 ########################################

function TEST::cfg::map::get::trait::ini() {
    local value
    local data

    # 不存在 section
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123'
    cfg::map::get --type=ini "--data=$data" '.test1.name' value
    utest::assert_fail $?
    utest::assert_equal "${value}" ""

    # 存在 section，不存在 key , section 后面没有其他的 section
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123'
    cfg::map::get --type=ini "--data=$data" '.test2.name' value
    utest::assert_fail $?
    utest::assert_equal "${value}" ""

    # 存在 section，不存在 key , section 后面存在其他的 section
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123'
    cfg::map::get --type=ini "--data=$data" '.test1.name1' value
    utest::assert_fail $?
    utest::assert_equal "${value}" ""

    # 存在 section，存在 key , section 后面没有其他的 section
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123'
    cfg::map::get --type=ini "--data=$data" '.test2.name' value
    utest::assert $?
    utest::assert_equal "${value}" "123"

    # 存在 section，存在 key , section 后面存在其他的 section
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123'
    cfg::map::get --type=ini "--data=$data" '.test1.name' value
    utest::assert $?
    utest::assert_equal "${value}" "abc"
}

function TEST::cfg::map::is_exists::trait::ini() {
    local data

    # 不存在 section
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123'
    cfg::map::is_exists --type=ini "--data=$data" '.test1.name'
    utest::assert_fail $?

    # 存在 section，不存在 key , section 后面没有其他的 section
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123'
    cfg::map::is_exists --type=ini "--data=$data" '.test2.name'
    utest::assert_fail $?

    # 存在 section，存在 key
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123'
    cfg::map::is_exists --type=ini "--data=$data" '.test2.name'
    utest::assert $?
}

function TEST::cfg::map::update::trait::ini() {
    local data
    local value
    local old_value
    local result_data

    # 不存在 section
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123\n'
    value="xxx"
    cfg::map::update --type=ini "--data=$data" --result-data-ref=result_data --result-value-ref=old_value '.test1.name' "${value}"
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test2]\nname=123\n[test1]\nname=xxx\n'
    utest::assert_equal "${old_value}" ""

    # 存在 section，不存在 key
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    value="xxx"
    cfg::map::update --type=ini "--data=$data" --result-data-ref=result_data --result-value-ref=old_value '.test2.name' "${value}"
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname1=123\nname=xxx\n'
    utest::assert_equal "${old_value}" ""

    # 存在 section，存在 key
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123\n'
    value="xxx"
    cfg::map::update --type=ini "--data=$data" --result-data-ref=result_data --result-value-ref=old_value '.test2.name' "${value}"
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=xxx\n'
    utest::assert_equal "${old_value}" "123"
}

function TEST::cfg::map::pop::trait::ini() {
    local data
    local old_value
    local result_data

    # 不存在 section
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123\n'
    cfg::map::pop --type=ini "--data=$data" --result-data-ref=result_data --result-value-ref=old_value '.test1.name'
    utest::assert_fail $?
    utest::assert_equal "${result_data}" $''
    utest::assert_equal "${old_value}" ""

    # 存在 section，不存在 key
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::map::pop --type=ini "--data=$data" --result-data-ref=result_data --result-value-ref=old_value '.test2.name'
    utest::assert_fail $?
    utest::assert_equal "${result_data}" $''
    utest::assert_equal "${old_value}" ""

    # 存在 section，存在 key
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123\n'
    cfg::map::pop --type=ini "--data=$data" --result-data-ref=result_data --result-value-ref=old_value '.test2.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\n'
    utest::assert_equal "${old_value}" "123"
}

function TEST::cfg::map::delete::trait::ini() {
    local data
    local old_value
    local result_data

    # 不存在 section
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123\n'
    cfg::map::delete --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test1.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test2]\nname=123\n'
    utest::assert_equal "${old_value}" ""

    # 存在 section，不存在 key
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::map::delete --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test2.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname1=123\n'
    utest::assert_equal "${old_value}" ""

    # 存在 section，存在 key
    old_value=""
    result_data=""
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123\n'
    cfg::map::delete --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test2.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\n'
    utest::assert_equal "${old_value}" "123"
}

######################################## array 测试代码 ########################################

function TEST::cfg::array::all::trait::ini() {
    local data
    local result

    # 不存在 section
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123\n'
    cfg::array::all --type=ini --data="$data" '.test1.name' result
    utest::assert $?
    utest::assert_equal "${data}" $'[test2]\nname=123\n'
    utest::assert_equal "${result[*]}" ""

    # 存在 section，不存在 key
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::array::all --type=ini --data="$data" '.test2.name' result
    utest::assert $?
    utest::assert_equal "${data}" $'[test1]\nname=abc\n[test2]\nname1=123\n'
    utest::assert_equal "${result[*]}" ""

    # 存在 section，存在 key
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123,456\n'
    cfg::array::all --type=ini --data="$data" '.test2.name' result
    utest::assert $?
    utest::assert_equal "${data}" $'[test1]\nname=abc\n[test2]\nname=123,456\n'
    utest::assert_equal "${result[*]}" "123 456"
}

function TEST::cfg::array::length::trait::ini() {
    local length
    local data

    # 不存在 section
    length=0
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123\n'
    cfg::array::length --type=ini --data="$data" '.test1.name' length
    utest::assert $?
    utest::assert_equal "${length}" "0"

    # 存在 section，不存在 key
    length=0
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::array::length --type=ini --data="$data" '.test2.name' length
    utest::assert $?
    utest::assert_equal "${length}" "0"

    # 存在 section，存在 key
    length=0
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123,456\n'
    cfg::array::length --type=ini --data="$data" '.test2.name' length
    utest::assert $?
    utest::assert_equal "${length}" "2"
}

function TEST::cfg::array::get::trait::ini() {
    local value
    local data

    # 不存在 section
    # shellcheck disable=SC2034
    data=$'[test2]\nname=123'
    cfg::array::get --type=ini --data="$data" '.test1.name' 0 value
    utest::assert_fail $?
    utest::assert_equal "${value}" ""
    utest::assert_equal "${data}" $'[test2]\nname=123'

    # 存在 section，不存在 key
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname1=123'
    cfg::array::get --type=ini --data="$data" '.test2.name' 0 value
    utest::assert_fail $?
    utest::assert_equal "${value}" ""
    utest::assert_equal "${data}" $'[test1]\nname=abc\n[test2]\nname1=123'

    # 存在 section，存在 key
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123,456'
    cfg::array::get --type=ini --data="$data" '.test2.name' 0 value
    utest::assert $?
    utest::assert_equal "${value}" "123"
    utest::assert_equal "${data}" $'[test1]\nname=abc\n[test2]\nname=123,456'

    # 存在 section，存在 key
    # shellcheck disable=SC2034
    data=$'[test1]\nname=abc\n[test2]\nname=123,456'
    cfg::array::get --type=ini --data="$data" '.test2.name' "-11" value
    utest::assert $?
    utest::assert_equal "${value}" "456"
    utest::assert_equal "${data}" $'[test1]\nname=abc\n[test2]\nname=123,456'
}

function TEST::cfg::array::update_all::trait::ini() {
    local data
    local result_data
    local old_value
    local new

    # 不存在 section
    old_value=()
    result_data=""
    # shellcheck disable=SC2034
    new=("abc" "123" "!@#")
    data=$'[test2]\nname=123\n'
    cfg::array::update_all --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data --separator=';' '.test1.name' new
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test2]\nname=123\n[test1]\nname=abc;123;!@#\n'
    utest::assert_equal "${old_value[*]}" $''

    # 存在 section，不存在 key
    old_value=()
    result_data=""
    # shellcheck disable=SC2034
    new=("abc" "123" "!@#")
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::array::update_all --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data --separator=';' '.test2.name' new
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname1=123\nname=abc;123;!@#\n'
    utest::assert_equal "${old_value[*]}" $''

    # 存在 section，存在 key
    old_value=()
    result_data=""
    # shellcheck disable=SC2034
    new=("abc" "123" "!@#")
    data=$'[test1]\nname=abc\n[test2]\nname=123,456\n'
    cfg::array::update_all --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test2.name' new
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=abc,123,!@#\n'
    utest::assert_equal "${old_value[*]}" $'123 456'

    # 存在 section，存在 key 使用不同的分隔符
    old_value=()
    result_data=""
    # shellcheck disable=SC2034
    new=("abc" "123" "!@#")
    data=$'[test1]\nname=abc\n[test2]\nname=123,456;abc;def\n'
    cfg::array::update_all --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data --separator=';' '.test2.name' new
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=abc;123;!@#\n'
    utest::assert_equal "${old_value[*]}" $'123,456 abc def'
}

function TEST::cfg::array::remove_at::trait::ini() {
    local data
    local result_data
    local old_value

    # 不存在 section
    result_data=""
    old_value=""
    data=$'[test2]\nname=123\n'
    cfg::array::remove_at --type=ini --data="$data" --result-data-ref=result_data --result-value-ref=old_value '.test1.name' 0
    utest::assert_fail $?
    utest::assert_equal "${data}" $'[test2]\nname=123\n'
    utest::assert_equal "${old_value}" $''

    # 存在 section，不存在 key
    result_data=""
    old_value=""
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::array::remove_at --type=ini --data="$data" --result-data-ref=result_data --result-value-ref=old_value '.test2.name' 0
    utest::assert_fail $?
    utest::assert_equal "${data}" $'[test1]\nname=abc\n[test2]\nname1=123\n'
    utest::assert_equal "${old_value}" $''

    # 存在 section，存在 key
    result_data=""
    old_value=""
    data=$'[test1]\nname=abc\n[test2]\nname=123,456\n'
    cfg::array::remove_at --type=ini --data="$data" --result-data-ref=result_data --result-value-ref=old_value '.test2.name' 0
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=456\n'
    utest::assert_equal "${old_value}" $'123'

    # 存在 section 存在 key ，测试负数下标和不同的分隔符
    result_data=""
    old_value=""
    data=$'[test1]\nname=abc\n[test2]\nname=123;456;  xxx;55\n'
    cfg::array::remove_at --type=ini --data="$data" --result-data-ref=result_data --result-value-ref=old_value --separator=';' '.test2.name' -3
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=123;  xxx;55\n'
    utest::assert_equal "${old_value}" $'456'
}

function TEST::cfg::array::remove::trait::ini() {
    local data
    local value
    local result_data

    # section 不存在
    result_data=""
    data=$'[test2]\nname=123\n'
    cfg::array::remove --type=ini "--data=$data" --result-data-ref=result_data '.test1.name' 'abc'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test2]\nname=123\n'

    # section 存在，key 不存在
    result_data=""
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::array::remove --type=ini "--data=$data" --result-data-ref=result_data '.test2.name' 'abc'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname1=123\n'

    # section 存在 key 存在，数组里没有要删除的元素
    result_data=""
    data=$'[test1]\nname=abc\n[test2]\nname=123,456\n'
    cfg::array::remove --type=ini "--data=$data" --result-data-ref=result_data '.test2.name' 'abc'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=123,456\n'

    # section 存在 key 存在，数组里有要删除的元素
    result_data=""
    data=$'[test1]\nname=abc\n[test2]\nname=123,456\n'
    cfg::array::remove --type=ini "--data=$data" --result-data-ref=result_data '.test2.name' '456'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=123\n'

    # section 存在 key 存在，数组里有重复要删除的元素，使用不同的分隔符
    result_data=""
    data=$'[test1]\nname=abc\n[test2]\nname=123;456;  xxx;55;456;zzz;456\n'
    cfg::array::remove --type=ini "--data=$data" --result-data-ref=result_data --separator=';' '.test2.name' '456'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname=123;  xxx;55;zzz\n'
}

function TEST::cfg::array::clear::trait::ini() {
    local data
    local result_data
    local old_value

    # section 不存在
    result_data=""
    old_value=()
    data=$'[test2]\nname=123\n'
    cfg::array::clear --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test1.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test2]\nname=123\n'
    utest::assert_equal "${old_value[*]}" ""

    # section 存在， key 不存在
    result_data=""
    old_value=()
    data=$'[test1]\nname=abc\n[test2]\nname1=123\n'
    cfg::array::clear --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test2.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\nname1=123\n'
    utest::assert_equal "${old_value[*]}" ""

    # section 存在， key 存在， 数组是空数组
    result_data=""
    old_value=()
    data=$'[test1]\nname=abc\n[test2]\nname=\n'
    cfg::array::clear --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data '.test2.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\n'
    utest::assert_equal "${old_value[*]}" $''

    # section 存在， key 存在，数组有元素，测试不同的分隔符
    result_data=""
    old_value=()
    data=$'[test1]\nname=abc\n[test2]\nname=123;456;   abc ;d;e;f\n'
    cfg::array::clear --type=ini --data="$data" --result-value-ref=old_value --result-data-ref=result_data --separator=';' '.test2.name'
    utest::assert $?
    utest::assert_equal "${result_data}" $'[test1]\nname=abc\n[test2]\n'
    utest::assert_equal "${old_value[*]}" $'123 456    abc  d e f'
}
