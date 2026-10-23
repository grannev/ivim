-- Neovide only: the terminal's font and translucency (Alacritty uses
-- JetBrainsMono Nerd Font Mono at 13 and opacity 0.75), and :q in the last
-- window back to the start screen (lua/config/menu_quit.lua). Neovide
-- animates scrolling itself, so neoscroll and mini.animate stay off there
-- (lua/plugins/animate.lua); its cursor animation is off, as in the
-- terminal — a trailing cursor reads as lag.
if not vim.g.neovide then
    return
end

vim.o.guifont = "JetBrainsMono Nerd Font Mono:h13"
vim.g.neovide_opacity = 0.75
vim.g.neovide_cursor_animation_length = 0
vim.g.neovide_cursor_trail_size = 0
require("config.menu_quit").setup()
