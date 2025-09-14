#!/bin/bash

if [ -n "${SCRIPT_DIR_28e227a8}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_28e227a8="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../process.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_28e227a8}/../os/os.sh"

# 获取所有 hyprland 实例
function hyprland::hyprctl::instance::all() {
    # shellcheck disable=SC2034
    local -n instances_d2d9c003="$1"
    shift

    local temp_d2d9c003

    temp_d2d9c003=$(hyprctl instances -j 2> >(lwrite)) || return "$SHELL_FALSE"
    temp_d2d9c003=$(echo "${temp_d2d9c003}" | grep instance | awk -F '"' '{print $4}')

    array::readarray instances_d2d9c003 <<<"${temp_d2d9c003}"

    return "$SHELL_TRUE"
}

# 获取 hyprland 实例的 pid
function hyprland::hyprctl::instance::pid() {
    local instance="$1"

    local pid

    pid="$(hyprctl instances -j)" || return "$SHELL_FALSE"
    pid=$(echo "${pid}" | yq ".[] | select(.instance == \"${instance}\") | .pid") || return "$SHELL_FALSE"

    echo "$pid"

    return "$SHELL_TRUE"
}

# 获取当前用户的所有 hyprland 实例
function hyprland::hyprctl::instance::all_by_username() {
    # shellcheck disable=SC2034
    local -n instances_22de1eba="$1"
    shift
    local username_22de1eba="$1"
    shift

    local all_22de1eba=()
    local temp_22de1eba
    local pid_22de1eba
    local process_username_22de1eba

    hyprland::hyprctl::instance::all all_22de1eba || return "$SHELL_FALSE"

    instances_22de1eba=()
    for temp_22de1eba in "${all_22de1eba[@]}"; do
        pid_22de1eba=$(hyprland::hyprctl::instance::pid "$temp_22de1eba") || return "$SHELL_FALSE"
        process_username_22de1eba=$(process::get_username "$pid_22de1eba") || return "$SHELL_FALSE"
        if [ "$process_username_22de1eba" == "$username_22de1eba" ]; then
            instances_22de1eba+=("$temp_22de1eba")
        fi
    done

    return "$SHELL_TRUE"
}

# 获取 hyprland 实例版本
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 版本信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::version() {
    local instance

    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    local temp_str
    temp_str=$(hyprctl -j version "${instance_params[@]}")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland version failed, instance=${instance}, err=${temp_str}"
        return "$SHELL_FALSE"
    fi
    echo "$temp_str"
    return "$SHELL_TRUE"
}

# 获取 hyprland 实例版本的 tag 信息
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 版本的 tag 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::version::tag() {

    local instance

    local tag
    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    tag=$(hyprctl -j version "${instance_params[@]}") || return "$SHELL_FALSE"
    tag=$(echo "$tag" | yq '.tag')
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland version tag failed, instance=${instance}, err=${tag}"
        return "$SHELL_FALSE"
    fi
    echo "$tag"
    return "$SHELL_TRUE"
}

# 检查 hyprland 实例是否可以连接
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 版本的 tag 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::is_can_connect() {
    hyprland::hyprctl::instance::version "$@" >/dev/null 2>&1 || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function hyprland::hyprctl::instance::is_not_can_connect() {
    ! hyprland::hyprctl::instance::is_can_connect "$@"
}

# hyprland 实例重新加载
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 无
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::reload() {

    local instance

    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl reload "${instance_params[@]}" || return "$SHELL_FALSE"

    linfo "reload hyprland config success. instance=${instance}"

    return "$SHELL_TRUE"
}

# 禁用 hyprland 实例的自动加载功能
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 无
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::autoreload::disable() {
    local instance

    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl keyword "misc:disable_autoreload" true "${instance_params[@]}" || return "$SHELL_FALSE"

    linfo "disable hyprland config autoreload success. instance=${instance}"

    return "$SHELL_TRUE"
}

# 启用 hyprland 实例的自动加载功能
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 无
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::autoreload::enable() {
    local instance

    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl keyword "misc:disable_autoreload" false "${instance_params[@]}" || return "$SHELL_FALSE"

    linfo "disable hyprland config autoreload success. instance=${instance}"

    return "$SHELL_TRUE"
}

# 获取 hyprland 实例的 option 值
# 说明：
# 位置参数：
#   option                          需要获取的 option
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 获取的 option 值
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::getoption() {
    local instance
    local option

    local temp
    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v option ]; then
                option="$param"
                continue
            fi
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v option ]; then
        lerror "param option is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    temp=$(hyprctl -j getoption "$option" "${instance_params[@]}")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland option failed, instance=${instance}, option=${option}, err=${temp}"
        return "$SHELL_FALSE"
    fi
    echo "$temp"
    return "$SHELL_TRUE"
}

# 获取 hyprland 实例的 monitors 信息
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 获取的 monitors 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::monitors() {
    local instance

    local value
    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    value=$(hyprctl -j monitors "${instance_params[@]}")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland monitors failed, instance=${instance}, err=${value}"
        return "$SHELL_FALSE"
    fi

    echo "$value"

    return "$SHELL_TRUE"
}

# 获取所有显示器的id列表
# 列表通过距离原点的距离进行排序
function hyprland::hyprctl::instance::monitors::sort_by_distance() {
    local -n monitors_name_44c8c1ef

    local monitors_44c8c1ef
    local monitor_count_44c8c1ef
    local index_44c8c1ef
    local id_44c8c1ef
    local name_44c8c1ef
    local description_44c8c1ef
    local temp_44c8c1ef
    local distance_44c8c1ef=0
    local x_44c8c1ef
    local y_44c8c1ef
    local min_index_44c8c1ef=0
    local min_distance_44c8c1ef=-1

    local instance_params_44c8c1ef=()
    local instance_44c8c1ef
    local param_44c8c1ef

    for param_44c8c1ef in "$@"; do
        case "$param_44c8c1ef" in
        --instance=*)
            parameter::parse_string --option="$param_44c8c1ef" instance_44c8c1ef || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_44c8c1ef"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R monitors_name_44c8c1ef ]; then
                monitors_name_44c8c1ef="${param_44c8c1ef}"
                continue
            fi
            lerror "invalid param: $param_44c8c1ef"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R monitors_name_44c8c1ef ]; then
        lerror "param monitors_name is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$instance_44c8c1ef"; then
        instance_params_44c8c1ef+=("-i" "$instance_44c8c1ef")
    fi

    monitors_44c8c1ef="$(hyprctl monitors -j "${instance_params_44c8c1ef[@]}")" || return "$SHELL_FALSE"
    monitor_count_44c8c1ef=$(echo "$monitors_44c8c1ef" | yq 'length')

    temp_44c8c1ef=()
    for ((index_44c8c1ef = 0; index_44c8c1ef < monitor_count_44c8c1ef; index_44c8c1ef++)); do
        id_44c8c1ef="$(echo "$monitors_44c8c1ef" | yq ".[${index_44c8c1ef}].id")" || return "$SHELL_FALSE"
        name_44c8c1ef="$(echo "$monitors_44c8c1ef" | yq ".[${index_44c8c1ef}].name")" || return "$SHELL_FALSE"
        description_44c8c1ef="$(echo "$monitors_44c8c1ef" | yq ".[${index_44c8c1ef}].description")" || return "$SHELL_FALSE"
        x_44c8c1ef="$(echo "$monitors_44c8c1ef" | yq ".[${index_44c8c1ef}].x")" || return "$SHELL_FALSE"
        y_44c8c1ef="$(echo "$monitors_44c8c1ef" | yq ".[${index_44c8c1ef}].y")" || return "$SHELL_FALSE"
        distance_44c8c1ef=$((x_44c8c1ef * x_44c8c1ef + y_44c8c1ef * y_44c8c1ef))

        array::rpush temp_44c8c1ef "${id_44c8c1ef}::${name_44c8c1ef}::${description_44c8c1ef}::${distance_44c8c1ef}" || return "$SHELL_FALSE"
    done

    # 按照距离进行排序
    monitors_44c8c1ef=()
    while array::is_not_empty temp_44c8c1ef; do
        min_index_44c8c1ef=0
        min_distance_44c8c1ef=-1
        monitor_count_44c8c1ef=$(array::length temp_44c8c1ef) || return "$SHELL_FALSE"
        for ((index_44c8c1ef = 0; index_44c8c1ef < monitor_count_44c8c1ef; index_44c8c1ef++)); do
            distance_44c8c1ef="$(echo "${temp_44c8c1ef[$index_44c8c1ef]}" | awk -F "::" '{print $4}')"
            if [ "$min_distance_44c8c1ef" -lt 0 ] || [ "$distance_44c8c1ef" -lt "$min_distance_44c8c1ef" ]; then
                min_index_44c8c1ef="$index_44c8c1ef"
                min_distance_44c8c1ef="$distance_44c8c1ef"
            fi
        done

        array::rpush monitors_44c8c1ef "${temp_44c8c1ef[$min_index_44c8c1ef]}" || return "$SHELL_FALSE"
        array::remove_at REF_PLACEHOLDER temp_44c8c1ef "$min_index_44c8c1ef" || return "$SHELL_FALSE"
    done

    linfo "sorted monitors: $(array::join_with monitors_44c8c1ef ', ')"

    monitors_name_44c8c1ef=()
    for temp_44c8c1ef in "${monitors_44c8c1ef[@]}"; do
        name_44c8c1ef="$(echo "$temp_44c8c1ef" | awk -F "::" '{print $2}')"
        array::rpush "${!monitors_name_44c8c1ef}" "$name_44c8c1ef" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}


# 获取 hyprland 实例的指定 monitor 分辨率的宽度
# 说明：
# 位置参数：
#   monitor_name                    需要获取的 monitor 的 ID
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 获取的 monitors 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::monitors::resolution::width() {
    local instance

    local monitor_name

    local value
    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v monitor_name ]; then
                monitor_name="$param"
                continue
            fi
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_empty "$monitor_name"; then
        lerror "param monitor_name is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    value=$(hyprctl -j monitors "${instance_params[@]}" | yq ".[] | select(.name == \"${monitor_name}\").width")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland monitors failed, instance=${instance}, monitor_name=${monitor_name}, err=${value}"
        return "$SHELL_FALSE"
    fi

    echo "$value"

    return "$SHELL_TRUE"
}

# 获取 hyprland 实例的指定 monitor 分辨率的高度
# 说明：
# 位置参数：
#   monitor_name                    需要获取的 monitor 的 ID
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 获取的 monitors 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::monitors::resolution::height() {
    local instance

    local monitor_name

    local value
    local instance_params=()
    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v monitor_name ]; then
                monitor_name="$param"
                continue
            fi
            lerror "invalid param: $param"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if string::is_empty "$monitor_name"; then
        lerror "param monitor_name is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    value=$(hyprctl -j monitors "${instance_params[@]}" | yq ".[] | select(.name == \"${monitor_name}\").height")
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland monitors failed, instance=${instance}, monitor_name=${monitor_name}, err=${value}"
        return "$SHELL_FALSE"
    fi

    echo "$value"

    return "$SHELL_TRUE"
}

# 获取 hyprland 实例的 plugin 列表
# 说明：
# 位置参数：
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 获取的 monitors 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::plugin::list() {
    local instance_f2e75a0d
    local -n plugins_f2e75a0d

    local value_f2e75a0d
    local instance_params_f2e75a0d=()
    local param_f2e75a0d

    for param_f2e75a0d in "$@"; do
        case "$param_f2e75a0d" in
        --instance=*)
            parameter::parse_string --option="$param_f2e75a0d" instance_f2e75a0d || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param_f2e75a0d"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R plugins_f2e75a0d ]; then
                plugins_f2e75a0d="$param_f2e75a0d"
                continue
            fi
            lerror "invalid param: $param_f2e75a0d"
            return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R plugins_f2e75a0d ]; then
        lerror "param plugins is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$instance_f2e75a0d"; then
        instance_params_f2e75a0d+=("-i" "$instance_f2e75a0d")
    fi

    value_f2e75a0d=$(hyprctl -j plugin list "${instance_params_f2e75a0d[@]}" | yq '.[].name')
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "get hyprland plugins failed, instance=${instance_f2e75a0d}, err=${value_f2e75a0d}"
        return "$SHELL_FALSE"
    fi

    array::readarray plugins_f2e75a0d <<<"${value_f2e75a0d}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# hyprland 实例执行 dispatcher
# 说明：
# 位置参数：
#   dispatcher                      需要执行的 dispatcher
#   dispatcher_params               dispatcher 参数
# 可选参数：
#   --instance=<INSTANCE>           hyprland 实例的ID，如果没有指定则使用当前实例。
# 标准输出： 获取的 monitors 信息
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::instance::dispatch {
    local instance
    local dispatcher
    local dispatcher_params=()
    local instance_params=()

    local param

    for param in "$@"; do
        case "$param" in
        --instance=*)
            parameter::parse_string --option="$param" instance || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: $param"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -v dispatcher ]; then
                dispatcher="$param"
                continue
            fi
            array::rpush dispatcher_params "$param" || return "$SHELL_FALSE"
            # lerror "invalid param: $param"
            # return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -v dispatcher ]; then
        lerror "param dispatcher is required"
        return "${SHELL_FALSE}"
    fi

    if string::is_not_empty "$instance"; then
        instance_params+=("-i" "$instance")
    fi

    cmd::run_cmd_with_history -- hyprctl -q "${instance_params[@]}" dispatch "${dispatcher}" "${dispatcher_params[@]}" || return "$SHELL_FALSE"

    linfo "hyprctl instance(${instance}) dispatch ${dispatcher} ${dispatcher_params[*]} success"

    return "$SHELL_TRUE"
}

# 当前用户下的所有 hyprland 实例执行相应的操作
# 说明：
#   1. 没有实例时不做任何操作，认为成功
# 位置参数：
# 可选参数：
# 标准输出： 相应操作的输出
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::self::caller() {
    local caller="$1"
    shift
    local params=("$@")
    shift

    local instances
    local instance

    hyprland::hyprctl::instance::all_by_username instances "$(os::user::name)" || return "$SHELL_FALSE"

    if array::is_empty instances; then
        linfo "hyprland self caller(${caller} ${params[*]}) failed, no instance to call."
        return "$SHELL_TRUE"
    fi

    for instance in "${instances[@]}"; do
        "hyprland::hyprctl::instance::${caller}" --instance="$instance" "${params[@]}" || return "$SHELL_FALSE"
        linfo "hyprland self ${caller} ${params[*]} success. instance=${instance}"
    done

    linfo "hyprland self ${caller} ${params[*]} all instance success."

    return "$SHELL_TRUE"
}

# 当前用户下的第一个 hyprland 实例执行相应的操作
# 说明：
#   1. 没有实例时不做任何操作，认为成功
# 位置参数：
# 可选参数：
# 标准输出： 相应操作的输出
# 返回值：
# ${SHELL_TRUE} 成功
# ${SHELL_FALSE} 失败
function hyprland::hyprctl::self::caller_first() {
    local caller="$1"
    shift
    local params=("$@")
    shift

    local instances
    local instance

    hyprland::hyprctl::instance::all_by_username instances "$(os::user::name)" || return "$SHELL_FALSE"

    if array::is_empty instances; then
        linfo "hyprland self caller_first(${caller} ${params[*]}) failed, no instance to call."
        return "$SHELL_TRUE"
    fi

    for instance in "${instances[@]}"; do
        "hyprland::hyprctl::instance::${caller}" --instance="$instance" "${params[@]}" || return "$SHELL_FALSE"
        linfo "hyprland self caller_first(${caller} ${params[*]}) success. instance=${instance}"
        return "$SHELL_TRUE"
    done

    return "$SHELL_TRUE"
}
