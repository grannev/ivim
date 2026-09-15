-- The island layer of iVim: island-shell (~/it/coding/island-shell) is the
-- Dynamic Island at the top of the screen, and with this plugin it is
-- Neovim's status line — the mode, the file, the position, git and the
-- diagnostics live there, saves and LSP progress arrive as pills, and the
-- pointer on the island opens the buffer list. The plugin itself lives in
-- the island's repository (nvim/lua/island.lua); when that checkout is not
-- around, the copy its install script puts on the runtime path is used.
--
-- Everything in this file is owned by the island side; see CLAUDE.md.
local checkout = vim.fn.expand("~/it/coding/island-shell/nvim")
local source = vim.uv.fs_stat(checkout) and checkout or vim.fn.stdpath("data") .. "/site"

return {
    {
        -- the island says all of it already
        "nvim-lualine/lualine.nvim",
        enabled = false,
    },
    {
        dir = source,
        name = "island.nvim",
        lazy = false,
        priority = 100,
        config = function()
            require("island").setup()
        end,
    },
}
