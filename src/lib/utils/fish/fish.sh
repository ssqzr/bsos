#!/bin/bash

if [ -n "${SCRIPT_DIR_d055412f}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d055412f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_d055412f}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_d055412f}/config.sh"
