-- A mark in the sign column where a code action is available
-- (<leader>ca applies it). Colour: LightBulbSign in lua/plugins/colorscheme.lua.
return {
    "kosayoda/nvim-lightbulb",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        priority = 1000,
        link_highlights = false,
        autocmd = {
            enabled = true,
            updatetime = 500,
            events = { "CursorHold", "CursorHoldI" },
        },
        sign = { enabled = true, text = "A", hl = "LightBulbSign" },
        virtual_text = { enabled = false },
        float = { enabled = false },
        status_text = { enabled = false },
        number = { enabled = false },
        line = { enabled = false },
    },
}
