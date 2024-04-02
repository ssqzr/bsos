#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_cd871afe="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/debug.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/print.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/file.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/tui.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/sed.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/process.sh"
