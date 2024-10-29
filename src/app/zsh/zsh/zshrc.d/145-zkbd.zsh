# 运行 /usr/share/zsh/functions/Misc/zkbd 脚本生成映射文件
if [ -e "$HOME/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}" ];then
    source "$HOME/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}"
elif [ -e "$HOME/.zkbd/$TERM-$VENDOR-$OSTYPE" ];then
    source "$HOME/.zkbd/$TERM-$VENDOR-$OSTYPE"
fi
