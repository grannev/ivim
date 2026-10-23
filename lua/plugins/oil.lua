-- The file explorer is a buffer: edit the listing, :w applies it. It
-- replaces netrw, so `nvim .` opens it too.
return {
    "stevearc/oil.nvim",
    lazy = false,
    keys = {
        { "-", function() require("oil").open() end, desc = "Open parent directory" },
        { "<leader>e", function() require("oil").open_float() end, desc = "Open file explorer" },
    },
    opts = {
        default_file_explorer = true,
        -- names only, like the rest of the editor's lists
        columns = {},
        view_options = { show_hidden = true },
        float = {
            padding = 2,
            max_width = 90,
            max_height = 30,
            border = "rounded",
        },
    },
}
