return {
    "nvim-pack/nvim-spectre",
    cmd = { "Spectre" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>sr", function() require("spectre").open() end, desc = "Search and replace in project" },
        {
            "<leader>sR",
            function()
                require("spectre").open_visual({ select_word = true })
            end,
            desc = "Replace word under cursor",
        },
        {
            "<leader>sF",
            function()
                require("spectre").open_file_search({ select_word = true })
            end,
            desc = "Replace in current file",
        },
    },
    opts = {
        color_devicons = false,
        open_cmd = "noswapfile vnew",
        mapping = {
            ["toggle_line"] = {
                map = "dd",
                cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
                desc = "Toggle current item",
            },
            ["enter_file"] = {
                map = "<CR>",
                cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
                desc = "Open file",
            },
            ["send_to_qf"] = {
                map = "<leader>q",
                cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
                desc = "Send all items to quickfix",
            },
            ["replace_cmd"] = {
                map = "<leader>c",
                cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
                desc = "Input replace command",
            },
            ["run_current_replace"] = {
                map = "<leader>rc",
                cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
                desc = "Replace current line",
            },
            ["run_replace"] = {
                map = "<leader>ra",
                cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
                desc = "Replace all",
            },
            ["change_view_mode"] = {
                map = "<leader>v",
                cmd = "<cmd>lua require('spectre').change_view()<CR>",
                desc = "Change result view mode",
            },
        },
    },
}
