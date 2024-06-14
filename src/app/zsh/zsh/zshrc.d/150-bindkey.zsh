
# "--" 的解答： https://unix.stackexchange.com/questions/11376/what-does-double-dash-mean
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete


# 快捷键的设置
# 运行 showkey -a 可以查看按键
# https://wiki.zshell.dev/zh-Hans/docs/guides/syntax/bindkey
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
# Alt-j
bindkey "^[j" backward-char
# Alt-l
bindkey "^[l" forward-char
# Alt-i
bindkey "^[i" up-line-or-history
# Alt-k
bindkey "^[k" down-line-or-history
# Alt-;
bindkey "^[;" end-of-line
# Alt-h
bindkey "^[h" beginning-of-line
# https://zsh.sourceforge.io/Doc/Release/Parameters.html 搜索 WORDCHARS
# word 的分隔符定义是 $WORDCHARS
# Ctrl-Backspace
bindkey "^H" backward-kill-word
# Ctrl-Delete
bindkey "^[[3;5~" kill-word
# Ctrl-left
bindkey "^[[1;5D" backward-word
# Ctrl-right
bindkey "^[[1;5C" forward-word