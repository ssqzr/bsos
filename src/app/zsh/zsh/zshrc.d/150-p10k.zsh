# 设置主题
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if os::tty::is_support_256color;then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/p10k/p10k.zsh"
else
    source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/p10k/p10k_vtty.zsh"
fi