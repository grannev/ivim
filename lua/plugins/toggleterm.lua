return {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
        { "<C-\\>", "<cmd>ToggleTerm direction=float<CR>", desc = "Toggle floating terminal" },
        { "<C-\\>", "<cmd>ToggleTerm direction=float<CR>", mode = "t", desc = "Toggle floating terminal" },
        { "<Esc>", [[<C-\><C-n>]], mode = "t", desc = "Exit terminal mode" },
    },
    opts = {
        direction = "float",
        shade_terminals = false,
        start_in_insert = true,
        persist_size = true,
        close_on_exit = true,
        float_opts = {
            border = "rounded",
            width = function()
                return math.floor(vim.o.columns * 0.85)
            end,
            height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
        },
    },
}
