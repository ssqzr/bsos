#!/bin/bash

if [ -n "${SCRIPT_DIR_0af2c712}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_0af2c712="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_0af2c712}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_0af2c712}/path.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_0af2c712}/file.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_0af2c712}/directory.sh"
