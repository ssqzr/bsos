#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_98e0c032="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

SRC_DIR="$(dirname "${SCRIPT_DIR_98e0c032}")"
SRC_DIR="$(realpath "${SRC_DIR}")"

# shellcheck disable=SC1091
source "${SRC_DIR}/lib/utils/array.sh"

function main() {
    local tests=()

    readarray -t tests < <(grep "\$TEST" -rn "${SRC_DIR}" | grep -v "test.sh" | awk -F ':' '{print $1}')

    array::dedup tests

    local filepath

    for filepath in "${tests[@]}"; do
        TEST=1 "$filepath"
    done
}

main
