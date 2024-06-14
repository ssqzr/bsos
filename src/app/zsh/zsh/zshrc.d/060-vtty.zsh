# 如果是 vtty ，设置本地化为 en_US.UTF-8 ，不然执行命令会乱码
if os::tty::is_vtty;then
    export LC_ALL=en_US.UTF-8
fi