#!/bin/bash

if [ -n "${SCRIPT_DIR_0dfb9771}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_0dfb9771="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_0dfb9771}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_0dfb9771}/override.sh"
