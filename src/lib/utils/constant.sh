#!/bin/bash

# 常量的定义，确保时通用的定义，全部的脚本都可以用的
# 一些部分脚本才可以用的定义应该定义到各自的脚本里，不要定义在这里

# 在shell里的True值
# shellcheck disable=SC2034
declare -i SHELL_TRUE=0

# 在shell里的False值
declare -i SHELL_FALSE=1
