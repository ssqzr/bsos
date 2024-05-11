-- 颜色和外观的相关配置
local wezterm = require 'wezterm'
local utils = require "lib.utils"


local theme = {}
local colors = nil
local cache_dir = utils.get_cache_dir()

if utils.file_exists(cache_dir .. "/colors/wezterm_colors.lua") then
    package.path = package.path .. ";" .. cache_dir .. "/colors/wezterm_colors.lua"
    colors = require("wezterm_colors")
end

function theme.colors(config)
    if colors == nil then
        local color_scheme = 'Breeze'
        wezterm.log_warn("color_scheme is nil, set color_scheme to ", color_scheme)
        config.color_scheme = color_scheme
    else
        local color_scheme = {
            -- NOTE: zsh 也会设置终端的颜色，为了让其他终端也有良好的颜色体验，我们会以 zsh 的颜色为主
            foreground = colors.foreground,
            background = colors.background,
            cursor_bg = colors.foreground,
            cursor_fg = colors.background,
            cursor_border = colors.color4,
            selection_bg = colors.color7,
            selection_fg = colors.foreground,
            tab_bar = {
                background = colors.background,
                active_tab = {
                    bg_color = colors.background,
                    fg_color = colors.foreground,
                },
                inactive_tab = {
                    bg_color = colors.foreground,
                    fg_color = colors.background,
                },
                inactive_tab_hover = {
                    bg_color = colors.color4,
                    fg_color = colors.color1,
                },
                new_tab = {
                    bg_color = colors.color6,
                    fg_color = colors.color7,
                },
                new_tab_hover = {
                    bg_color = colors.color4,
                    fg_color = colors.color1,
                    italic = true,
                },
            },
        }
        config.colors = color_scheme
    end
end

function theme.window_background_gradient(config)
    if colors == nil then
        wezterm.log_warn("colors is nil, will not set window_background_gradient")
        return
    end
    config.window_background_gradient = {
        -- Can be "Vertical" or "Horizontal".  Specifies the direction
        -- in which the color gradient varies.  The default is "Horizontal",
        -- with the gradient going from left-to-right.
        -- Linear and Radial gradients are also supported; see the other
        -- examples below
        orientation = { Linear = { angle = -45.0 } },

        -- Specifies the set of colors that are interpolated in the gradient.
        -- Accepts CSS style color specs, from named colors, through rgb
        -- strings and more
        colors = {
            colors.background,
            colors.color0,
            colors.color8,
        },

        -- Instead of specifying `colors`, you can use one of a number of
        -- predefined, preset gradients.
        -- A list of presets is shown in a section below.
        -- preset = "Warm",

        -- Specifies the interpolation style to be used.
        -- "Linear", "Basis" and "CatmullRom" as supported.
        -- The default is "Linear".
        interpolation = 'Basis',

        -- How the colors are blended in the gradient.
        -- "Rgb", "LinearRgb", "Hsv" and "Oklab" are supported.
        -- The default is "Rgb".
        blend = 'Rgb',

        -- To avoid vertical color banding for horizontal gradients, the
        -- gradient position is randomly shifted by up to the `noise` value
        -- for each pixel.
        -- Smaller values, or 0, will make bands more prominent.
        -- The default value is 64 which gives decent looking results
        -- on a retina macbook pro display.
        -- noise = 64,

        -- By default, the gradient smoothly transitions between the colors.
        -- You can adjust the sharpness by specifying the segment_size and
        -- segment_smoothness parameters.
        -- segment_size configures how many segments are present.
        -- segment_smoothness is how hard the edge is; 0.0 is a hard edge,
        -- 1.0 is a soft edge.

        -- segment_size = 11,
        -- segment_smoothness = 0.0,
    }
end

return theme
