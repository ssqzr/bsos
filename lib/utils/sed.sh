#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_66955168="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_66955168}/constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_66955168}/cmd.sh"

# 删除匹配的两行之间的内容，包括匹配的两行
function sed::delete_between_line() {
    local first_match="$1"
    local last_match="$2"
    local filepath="$3"
    # https://www.cnblogs.com/mingzhang/p/10026644.html
    # https://stackoverflow.com/questions/6287755/using-sed-to-delete-all-lines-between-two-matching-patterns
    # https://stackoverflow.com/questions/5071901/removing-lines-between-two-patterns-not-inclusive-with-sed
    # sed "/${first_match}/,/${last_match}/{/.*/d}" "$filepath"
    cmd::run_cmd_with_history sed -i "'/${first_match}/,/${last_match}/d'" "$filepath"

    # 这个是不包含匹配的两行
    # sed "/${first_match}/,/${last_match}/{//!d}" "$filepath"
}
