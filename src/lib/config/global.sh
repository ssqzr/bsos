#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d8d5b6c2="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_d8d5b6c2}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_d8d5b6c2}/yaml/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_d8d5b6c2}/yaml/map.sh"

if [ -z "${__config_filepath}" ]; then
    lerror "env __config_filepath is empty"
    exit 1
fi

# function config::global::reuse_cache::set_true() {
#     config::map::set ".global" "reuse_cache" "true" "${__config_filepath}" || return "$SHELL_FALSE"
#     return "$SHELL_TRUE"
# }

# function config::global::reuse_cache::set_false() {
#     config::map::set ".global" "reuse_cache" "false" "${__config_filepath}" || return "$SHELL_FALSE"
#     return "$SHELL_TRUE"
# }

# function config::global::reuse_cache::get() {
#     local value
#     value=$(config::map::get ".global" "reuse_cache") || return "$SHELL_FALSE"
#     if string::is_true "$value"; then
#         return "$SHELL_TRUE"
#     fi
#     return "$SHELL_FALSE"
# }
