local wezterm = require 'wezterm'
local theme = require('config.theme')
local tab = require('config.tab')
local mux = wezterm.mux
local act = wezterm.action

local config = wezterm.config_builder()

-- FIXME: https://github.com/wez/wezterm/issues/5103
config.enable_wayland = false

-- 默认光标的样式
config.default_cursor_style = 'BlinkingBlock'
config.hide_mouse_cursor_when_typing = true

theme.config(config)
tab.config(config)

-- 字体
-- wezterm 捆绑了 JetBrains Mono
-- config.font = wezterm.font 'JetBrains Mono'
config.font_size = 10;

config.default_prog = { '/usr/bin/zsh' }
-- 背景透明度
config.window_background_opacity = 1
config.text_background_opacity = 1.0

-- 不活动窗体的样式
config.inactive_pane_hsb = {
    -- 色调
    -- hue = 0.6,
    -- 饱和度
    saturation = 0.8,
    -- 亮度
    brightness = 0.6,
}


-- https://wezfurlong.org/wezterm/config/keys.html?h=leader#leader-key
config.leader = { key = 'k', mods = 'CTRL', timeout_milliseconds = 1000 }

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
}

-- 启动时窗口最大化
-- https://wezfurlong.org/wezterm/config/lua/gui-events/gui-startup.html
wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return config
