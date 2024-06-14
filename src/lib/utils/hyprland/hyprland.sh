#!/bin/bash

if [ -n "${SCRIPT_DIR_8cc6ad8f}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_8cc6ad8f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/../log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/../fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/hyprctl.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/config.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_8cc6ad8f}/hyprpm.sh"
