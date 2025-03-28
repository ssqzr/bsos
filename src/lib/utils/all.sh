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
source "${SCRIPT_DIR_cd871afe}/log/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/fs/fs.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/tui/tui.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/cfg/cfg.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/sed.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/process.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/systemctl.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/os/os.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/gsettings.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/hyprland/hyprland.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/fish/fish.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/flatpak/flatpak.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/storage/storage.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/math/math.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/swap.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_cd871afe}/lock.sh"
