return {
    -- Oceanic Next: same theme as in plain Vim (~/.vimrc) so both editors
    -- match each other and the Frutiger Aero blue/teal desktop palette.
    "mhartington/oceanic-next",
    priority = 1000,
    config = function()
        vim.g.oceanic_next_terminal_bold = 1
        vim.g.oceanic_next_terminal_italic = 1
        -- transparent background: show alacritty's own (translucent) background
        -- instead of the theme's; re-applied on every colorscheme change
        local function transparent_bg()
            for _, group in ipairs({ "Normal", "NormalNC", "NonText", "EndOfBuffer", "LineNr", "SignColumn", "FoldColumn", "WinSeparator" }) do
                local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
                hl.bg, hl.ctermbg = nil, nil
                vim.api.nvim_set_hl(0, group, hl)
            end
        end
        vim.api.nvim_create_autocmd("ColorScheme", { callback = transparent_bg })
        vim.cmd.colorscheme("OceanicNext")
        transparent_bg()
    end,
}
