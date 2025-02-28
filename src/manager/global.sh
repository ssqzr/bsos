#!/bin/bash

# 全局可用的函数和变量

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_942ac773="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_942ac773}/../lib/utils/all.sh"

function global::project_name() {
    echo "bsos"
}

function global::temp_base_dir() {
    echo "$(os::path::temp_temp_base_dir)/$(global::project_name)"
}
