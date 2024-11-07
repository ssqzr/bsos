-- 鼠标相关设置

local wezterm = require 'wezterm'
local act = wezterm.action

local mouse = {}

function mouse.config(config)
    -- 输入时隐藏鼠标光标
    config.hide_mouse_cursor_when_typing = true

    -- 鼠标按键绑定
    config.mouse_bindings = {
        -- https://wezfurlong.org/wezterm/config/mouse.html#configuring-mouse-assignments
        -- Scrolling up while holding CTRL increases the font size
        {
            event = { Down = { streak = 1, button = { WheelUp = 1 } } },
            mods = 'CTRL',
            action = act.IncreaseFontSize,
        },

        -- Scrolling down while holding CTRL decreases the font size
        {
            event = { Down = { streak = 1, button = { WheelDown = 1 } } },
            mods = 'CTRL',
            action = act.DecreaseFontSize,
        },
    }
end

return mouse
