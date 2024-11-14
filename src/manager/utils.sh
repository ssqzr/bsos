#!/bin/bash

# 说明：

# 这里是工具函数的集合，存放那些和业务无关，不知道放哪里，其他脚本又需要用到的函数。

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_39ba7b38="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_39ba7b38}/../lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_39ba7b38}/../lib/utils/utest.sh"

# 将 app_name 转换为 package:app_name 的格式
function manager::utils::convert_app_name() {
    local app_name="$1"
    shift

    if [ "$(string::find "${app_name}" ":")" -ge 0 ]; then
        echo "${app_name}"
    else
        echo "custom:${app_name}"
    fi
    return "${SHELL_TRUE}"
}

########################################### 下面是测试代码 ###########################################

function TEST::manager::utils::convert_app_name() {
    utest::assert_equal "$(manager::utils::convert_app_name "app_name")" "custom:app_name"
    utest::assert_equal "$(manager::utils::convert_app_name "yay:app_name")" "yay:app_name"
    utest::assert_equal "$(manager::utils::convert_app_name "pacman:app_name")" "pacman:app_name"
    utest::assert_equal "$(manager::utils::convert_app_name "pacman::app_name")" "pacman::app_name"
}
