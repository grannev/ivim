-- Neovide only: the terminal's font and translucency (Alacritty uses
-- JetBrainsMono Nerd Font Mono at 13 and opacity 0.75). Neovide animates
-- the cursor and scrolling itself, so neoscroll and mini.animate stay off
-- there (lua/plugins/animate.lua).
if not vim.g.neovide then
    return
end

vim.o.guifont = "JetBrainsMono Nerd Font Mono:h13"
vim.g.neovide_opacity = 0.75
