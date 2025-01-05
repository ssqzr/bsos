-- 快捷键相关的配置

local wezterm = require 'wezterm'
local act = wezterm.action

local keys = {}

function keys.config(config)
    -- https://wezfurlong.org/wezterm/config/keys.html?h=leader#leader-key
    config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

    config.keys = {
        {
            -- 全屏的快捷键
            -- https://wezfurlong.org/wezterm/config/lua/keyassignment/ToggleFullScreen.html?h=toggle+full+screen
            key = 'F11',
            -- mods = 'SHIFT|CTRL',
            action = wezterm.action.ToggleFullScreen
        },
        {
            -- 分割窗格，上下分屏，新的窗格在上面
            key = 'i',
            mods = 'LEADER',
            action = wezterm.action.SplitPane {
                direction = 'Up',
                -- command = { args = { 'top' } },
                size = { Percent = 50 },
                -- top_level = true
            },
        },
        {
            -- 分割窗格，上下分屏，新的窗格在下面
            key = 'k',
            mods = 'LEADER',
            action = wezterm.action.SplitPane {
                direction = 'Down',
                size = { Percent = 50 },
            },
        },
        {
            -- 分割窗格，左右分屏，新的窗格在左边
            key = 'j',
            mods = 'LEADER',
            action = wezterm.action.SplitPane {
                direction = 'Left',
                size = { Percent = 50 },
            },
        },
        {
            -- 分割窗格，左右分屏，新的窗格在右边
            key = 'l',
            mods = 'LEADER',
            action = wezterm.action.SplitPane {
                direction = 'Right',
                size = { Percent = 50 },
            },
        },
        {
            -- 窗格向上扩充5个单位
            key = 'i',
            mods = 'CTRL|SHIFT|ALT',
            action = act.AdjustPaneSize { 'Up', 5 }
        },
        {
            -- 窗格向下扩充5个单位
            key = 'k',
            mods = 'CTRL|SHIFT|ALT',
            action = act.AdjustPaneSize { 'Down', 5 },
        },
        {
            -- 窗格向左扩充5个单位
            key = 'j',
            mods = 'CTRL|SHIFT|ALT',
            action = act.AdjustPaneSize { 'Left', 5 },
        },
        {
            -- 窗格向右扩充5个单位
            key = 'l',
            mods = 'CTRL|SHIFT|ALT',
            action = act.AdjustPaneSize { 'Right', 5 },
        },
        {
            -- 选择分割的窗格
            key = '8',
            mods = 'CTRL',
            action = act.PaneSelect {
                -- alphabet = '1234567890'
                -- show_pane_ids = true
            }
        },
        {
            key = 'w',
            mods = 'CTRL',
            action = wezterm.action.CloseCurrentPane {
                confirm = true
            },
        },
        -- 解决在 hyprland + wayland 下复制和粘贴的问题
        -- wezterm-git 没有问题，切换回正式版本需要验证是否有问题
        -- https://wezfurlong.org/wezterm/config/lua/keyassignment/PasteFrom.html
        -- Ctrl + Shift + V 粘贴
        -- {
        --     key = 'V',
        --     mods = 'CTRL',
        --     action = act.PasteFrom 'Clipboard'
        -- },
        -- {
        --     key = 'C',
        --     mods = 'CTRL',
        --     action = wezterm.action.CopyTo 'Clipboard'
        -- },

        -- 滚动快捷键
        { key = 'i',        mods = 'CTRL',  action = act.ScrollByLine(-1) },
        { key = 'k',        mods = 'CTRL',  action = act.ScrollByLine(1) },
        { key = 'j',        mods = 'CTRL',  action = act.ScrollToPrompt(-1) },
        { key = 'l',        mods = 'CTRL',  action = act.ScrollToPrompt(1) },
        { key = 'h',        mods = 'CTRL',  action = act.ScrollToTop },
        { key = ';',        mods = 'CTRL',  action = act.ScrollToBottom },
        { key = 'PageUp',   mods = 'SHIFT', action = act.ScrollByPage(-0.5) },
        { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(0.5) },
    }
end

return keys
