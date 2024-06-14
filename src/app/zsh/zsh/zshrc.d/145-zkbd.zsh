# run /usr/share/zsh/functions/Misc/zkbd to generate
if [ -e "$HOME/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}" ];then
    source "$HOME/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}"
fi