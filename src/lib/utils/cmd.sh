#!/bin/bash

if [ -n "${SCRIPT_DIR_e53d23f3}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_e53d23f3="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/constant.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/log/log.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/string.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/array.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/print.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/parameter.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/utest.sh"

function cmd::_init_cmd_history_filepath() {
    if [ -n "${__cmd_history_filepath}" ]; then
        return "$SHELL_TRUE"
    fi
    local cmd_history_dir="${XDG_CACHE_HOME}"
    if [ -z "${cmd_history_dir}" ]; then
        cmd_history_dir="${HOME}/.cache"
    fi

    export __cmd_history_filepath="${cmd_history_dir}/bsos/cmd.history"
}

function cmd::_init() {
    cmd::_init_cmd_history_filepath || return "$SHELL_FALSE"
}

function cmd::_default_stdout_handler() {
    cat
}

function cmd::_default_stderr_handler() {
    cat 1>&2
}

# 函数的返回结果是命令的执行结果
# stdout_handler 和 stderr_handler 的返回结果并不影响函数的返回结果
# NOTE: 如果命令的部分需要转义，可以将字符串用 {{}} 包裹起来
# 例如： {{hello world!@#$%^&*}} ，被包裹的字符串会通过 ${xxx@Q} 进行转义
# 或者自己进行转义再调用函数也可以
function cmd::run_cmd() {
    local cmds
    local is_sudo="$SHELL_FALSE"
    local password=""
    local stdout_handler
    local stdout_handler_params=()
    local stderr_handler
    local stderr_handler_params=()
    local is_record_cmd="$SHELL_FALSE"
    local is_parse_self="$SHELL_TRUE"
    local param
    local temp_str
    local index
    local exit_code

    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            cmds+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        -s | -s=* | --sudo | --sudo=*)
            parameter::parse_bool --option="$param" is_sudo || return "$SHELL_FALSE"
            ;;
        -p=* | --password=*)
            parameter::parse_string --option="$param" password || return "$SHELL_FALSE"
            ;;
        --stdout=*)
            parameter::parse_string --option="$param" stdout_handler || return "$SHELL_FALSE"
            ;;
        --stdout-option=*)
            temp_str=""
            parameter::parse_string --option="$param" temp_str || return "$SHELL_FALSE"
            stdout_handler_params+=("${temp_str}")
            ;;
        --stderr=*)
            parameter::parse_string --option="$param" stderr_handler || return "$SHELL_FALSE"
            ;;
        --stderr-option=*)
            temp_str=""
            parameter::parse_string --option="$param" temp_str || return "$SHELL_FALSE"
            stderr_handler_params+=("${temp_str}")
            ;;
        --record | --record=*)
            parameter::parse_bool --option="$param" is_record_cmd || return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v stdout_handler ]; then
        stdout_handler=cmd::_default_stdout_handler
    fi

    if [ ! -v stderr_handler ]; then
        stderr_handler=cmd::_default_stdout_handler
    fi

    # 参数合法性
    if [ "$(array::length cmds)" -eq 0 ]; then
        lerror "cmds is empty"
        return "$SHELL_FALSE"
    fi

    for ((index = 0; index < "${#cmds[@]}"; index++)); do
        temp_str="${cmds[$index]}"
        if [ "${#temp_str}" -ge 4 ] && [ "${temp_str:0:2}" == "{{" ] && [ "${temp_str: -2}" == "}}" ]; then
            temp_str="${temp_str:2:-2}"
            cmds[index]="$(string::quote "${temp_str}")"
            continue
        fi
    done

    if [ "$is_record_cmd" -eq "$SHELL_TRUE" ]; then
        echo "${cmds[*]}" >>"${__cmd_history_filepath}"
    fi

    if [ "$is_sudo" -eq "$SHELL_TRUE" ] && [ -z "$password" ]; then
        ldebug "start run cmd, is_sudo=$(string::print_yes_no "$is_sudo"), password=$password, cmd=sudo bash -c ${cmds[*]}"

        # https://stackoverflow.com/questions/9112979/pipe-stdout-and-stderr-to-two-different-processes-in-shell-script
        # shellcheck disable=SC2024
        { sudo bash -c "${cmds[*]}" > >(${stdout_handler} "${stdout_handler_params[@]}" 3>&-) 2> >(${stderr_handler} "${stderr_handler_params[@]}" 1>&3 3>&-) 3>&-; } 3>&1
        exit_code=$?

    elif [ "$is_sudo" -eq "$SHELL_TRUE" ] && [ -n "$password" ]; then
        ldebug "start run cmd, is_sudo=$(string::print_yes_no "$is_sudo"), password=******, cmd=printf ****** | sudo -S bash -c ${cmds[*]}"

        # shellcheck disable=SC2024
        { printf "%s" "$password" | sudo -S bash -c "${cmds[*]}" > >(${stdout_handler} "${stdout_handler_params[@]}" 3>&-) 2> >(${stderr_handler} "${stderr_handler_params[@]}" 1>&3 3>&-) 3>&-; } 3>&1
        exit_code=$?

    else
        ldebug "start run cmd, is_sudo=$(string::print_yes_no "$is_sudo"), cmd=bash -c ${cmds[*]}"

        { bash -c "${cmds[*]}" > >(${stdout_handler} "${stdout_handler_params[@]}" 3>&-) 2> >(${stderr_handler} "${stderr_handler_params[@]}" 1>&3 3>&-) 3>&-; } 3>&1
        exit_code=$?
    fi

    if [ "$exit_code" -ne "$SHELL_TRUE" ]; then
        lerror "run cmd failed"
        return "$SHELL_FALSE"
    fi

    ldebug "run cmd success"
    return "$SHELL_TRUE"
}

function cmd::set_cmd_history_filepath() {
    local filepath="$1"
    if [ -z "$filepath" ]; then
        lerror "set cmd history filepath failed, param filepath is empty"
        return "$SHELL_FALSE"
    fi
    local parent_dir
    parent_dir=$(dirname "$filepath")
    mkdir -p "$parent_dir" 1>/dev/null 2>&1 || return "$SHELL_FALSE"

    # FIXME: 是删掉重新记录还是追加的方式记录呢？？
    echo "--------------------------------" >>"$filepath"

    export __cmd_history_filepath="$filepath"

}

function cmd::run_cmd_with_history() {
    local cmds=()
    local options=()
    local is_parse_self="$SHELL_TRUE"
    local param
    local temp_str

    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            cmds+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        -*)
            options+=("$param")
            ;;
        *)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    # --record 强制覆盖
    cmd::run_cmd --stdout=lwrite --stderr=lwrite "${options[@]}" --record -- "${cmds[@]}"
    return $?
}

#
function cmd::run_cmd_retry() {
    local max_count=$1
    shift
    local count=1
    while [ "$count" -le "$max_count" ]; do
        "${@}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "run command(${*}) failed ${count} times, max retry count=${max_count}"
            ((count += 1))
            continue
        fi
        return "$SHELL_TRUE"
    done
    return "$SHELL_FALSE"
}

function cmd::run_cmd_retry_three() {
    cmd::run_cmd_retry 3 "$@" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

##################################### 以下是测试代码 #####################################

function TEST::cmd::run_cmd::simple() {
    local output
    local test_str="hello world"
    output=$(cmd::run_cmd -- echo "$test_str")
    utest::assert_equal "$output" "$test_str"

    output=$(cmd::run_cmd -- printf "${test_str}")
    utest::assert_equal "$output" "hello"

    output=$(cmd::run_cmd -- printf "'${test_str}'")
    utest::assert_equal "$output" "$test_str"

}

function TEST::cmd::run_cmd::origin_pipe_char() {
    local output

    output=$(cmd::run_cmd -- echo "'|'")
    utest::assert_equal "$output" "|"

    output=$(cmd::run_cmd -- printf "{{|}}")
    utest::assert_equal "$output" "|"
}

function TEST::cmd::run_cmd::bracket() {
    local output
    local test_str

    output=$(cmd::run_cmd -- echo "{{}}")
    utest::assert_equal "$output" ""

    output=$(cmd::run_cmd -- echo "{{abc}}")
    utest::assert_equal "$output" "abc"

    output=$(cmd::run_cmd -- printf "%s")
    utest::assert_equal "$output" ""
    output=$(cmd::run_cmd -- printf "{{%s}}")
    utest::assert_equal "$output" ""
    test_str="%s"
    output=$(cmd::run_cmd -- printf "{{$(string::quote "$test_str")}}")
    utest::assert_equal "$output" "''"
    test_str="%%s"
    output=$(cmd::run_cmd -- printf "{{${test_str}}}")
    utest::assert_equal "$output" "%s"

    test_str="hello world"
    output=$(cmd::run_cmd -- printf "${test_str}")
    utest::assert_equal "$output" "hello"
    output=$(cmd::run_cmd -- printf "{{${test_str}}}")
    utest::assert_equal "$output" "$test_str"

    test_str='`~!@#$%^&*()-_=+{}[]\|;:"<>,./?'
    test_str+="'"
    output=$(cmd::run_cmd -- printf "%s" "{{${test_str}}}")
    utest::assert_equal "$output" "${test_str}"
}

function TEST::cmd::run_cmd::origin_bracket() {
    local output

    output=$(cmd::run_cmd -- echo "'{{}}'")
    utest::assert_equal "$output" "{{}}"

    output=$(cmd::run_cmd -- printf "{{{{}}}}")
    utest::assert_equal "$output" "{{}}"
}

function TEST::cmd::run_cmd::simple_and_error() {
    local output
    local test_str="hello world"

    cmd::run_cmd --
    utest::assert_fail "$?"

    output=$(cmd::run_cmd -- echo "$test_str" "|" grep "ssss")
    utest::assert_fail "$?"
    utest::assert_equal "$output" ""
}

function TEST::cmd::run_cmd::pipe() {
    local output
    output=$(cmd::run_cmd -- echo "{{hello world}}" "|" sed "s/hello/xxx/")
    utest::assert_equal "$output" "xxx world"

    output=$(cmd::run_cmd -- printf "{{hello world}}" "|" sed "s/hello/xxx/")
    utest::assert_equal "$output" "xxx world"

    output=$(cmd::run_cmd -- printf "'hello world'" "|" sed "s/hello/xxx/")
    utest::assert_equal "$output" "xxx world"
}

function TEST::cmd::run_cmd::multi_pipe() {
    local output
    output=$(cmd::run_cmd -- echo "hello world" "|" sed "s/hello/xxx/" "|" sed "s/xxx/yyy/")
    utest::assert_equal "$output" "yyy world"
}

function TEST::cmd::run_cmd::redirect() {
    local output
    output=$(cmd::run_cmd -- echo "hello world" "1>" "/dev/null")
    utest::assert "$?"
    utest::assert_equal "$output" ""

    output=$(cmd::run_cmd -- echo "hello world" "1>>" "/dev/null")
    utest::assert "$?"
    utest::assert_equal "$output" ""
}

function TEST::cmd::run_cmd::stdout_handler() {
    local output
    output=$(cmd::run_cmd --stdout=sed --stdout-option="s/hello/xxx/" -- echo "hello world")
    utest::assert_equal "$output" "xxx world"
}

function TEST::cmd::run_cmd::stdout_handler_and_error() {
    local output
    output=$(cmd::run_cmd --stdout=grep --stdout-option="xxxx" -- echo "hello world")
    utest::assert "$?"
    utest::assert_equal "$output" ""
}

function TEST::cmd::run_cmd::stderr_handler() {
    local output
    output=$(cmd::run_cmd --stderr=sed --stderr-option="s/hello/xxx/" -- echo "hello world" "1>&2")
    utest::assert_equal "$output" "xxx world"

}

function TEST::cmd::run_cmd::stderr_handler_and_error() {
    local output
    output=$(cmd::run_cmd --stderr=grep --stderr-option="xxxx" -- echo "hello world" "1>&2")
    utest::assert "$?"
    utest::assert_equal "$output" ""
}

function cmd::_main() {
    cmd::_init || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

cmd::_main
