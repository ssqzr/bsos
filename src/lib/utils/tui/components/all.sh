#!/bin/bash

if [ -n "${SCRIPT_DIR_68b89900}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_68b89900="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_68b89900}/../../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_68b89900}/spinner/spinner.sh"
