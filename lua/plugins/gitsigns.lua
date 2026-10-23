-- The island reads vim.b.gitsigns_status_dict for the branch and the diff
-- (see CLAUDE.md): keep gitsigns.
return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
        { "]c", function() require("gitsigns").nav_hunk("next") end, desc = "Next git hunk" },
        { "[c", function() require("gitsigns").nav_hunk("prev") end, desc = "Previous git hunk" },
        { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview git hunk" },
        { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "Reset git hunk" },
        {
            "<leader>gb",
            function()
                require("gitsigns").blame_line({ full = true })
            end,
            desc = "Git blame line",
        },
    },
    opts = {
        signcolumn = true,
        numhl = false,
        linehl = false,
        current_line_blame = false,
    },
}
