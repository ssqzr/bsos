#!/bin/bash

# 接口命名参考 python 的 dict 和 array 接口命名

if [ -n "${SCRIPT_DIR_b59e77de}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_b59e77de="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_b59e77de}/../../utest.sh"

# 用于构造 line 的信息
function cfg::trait::ini::parser::factory::line() {
    local -n line_6b833545="$1"
    shift
    local content_6b833545="$1"
    shift
    local number_6b833545="$1"
    shift
    # 行所属的 section
    local section_6b833545="$1"
    shift

    if array::is_not_associative_array "${!line_6b833545}"; then
        lerror "invalid param line: ref name ${!line_6b833545} is not associative array"
        return "${SHELL_FALSE}"
    fi

    line_6b833545=()
    line_6b833545["content"]="${content_6b833545}"
    line_6b833545["number"]="${number_6b833545}"
    line_6b833545["section"]="${section_6b833545}"
    return "${SHELL_TRUE}"
}

# 说明
# 用于构造回调函数的参数的工厂函数
# 1. 所有的回调函数第一个参数都是一个关联数组，字段有如下：
#   字段说明：
#       - result                    string 引用                         用于保存修改后的配置数据
#       - data                      string                              完整的配置数据
#       - comment                   string                              注释符号
#       - separator                 string                              分隔符
#       - extra                     关联数组的引用                        回调函数额外的参数
#       - line                      关联数组的引用                        当前处理的行的信息
#           - content               string                              当前处理的行的内容
#           - section               string                              当前处理的行的 section
#           - number                int                                 当前处理的行的行号，从 1 开始
# 参数说明：
#   - params                        关联数组的引用                        构造返回的回调函数的参数
#   - result                        string 引用                         用于保存修改后的配置数据
#   - data                          string                              完整的配置数据
#   - comment                       string                              注释符号
#   - separator                     string                              分隔符
#   - line_content                  string                              当前处理的行的内容
#   - line_section                  string                              当前处理的行的 section
#   - line_number                   int                                 当前处理的行的行号，从 1 开始
#   - extra                         关联数组的引用                        回调函数额外的参数
function cfg::trait::ini::parser::factory::callback_params() {
    local -n params_da624ac9="$1"
    shift
    local -n result_da624ac9="$1"
    shift
    local data_da624ac9="$1"
    shift
    local comment_da624ac9="$1"
    shift
    local separator_da624ac9="$1"
    shift
    # shellcheck disable=SC2034
    local -n line_da624ac9="$1"
    shift
    local -n extra_da624ac9="$1"
    shift

    if array::is_not_associative_array "${!params_da624ac9}"; then
        lerror "invalid params: ref name ${!params_da624ac9} is not associative array"
        return "${SHELL_FALSE}"
    fi

    params_da624ac9=()
    params_da624ac9["result"]="${!result_da624ac9}"
    params_da624ac9["data"]="${data_da624ac9}"
    params_da624ac9["comment"]="${comment_da624ac9}"
    params_da624ac9["separator"]="${separator_da624ac9}"
    params_da624ac9["line"]=${!line_da624ac9}
    params_da624ac9["extra"]="${!extra_da624ac9}"

    return "${SHELL_TRUE}"
}

# 构造默认的回调函数列表
function cfg::trait::ini::parser::factory::callback::default() {
    local -n callback_dafe97d6="$1"
    shift

    if array::is_not_associative_array "${!callback_dafe97d6}"; then
        lerror "invalid params: ref name ${!callback_dafe97d6} is not associative array"
        return "${SHELL_FALSE}"
    fi

    callback_dafe97d6=()
    callback_dafe97d6["data::start"]="cfg::trait::ini::parser::callback::default::data::start"
    callback_dafe97d6["data::end"]="cfg::trait::ini::parser::callback::default::data::end"
    callback_dafe97d6["section::start"]="cfg::trait::ini::parser::callback::default::section::start"
    callback_dafe97d6["section::end"]="cfg::trait::ini::parser::callback::default::section::end"
    callback_dafe97d6["line::comment"]="cfg::trait::ini::parser::callback::default::line::comment"
    callback_dafe97d6["line::kv"]="cfg::trait::ini::parser::callback::default::line::kv"
    callback_dafe97d6["line::empty"]="cfg::trait::ini::parser::callback::default::line::empty"
    # shellcheck disable=SC2034
    callback_dafe97d6["line::unknown"]="cfg::trait::ini::parser::callback::default::line::unknown"

    return "${SHELL_TRUE}"
}

# 判断是否匹配到 section
function cfg::trait::ini::parser::is_match_section() {
    local line="$1"
    shift

    if [[ "${line}" =~ ^[[:space:]]*\[.*\][[:space:]]*$ ]]; then
        return "${SHELL_TRUE}"
    fi
    return "${SHELL_FALSE}"
}

# 判断是否匹配到 comment
function cfg::trait::ini::parser::is_match_comment() {
    local line="$1"
    shift
    local comment="$1"
    shift

    if [[ "${line}" =~ ^[[:space:]]*${comment}.*$ ]]; then
        return "${SHELL_TRUE}"
    fi
    return "${SHELL_FALSE}"
}

# 判断是否匹配到空行
function cfg::trait::ini::parser::is_match_empty() {
    local line="$1"
    shift

    if [[ "${line}" =~ ^[[:space:]]*$ ]]; then
        return "${SHELL_TRUE}"
    fi
    return "${SHELL_FALSE}"
}

# 判断是否匹配到 key-value
function cfg::trait::ini::parser::is_match_key_value() {
    local line="$1"
    shift

    if [[ "${line}" =~ ^[[:space:]]*(.*)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then
        return "${SHELL_TRUE}"
    fi
    return "${SHELL_FALSE}"
}

# 根据 JSONPath 解析 section 的名称
function cfg::trait::ini::parser::path::parse_section() {
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

# 根据 JSONPath 解析 section 下的配置的 key 的名称
function cfg::trait::ini::parser::path::parse_key() {
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

# 解析 section
# 输出 section 名称
function cfg::trait::ini::parser::line::parse_section_name() {
    local line="$1"
    shift

    local section

    cfg::trait::ini::parser::is_match_section "${line}" || return "${SHELL_FALSE}"

    section="$(echo "${line}" | sed -E 's/^\s*\[(.*)\]\s*$/\1/')"
    if string::is_equal "${line}" "${section}"; then
        return "${SHELL_FALSE}"
    fi

    echo "${section}"
    return "${SHELL_TRUE}"
}

# 解析 key-value 的 key ， 以第一个 = 进行分割
function cfg::trait::ini::parser::line::parse_key() {
    local line="$1"
    shift

    local key

    cfg::trait::ini::parser::is_match_key_value "${line}" || return "${SHELL_FALSE}"

    key="${line%%=*}"

    key=$(string::trim "${key}") || return "${SHELL_FALSE}"

    echo "${key}"

    return "${SHELL_TRUE}"
}

# 解析 key-value 的 value ， 以第一个 = 进行分割
function cfg::trait::ini::parser::line::parse_value() {
    local line="$1"
    shift

    local value

    cfg::trait::ini::parser::is_match_key_value "${line}" || return "${SHELL_FALSE}"

    value="${line#*=}"

    echo "${value}"

    return "${SHELL_TRUE}"
}

# 参数说明
#   - result                        string引用                          修改后的配置会写入到这个变量中
#   - data                          string                              配置数据
#   - comment                       string                             注释符号
#   - separator                     string                              用于解析数组的分隔符
#   - callback                      关联数组的引用                        回调函数的关联数组
#       - data:start                                                        用于处理解析整个配置开始的回调函数
#       - data:end                                                          用于处理解析整个配置结束的回调函数
#       - section::start                                                    用于处理 section 开始的回调函数
#       - section::end                                                      用于处理 section 结束的回调函数
#       - line::comment                                                     用于处理注释的回调函数
#       - line::kv                                                          用于处理 key-value 的回调函数
#       - line::empty                                                       用于处理空行
#       - line::unknown                                                     用于处理未知的行
#   - extra                         关联数组的引用                        额外的参数，直接传递给回调，是关联数组
function cfg::trait::ini::parser::parser() {
    # shellcheck disable=SC2034
    local -n result_468242ca="$1"
    shift
    local data_468242ca="$1"
    shift
    local comment_468242ca="$1"
    shift
    local separator_468242ca="$1"
    shift
    local -n callback_468242ca="$1"
    shift
    # 额外的参数，直接传递给回调，是关联数组的引用
    local -n extra_468242ca="$1"
    shift

    local line_468242ca
    local line_section_468242ca
    local line_number_468242ca="-1"
    # shellcheck disable=SC2034
    declare -A callback_pramas_468242ca=()
    declare -A line_info_468242ca=()
    local temp_468242ca
    local func_468242ca

    if array::is_not_associative_array "${!callback_468242ca}"; then
        lerror "invalid param callback: ref name ${!callback_468242ca} is not associative array"
        return "${SHELL_FALSE}"
    fi

    if array::is_not_associative_array "${!extra_468242ca}"; then
        lerror "invalid param extra: ref name ${!extra_468242ca} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 解析前的回调
    func_468242ca="${callback_468242ca["data::start"]}"
    if string::is_not_empty "${func_468242ca}"; then
        cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
        "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
    fi

    line_number_468242ca=0
    while IFS='' read -r line_468242ca; do
        if [ "${line_number_468242ca}" -gt 0 ]; then
            # 处理第一行前不加换行符，处理后面的行才加换行符
            result_468242ca+=$'\n'
        fi
        line_info_468242ca=()
        line_number_468242ca=$((line_number_468242ca + 1))
        cfg::trait::ini::parser::factory::line line_info_468242ca "${line_468242ca}" "${line_number_468242ca}" "${line_section_468242ca}" || return "${SHELL_FALSE}"

        if cfg::trait::ini::parser::is_match_empty "${line_468242ca}"; then
            # 空行
            ldebug "empty line, line number=$line_number_468242ca"

            func_468242ca="${callback_468242ca["line::empty"]}"
            if string::is_not_empty "${func_468242ca}"; then
                cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
                "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
            fi
            continue
        fi

        if cfg::trait::ini::parser::is_match_comment "${line_468242ca}" "${comment_468242ca}"; then
            # 找到注释
            ldebug "comment line: (${line_468242ca})"

            func_468242ca="${callback_468242ca["line::comment"]}"
            if string::is_not_empty "${func_468242ca}"; then
                cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
                "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
            fi
            continue
        fi

        if cfg::trait::ini::parser::is_match_section "${line_468242ca}"; then
            # 找到 section
            ldebug "section line: (${line_468242ca})"

            temp_468242ca=$(cfg::trait::ini::parser::line::parse_section_name "${line_468242ca}") || return "${SHELL_FALSE}"
            if string::is_not_equal "${temp_468242ca}" "${line_section_468242ca}"; then
                # 上一个 section 结束
                func_468242ca="${callback_468242ca["section::end"]}"
                if string::is_not_empty "${func_468242ca}"; then
                    cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
                    "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
                fi
            fi

            # 新的 section 开始
            line_section_468242ca="${temp_468242ca}"
            line_info_468242ca["section"]="${line_section_468242ca}"
            func_468242ca="${callback_468242ca["section::start"]}"
            if string::is_not_empty "${func_468242ca}"; then
                cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
                "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
            fi
            continue
        fi

        if cfg::trait::ini::parser::is_match_key_value "${line_468242ca}"; then
            # 找到 key-value
            ldebug "key-value line: (${line_468242ca})"

            func_468242ca="${callback_468242ca["line::kv"]}"
            if string::is_not_empty "${func_468242ca}"; then
                cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
                "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
            fi
            continue
        fi

        # 找到未知的行
        ldebug "unknown line: (${line_468242ca})"

        func_468242ca="${callback_468242ca["line::unknown"]}"
        if string::is_not_empty "${func_468242ca}"; then
            cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
            "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
        fi
        continue

    done <<<"${data_468242ca}"

    # 文件结束，最后一个 section 结束的回调函数
    cfg::trait::ini::parser::factory::line line_info_468242ca "" "" "${line_section_468242ca}" || return "${SHELL_FALSE}"
    func_468242ca="${callback_468242ca["section::end"]}"
    if string::is_not_empty "${func_468242ca}"; then
        cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
        "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
    fi

    # 解析后的回调
    # shellcheck disable=SC2034
    line_info_468242ca=()
    func_468242ca="${callback_468242ca["data::end"]}"
    if string::is_not_empty "${func_468242ca}"; then
        cfg::trait::ini::parser::factory::callback_params callback_pramas_468242ca result_468242ca "${data_468242ca}" "${comment_468242ca}" "${separator_468242ca}" line_info_468242ca "${!extra_468242ca}" || return "${SHELL_FALSE}"
        "${func_468242ca}" callback_pramas_468242ca || return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

############################################### 默认回调函数 #################################################

# 解析整个数据开始的回调
function cfg::trait::ini::parser::callback::default::data::start() {
    # 需要传递 associative array 的引用
    local -n params_ef4eda8a="$1"

    if array::is_not_associative_array "${!params_ef4eda8a}"; then
        lerror "invalid params: ref name ${!params_ef4eda8a} is not associative array"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# 解析整个数据结束的回调
function cfg::trait::ini::parser::callback::default::data::end() {
    # 需要传递 associative array 的引用
    local -n params_8330dd0d="$1"

    if array::is_not_associative_array "${!params_8330dd0d}"; then
        lerror "invalid params: ref name ${!params_8330dd0d} is not associative array"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# 解析 section 开始的回调函数
function cfg::trait::ini::parser::callback::default::section::start() {
    # 需要传递 associative array 的引用
    local -n params_b19b10e9="$1"

    if array::is_not_associative_array "${!params_b19b10e9}"; then
        lerror "invalid params: ref name ${!params_b19b10e9} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_b19b10e9="${params_b19b10e9["line"]}"
    local -n result_b19b10e9="${params_b19b10e9["result"]}"

    result_b19b10e9+="${line_b19b10e9["content"]}"

    return "${SHELL_TRUE}"
}

# 解析 section 结束的回调函数
function cfg::trait::ini::parser::callback::default::section::end() {
    # 需要传递 associative array 的引用
    local -n params_09a13f6f="$1"

    if array::is_not_associative_array "${!params_09a13f6f}"; then
        lerror "invalid params: ref name ${!params_09a13f6f} is not associative array"
        return "${SHELL_FALSE}"
    fi

    return "${SHELL_TRUE}"
}

# 解析所有注释的行
# NOTE: 注释可能属于某个 section 的，也可能不属于任何 section。通过判断 line_section 是否为空来判断
function cfg::trait::ini::parser::callback::default::line::comment() {
    # 需要传递 associative array 的引用
    local -n params_ee653e6e="$1"

    if array::is_not_associative_array "${!params_ee653e6e}"; then
        lerror "invalid params: ref name ${!params_ee653e6e} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_ee653e6e="${params_ee653e6e["line"]}"
    local -n result_ee653e6e="${params_ee653e6e["result"]}"

    result_ee653e6e+="${line_ee653e6e["content"]}"

    return "${SHELL_TRUE}"
}

# 解析所有 key-value 的行
function cfg::trait::ini::parser::callback::default::line::kv() {
    # 需要传递 associative array 的引用
    local -n params_09e0c22c="$1"

    if array::is_not_associative_array "${!params_09e0c22c}"; then
        lerror "invalid params: ref name ${!params_09e0c22c} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_09e0c22c="${params_09e0c22c["line"]}"
    local -n result_09e0c22c="${params_09e0c22c["result"]}"

    result_09e0c22c+="${line_09e0c22c["content"]}"

    return "${SHELL_TRUE}"
}

# 解析空行
function cfg::trait::ini::parser::callback::default::line::empty() {
    # 需要传递 associative array 的引用
    local -n params_aa2009f9="$1"

    if array::is_not_associative_array "${!params_aa2009f9}"; then
        lerror "invalid params: ref name ${!params_aa2009f9} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_aa2009f9="${params_aa2009f9["line"]}"
    local -n result_aa2009f9="${params_aa2009f9["result"]}"

    result_aa2009f9+="${line_aa2009f9["content"]}"

    return "${SHELL_TRUE}"
}

# 解析未知的行
function cfg::trait::ini::parser::callback::default::line::unknown() {
    # 需要传递 associative array 的引用
    local -n params_355b4c4c="$1"

    if array::is_not_associative_array "${!params_355b4c4c}"; then
        lerror "invalid params: ref name ${!params_355b4c4c} is not associative array"
        return "${SHELL_FALSE}"
    fi

    # 自定义变量
    local -n line_355b4c4c="${params_355b4c4c["line"]}"
    local -n result_355b4c4c="${params_355b4c4c["result"]}"

    result_355b4c4c+="${line_355b4c4c["content"]}"

    return "${SHELL_TRUE}"
}

################################################## 下面是测试测试 ##################################################

function TEST::cfg::trait::ini::parser::is_match_section() {
    cfg::trait::ini::parser::is_match_section "[]"
    utest::assert $?

    cfg::trait::ini::parser::is_match_section "[abc def]"
    utest::assert $?

    cfg::trait::ini::parser::is_match_section "[[abc def]]"
    utest::assert $?

    cfg::trait::ini::parser::is_match_section "[abc def]]"
    utest::assert $?

    cfg::trait::ini::parser::is_match_section "[[abc def]"
    utest::assert $?

    cfg::trait::ini::parser::is_match_section "abc"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_section "[abc"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_section "abc]"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_section "[[abc"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_section "abc]]"
    utest::assert_fail $?
}

function TEST::cfg::trait::ini::parser::is_match_comment() {
    cfg::trait::ini::parser::is_match_comment "#" "#"
    utest::assert $?

    cfg::trait::ini::parser::is_match_comment "#abc" "#"
    utest::assert $?

    cfg::trait::ini::parser::is_match_comment "# abc" "#"
    utest::assert $?

    cfg::trait::ini::parser::is_match_comment ";" ";"
    utest::assert $?

    cfg::trait::ini::parser::is_match_comment ";abc" ";"
    utest::assert $?

    cfg::trait::ini::parser::is_match_comment ";abc;" ";"
    utest::assert $?

    cfg::trait::ini::parser::is_match_comment ";abc;" "#"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_comment "abc#" "#"
    utest::assert_fail $?
}

function TEST::cfg::trait::ini::parser::is_match_empty() {
    cfg::trait::ini::parser::is_match_empty ""
    utest::assert $?

    cfg::trait::ini::parser::is_match_empty "      "
    utest::assert $?

    cfg::trait::ini::parser::is_match_empty $'   \t   '
    utest::assert $?

    cfg::trait::ini::parser::is_match_empty $'   \n   '
    utest::assert $?

    cfg::trait::ini::parser::is_match_empty $'a'
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_empty $'1'
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_empty "   1"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_empty "\n"
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_empty "\t"
    utest::assert_fail $?

}

function TEST::cfg::trait::ini::parser::is_match_key_value() {
    cfg::trait::ini::parser::is_match_key_value "name="
    utest::assert $?

    cfg::trait::ini::parser::is_match_key_value "="
    utest::assert $?

    cfg::trait::ini::parser::is_match_key_value "=value"
    utest::assert $?

    cfg::trait::ini::parser::is_match_key_value "=="
    utest::assert $?

    cfg::trait::ini::parser::is_match_key_value ""
    utest::assert_fail $?

    cfg::trait::ini::parser::is_match_key_value "aa"
    utest::assert_fail $?
}

function TEST::cfg::trait::ini::parser::line::parse_section_name() {
    local section

    utest::assert_equal "$(cfg::trait::ini::parser::line::parse_section_name "[abc]")" "abc"
    utest::assert_equal "$(cfg::trait::ini::parser::line::parse_section_name "[]")" ""
    utest::assert_equal "$(cfg::trait::ini::parser::line::parse_section_name "[[]]")" "[]"
    utest::assert_equal "$(cfg::trait::ini::parser::line::parse_section_name "[abc.def]")" "abc.def"

    section="$(cfg::trait::ini::parser::line::parse_section_name "")"
    utest::assert_fail $?

    section="$(cfg::trait::ini::parser::line::parse_section_name "abc")"
    utest::assert_fail $?

    section="$(cfg::trait::ini::parser::line::parse_section_name "[")"
    utest::assert_fail $?

    section="$(cfg::trait::ini::parser::line::parse_section_name "]")"
    utest::assert_fail $?

}

function TEST::cfg::trait::ini::parser::line::parse_key() {
    local key

    key="$(cfg::trait::ini::parser::line::parse_key "")"
    utest::assert_fail $?

    key="$(cfg::trait::ini::parser::line::parse_key "aa")"
    utest::assert_fail $?

    key="$(cfg::trait::ini::parser::line::parse_key "name=")"
    utest::assert $?
    utest::assert_equal "$key" "name"

    key="$(cfg::trait::ini::parser::line::parse_key "=")"
    utest::assert $?
    utest::assert_equal "$key" ""

    key="$(cfg::trait::ini::parser::line::parse_key "=value")"
    utest::assert $?
    utest::assert_equal "$key" ""
}

function TEST::cfg::trait::ini::parser::line::parse_value() {
    local value

    value="$(cfg::trait::ini::parser::line::parse_value "")"
    utest::assert_fail $?

    value="$(cfg::trait::ini::parser::line::parse_value "aa")"
    utest::assert_fail $?

    value="$(cfg::trait::ini::parser::line::parse_value "name=")"
    utest::assert $?
    utest::assert_equal "$value" ""

    value="$(cfg::trait::ini::parser::line::parse_value "=")"
    utest::assert $?
    utest::assert_equal "$value" ""

    value="$(cfg::trait::ini::parser::line::parse_value $'name=a1`~!@#$%^&*()-=_+{}[]\\|;:"\',<.>/?')"
    utest::assert $?
    utest::assert_equal "$value" $'a1`~!@#$%^&*()-=_+{}[]\\|;:"\',<.>/?'
}
