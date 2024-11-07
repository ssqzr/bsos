local wezterm = require 'wezterm'
local theme = require('config.theme')
local tab = require('config.tab')
local keys = require('config.keys')
local mouse = require('config.mouse')
local mux = wezterm.mux

local config = wezterm.config_builder()


-- 默认光标的样式
config.default_cursor_style = 'BlinkingBlock'

theme.config(config)
tab.config(config)
keys.config(config)
mouse.config(config)

-- 字体
-- wezterm 捆绑了 JetBrains Mono
-- config.font = wezterm.font 'JetBrains Mono'
config.font_size = 10;

-- https://wezfurlong.org/wezterm/config/lua/config/adjust_window_size_when_changing_font_size.html
-- 通过 CTRL + -/= 调整字体大小时不调整窗口大小，否则在平铺窗口管理器下体验不佳
-- https://wezfurlong.org/wezterm/config/lua/keyassignment/DecreaseFontSize.html
-- CTRL + - DecreaseFontSize
-- https://wezfurlong.org/wezterm/config/lua/keyassignment/IncreaseFontSize.html
-- CTRL + = IncreaseFontSize
-- https://wezfurlong.org/wezterm/config/lua/keyassignment/ResetFontSize.html
-- CTRL + 0 ResetFontSize
config.adjust_window_size_when_changing_font_size = false

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




-- 启动时窗口最大化
-- https://wezfurlong.org/wezterm/config/lua/gui-events/gui-startup.html
wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return config
