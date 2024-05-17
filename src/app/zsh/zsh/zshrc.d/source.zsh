#!/bin/zsh

# 因为支持子目录，所以不使用 find 的 regex 匹配，正则匹配的是路径，而不是文件名。
for temp_str in $(find "${0:A:h}" -regex ".*/[0-9][0-9][0-9]-.*\.zsh$" | sort); do
    source "$temp_str"
done
unset temp_str
