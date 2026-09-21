return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
        local telescope = require("telescope")
        telescope.setup({
            defaults = {
                winblend = 0,
                sorting_strategy = "ascending",
                layout_config = {
                    width = 0.78,
                    height = 0.65,
                    horizontal = { prompt_position = "top", preview_cutoff = 110 },
                },
                prompt_prefix = "  › ",
                selection_caret = "  ",
                entry_prefix = "  ",
                path_display = { "smart" },
                border = true,
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                mappings = {
                    i = { ["<C-u>"] = false, ["<C-d>"] = false },
                },
            },
        })
        pcall(telescope.load_extension, "fzf")
    end,
}
