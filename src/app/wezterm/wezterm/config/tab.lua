require('events.tab-title').setup()

local tab = {}

function tab.config(config)
    config.enable_tab_bar = true
    config.tab_bar_at_bottom = false
    config.show_tab_index_in_tab_bar = false
    config.switch_to_last_active_tab_when_closing_tab = true
    config.hide_tab_bar_if_only_one_tab = false
    config.use_fancy_tab_bar = false
    config.tab_max_width = 50
end

return tab
