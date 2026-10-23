return {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Project diagnostics" },
        { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
        { "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", desc = "LSP references" },
        { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
    },
    opts = {
        auto_close = false,
        auto_open = false,
        focus = true,
        win = { type = "split", position = "bottom", size = 8 },
        icons = {
            indent = { fold_open = "-", fold_closed = "+" },
            folder_closed = "",
            folder_open = "",
            kinds = {},
        },
    },
}
