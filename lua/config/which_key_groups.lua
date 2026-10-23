vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        local ok, wk = pcall(require, "which-key")
        if not ok then
            return
        end
        wk.add({
            { "<leader>b", group = "buffers" },
            { "<leader>c", group = "config" },
            { "<leader>D", group = "debug" },
            { "<leader>f", group = "find" },
            { "<leader>g", group = "git" },
            { "<leader>i", group = "inlay hints" },
            { "<leader>l", group = "lsp / latex" },
            { "<leader>m", group = "make / quickfix" },
            { "<leader>r", group = "run / rust" },
            { "<leader>s", group = "session / search / spell" },
            { "<leader>t", group = "tabs" },
            { "<leader>u", group = "ui toggles" },
            { "<leader>x", group = "diagnostics / trouble" },
        })
    end,
})
