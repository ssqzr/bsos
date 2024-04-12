#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_e53d23f3="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/log.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/string.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/print.sh"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e53d23f3}/file.sh"

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

    export __cmd_history_filepath="${cmd_history_dir}/lzw/cmd.history"
}

function cmd::_default_stdout_handler() {
    cat
}

function cmd::_default_stderr_handler() {
    cat 1>&2
}

# https://stackoverflow.com/questions/9112979/pipe-stdout-and-stderr-to-two-different-processes-in-shell-script
# 函数的返回结果是命令的执行结果
# stdout_handler 和 stderr_handler 的返回结果并不影响函数的返回结果
function cmd::run_cmd() {
    local cmd=()
    local stdout_handler
    local stdout_handler_params=()
    local stderr_handler
    local stderr_handler_params=()
    local parse_step=0
    local param
    for param in "$@"; do
        case $parse_step in
        0)
            if [ "$param" = "none" ]; then
                stdout_handler="cmd::_default_stdout_handler"
                ((parse_step += 2))
                continue
            fi
            stdout_handler="$param"
            ((parse_step += 1))
            continue
            ;;
        1)
            if [ "$param" = "-" ]; then
                ((parse_step += 1))
                continue
            fi
            stdout_handler_params+=("$param")
            continue
            ;;
        2)
            if [ "$param" = "none" ]; then
                stderr_handler="cmd::_default_stderr_handler"
                ((parse_step += 2))
                continue
            fi
            stderr_handler="$param"
            ((parse_step += 1))
            continue
            ;;
        3)
            if [ "$param" = "-" ]; then
                ((parse_step += 1))
                continue
            fi
            stderr_handler_params+=("$param")
            continue
            ;;
        *)
            cmd+=("$param")
            continue
            ;;
        esac
    done

    # 参数参数合法性
    if [ ${#cmd[@]} -eq 0 ]; then
        lerror "cmd is empty"
        return "$SHELL_FALSE"
    fi

    ldebug "start run cmd: ${cmd[*]}"

    bash -c "${cmd[*]}" > >(${stdout_handler} "${stdout_handler_params[@]}") 2> >(${stderr_handler} "${stderr_handler_params[@]}")

    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "run cmd failed: ${cmd[*]}"
        return "$SHELL_FALSE"
    fi

    ldebug "run cmd success: ${cmd[*]}"
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
    file::create_dir_recursive "$parent_dir" || return "$SHELL_FALSE"

    # FIXME: 是删掉重新记录还是追加的方式记录呢？？
    echo "--------------------------------" >>"$filepath"

    export __cmd_history_filepath="$filepath"

}

function cmd::run_cmd_with_history() {
    echo "$*" >>"${__cmd_history_filepath}"
    cmd::run_cmd lwrite - lwrite - "$@"
    return $?
}

function cmd::_test_simple_cmd() {
    local output
    local test_str="hello world"
    output=$(cmd::run_cmd none none echo "$test_str")
    utest::assert_equal "$output" "$test_str"
}

function cmd::_test_simple_cmd_error() {
    local output
    local test_str="hello world"
    output=$(cmd::run_cmd none none echo "$test_str" "|" grep "ssss")
    utest::assert_fail "$?"
    utest::assert_equal "$output" ""
}

function cmd::_test_pipe() {
    local output
    output=$(cmd::run_cmd none none echo "hello world" "|" sed "s/hello/xxx/")
    utest::assert_equal "$output" "xxx world"
}

function cmd::_test_multi_pipe() {
    local output
    output=$(cmd::run_cmd none none echo "hello world" "|" sed "s/hello/xxx/" "|" sed "s/xxx/yyy/")
    utest::assert_equal "$output" "yyy world"
}

function cmd::_test_redirect() {
    local output
    output=$(cmd::run_cmd none none echo "hello world" "1>/dev/null")
    utest::assert "$?"
    utest::assert_equal "$output" ""
}

function cmd::_test_stdout_handler() {
    local output
    output=$(cmd::run_cmd sed "s/hello/xxx/" - none echo "hello world")
    utest::assert_equal "$output" "xxx world"
}

function cmd::_test_stdout_handler_error() {
    local output
    output=$(cmd::run_cmd grep "xxxx" - none echo "hello world")
    utest::assert "$?"
    utest::assert_equal "$output" ""
}

function cmd::_test_stderr_handler() {
    local output
    output=$(cmd::run_cmd none sed "s/hello/xxx/" - echo "hello world" "1>&2")
    utest::assert_equal "$output" "xxx world"
}

function cmd::_test_stderr_handler_error() {
    local output
    output=$(cmd::run_cmd none grep "xxxx" - echo "hello world" "1>&2")
    utest::assert "$?"
    utest::assert_equal "$output" ""
}

# cmd::run_cmd 的测试案例
function cmd::_test_run_cmd() {
    # 测试普通的命令
    cmd::_test_simple_cmd || return "$SHELL_FALSE"

    # 测试错误的命令
    cmd::_test_simple_cmd_error || return "$SHELL_FALSE"

    # 测试带参数的命令

    # 测试双引号

    # 测试单引号

    # 测试管道符
    cmd::_test_pipe || return "$SHELL_FALSE"

    # 测试多个管道符
    cmd::_test_multi_pipe || return "$SHELL_FALSE"

    # 测试重定向
    cmd::_test_redirect || return "$SHELL_FALSE"

    # 测试标准输出处理函数
    cmd::_test_stdout_handler || return "$SHELL_FALSE"

    # 测试标准输出处理函数返回失败
    cmd::_test_stdout_handler_error || return "$SHELL_FALSE"

    # 测试标准错误输出处理函数
    cmd::_test_stderr_handler || return "$SHELL_FALSE"

    # 测试标准错误输出处理函数返回失败
    cmd::_test_stderr_handler_error || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

string::is_true "$TEST" && cmd::_test_run_cmd
cmd::_init_cmd_history_filepath
