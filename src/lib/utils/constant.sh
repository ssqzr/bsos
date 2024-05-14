#!/bin/bash

# 常量的定义，确保时通用的定义，全部的脚本都可以用的
# 一些部分脚本才可以用的定义应该定义到各自的脚本里，不要定义在这里

# 在shell里的True值
# shellcheck disable=SC2034
declare -i SHELL_TRUE=0

# 在shell里的False值，一般性未知错误
declare -i SHELL_FALSE=1

# https://tldp.org/LDP/abs/html/exitcodes.html
# 退出码的定义
# 命令返回成功
declare -i CODE_SUCCESS=0
# 一般性错误
declare -i CODE_ERROR=1
# 命令（或参数）使用不当
declare -i CODE_USAGE=2
# 权限被拒绝（或）无法执行
declare -i CODE_PERMISSION=126
# 未找到命令，或 PATH 错误
declare -i CODE_COMMAND_NOT_FOUND=127
# 当应用程序或命令因致命错误而终止或执行失败时，将产生 128 系列退出码（128+n），其中 n 为信号编号。
# 通过 Ctrl+C 或 SIGINT 终止（终止代码 2 或键盘中断）
declare -i CODE_INTERRUPTED=130
# 通过 SIGTERM 终止（默认终止）
declare -i CODE_TERMINATED=143
# 退出码超过了 0-255 的范围，因此重新计算（LCTT 译注：超过 255 后，用退出码对 256 取模）
# 255/*
