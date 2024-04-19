#!/bin/zsh

source "${0:A:h}/constant.zsh"

function os::tty::is_vtty() {
    if [ "$TERM" = "linux" ]; then
        return $SHELL_TRUE
    fi
    return $SHELL_FALSE
}

function os::tty::is_support_256color() {
    if zmodload zsh/terminfo && ((terminfo[colors] >= 256)); then
        return $SHELL_TRUE
    else
        return $SHELL_FALSE
    fi
}
