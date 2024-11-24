#!/bin/bash

if [ -n "${SCRIPT_DIR_8a3b5757}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_8a3b5757="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_8a3b5757}/../../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8a3b5757}/../../../print.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8a3b5757}/../../../utest.sh"

# 命名规范： __SPINNER_{name}_FRAMES
# 脚本会解析 name 的值
declare __SPINNER_LINE_FRAMES=("|" "/" "-" "\\")
declare __SPINNER_DOT_FRAMES=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
declare __SPINNER_MINIDOT_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# 其他类型可能在 tty 下不能正常显示
declare __SPINNER_DEFAULT_TYPE="line"

function tui::components::spinner::all_type() {
    # shellcheck disable=SC2034
    local -n all_type_89e50648="$1"
    local temp_89e50648

    temp_89e50648=$(grep "declare" "${BASH_SOURCE[0]}" | grep "__SPINNER_.*_FRAMES" | grep -v grep | awk -F '_' '{print $4}') || return "${SHELL_FALSE}"

    temp_89e50648="${temp_89e50648,,}"
    array::readarray all_type_89e50648 <<<"$temp_89e50648"

    return "${SHELL_TRUE}"
}

function tui::components::spinner::get_frames_by_type() {
    local -n frame_969e3d8e="$1"
    shift
    local spinner_type_969e3d8e="$1"
    shift

    case "$spinner_type_969e3d8e" in
    "line")
        frame_969e3d8e=("${__SPINNER_LINE_FRAMES[@]}")
        ;;
    "dot")
        frame_969e3d8e=("${__SPINNER_DOT_FRAMES[@]}")
        ;;
    "minidot")
        # shellcheck disable=SC2034
        frame_969e3d8e=("${__SPINNER_MINIDOT_FRAMES[@]}")
        ;;
    *)
        lerror "invalid spinner type: $spinner_type_969e3d8e"
        return "${SHELL_FALSE}"
        ;;
    esac

    return "${SHELL_TRUE}"
}

function tui::components::spinner::frame() {
    local spinner_type="$1"
    shift
    local count="$1"
    shift

    local frame
    local frame_index

    tui::components::spinner::get_frames_by_type frame "$spinner_type" || return "$SHELL_FALSE"

    frame_index=$((count % ${#frame[@]}))
    frame="${frame[frame_index]}"

    echo "$frame"

    return "${SHELL_TRUE}"
}

# 运行脚本或者命令时，显示一个 spinner
# 说明：
#   1. 执行的命令最好不要有任何标准输出和错误输出，当前还没处理它的标准输出和错误输出
# 可选参数：
#   --spinner=__SPINNER_DEFAULT_TYPE    string              spinner 类型，默认为 __SPINNER_DEFAULT_TYPE 。可选的值有： $(tui::components::spinner::all_type)
#   --fps=FPS                           string              刷新频率，单位为秒
#   --title="Loading..."                string              显示在 spinner 旁边的文字
#   --align="left"                      string              对齐方式，可选的值有： left,center,right
#   --                                                  分隔符，后面的字符不会被解析，全部传给要执行的命令作为它的参数
# 位置参数：
#   code                                int 的引用           存储执行命令的推出码
#   cmd                                 string              要运行的命令
#   [args]                              string              要运行的命令的参数
# 标准输出： spinner 显示的信息
# 返回值：
#   ${SHELL_TRUE} 表示执行命令成功
#   ${SHELL_FALSE} 表示执行命令失败
function tui::components::spinner::main() {
    local -n code_6eb96c5f
    local spinner_type_6eb96c5f="${__SPINNER_DEFAULT_TYPE}"
    local fps_6eb96c5f="0.3"
    local title_6eb96c5f="Loading..."
    local align_6eb96c5f="left"
    local cmds_6eb96c5f=()

    # shellcheck disable=SC2034
    local valid_align_6eb96c5f=("left" "right")
    # shellcheck disable=SC2034
    local valid_spinner_type_6eb96c5f

    local count_6eb96c5f=0
    local frame_6eb96c5f
    local printf_left_6eb96c5f
    local printf_right_6eb96c5f
    local start_6eb96c5f
    local used_6eb96c5f=0
    local pid_6eb96c5f
    local tmp_filepath_6eb96c5f

    local is_parse_self_6eb96c5f="$SHELL_TRUE"
    local param_6eb96c5f

    tui::components::spinner::all_type valid_spinner_type_6eb96c5f || return "${SHELL_FALSE}"

    for param_6eb96c5f in "$@"; do
        if [ "$is_parse_self_6eb96c5f" == "$SHELL_FALSE" ]; then
            cmds_6eb96c5f+=("${param_6eb96c5f}")
            continue
        fi

        case "${param_6eb96c5f}" in
        --)
            is_parse_self_6eb96c5f="$SHELL_FALSE"
            ;;
        --spinner=*)
            parameter::parse_string --default="${spinner_type_6eb96c5f}" --enum=valid_spinner_type_6eb96c5f --option="${param_6eb96c5f}" spinner_type_6eb96c5f || return "${SHELL_FALSE}"
            ;;
        --fps=*)
            parameter::parse_string --default="${fps_6eb96c5f}" --option="${param_6eb96c5f}" fps_6eb96c5f || return "${SHELL_FALSE}"
            ;;
        --title=*)
            parameter::parse_string --default="${title_6eb96c5f}" --option="${param_6eb96c5f}" title_6eb96c5f || return "${SHELL_FALSE}"
            ;;
        --align=*)
            parameter::parse_string --default="${align_6eb96c5f}" --enum=valid_align_6eb96c5f --option="${param_6eb96c5f}" align_6eb96c5f || return "${SHELL_FALSE}"
            ;;
        -*)
            lerror "invalid option: ${param_6eb96c5f}"
            return "${SHELL_FALSE}"
            ;;
        *)
            if [ ! -R code_6eb96c5f ]; then
                code_6eb96c5f="${param_6eb96c5f}"
                continue
            fi
            cmds_6eb96c5f+=("${param_6eb96c5f}")
            # lerror "invalid param: $param"
            # return "${SHELL_FALSE}"
            ;;
        esac
    done

    if [ ! -R code_6eb96c5f ]; then
        lerror "param code is required"
        return "${SHELL_FALSE}"
    else
        code_6eb96c5f=0
    fi

    linfo "start running command: ${cmds_6eb96c5f[*]}"

    tmp_filepath_6eb96c5f="/tmp/bsos_spinner_$$_$(date +%s.%N)"

    {
        "${cmds_6eb96c5f[@]}"
        echo $? >"${tmp_filepath_6eb96c5f}"
    } &
    pid_6eb96c5f=$!

    start_6eb96c5f=$(date +%s.%N)
    while true; do
        used_6eb96c5f="$(math::sub "$(date +%s.%N)" "${start_6eb96c5f}" 3)"
        frame_6eb96c5f=$(tui::components::spinner::frame "${spinner_type_6eb96c5f}" "${count_6eb96c5f}") || return "${SHELL_FALSE}"
        printf_right_6eb96c5f="waiting ${used_6eb96c5f}"
        case "${align_6eb96c5f}" in
        "left")
            printf_left_6eb96c5f="${frame_6eb96c5f} ${title_6eb96c5f}"
            ;;
        "right")
            printf_left_6eb96c5f="${title_6eb96c5f} ${frame_6eb96c5f}"
            ;;
        *)
            lerror "invalid align: ${align_6eb96c5f}"
            return "${SHELL_FALSE}"
            ;;
        esac

        # 参考： https://stackoverflow.com/a/35054595
        printf_yellow --format="\r%*s\r%s" "$(tput cols)" -- "${printf_right_6eb96c5f}" "${printf_left_6eb96c5f}"
        count_6eb96c5f=$((count_6eb96c5f + 1))

        waitpid --timeout "${fps_6eb96c5f}" -e "${pid_6eb96c5f}"
        case "$?" in
        0)
            ldebug "waitpid pid(${pid_6eb96c5f}) success"
            println_yellow ""
            code_6eb96c5f=$(cat "${tmp_filepath_6eb96c5f}")
            rm -f "${tmp_filepath_6eb96c5f}"
            linfo "command exit with code: ${code_6eb96c5f}"
            return "${SHELL_TRUE}"
            ;;
        3)
            ldebug "timeout waitpid pid(${pid_6eb96c5f})"
            continue
            ;;
        *)
            lerror "waitpid pid(${pid_6eb96c5f}) failed, code=$?"
            return "${SHELL_FALSE}"
            ;;
        esac
    done
}
