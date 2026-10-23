return {
    "nvim-telescope/telescope.nvim",
    -- master, not the 0.1.x release branch: 0.1.x still calls the old
    -- nvim-treesitter API in its previewer, which the main branch of
    -- nvim-treesitter (lua/plugins/treesitter.lua) no longer has
    branch = "master",
    cmd = "Telescope",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
        { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
        { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Find text" },
        { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find buffers" },
        { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Find help" },
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
                file_ignore_patterns = {
                    "%.git/",
                    "node_modules/",
                    "build/",
                    "dist/",
                    "target/",
                    "__pycache__/",
                    "%.venv/",
                    "venv/",
                    "%.mypy_cache/",
                    "%.pytest_cache/",
                    "%.cache/",
                    "%.o$",
                    "%.a$",
                    "%.so$",
                    "%.pdf$",
                    "%.aux$",
                    "%.log$",
                },
                mappings = {
                    i = {
                        ["<C-j>"] = "move_selection_next",
                        ["<C-k>"] = "move_selection_previous",
                        ["<C-q>"] = "send_selected_to_qflist",
                        ["<C-u>"] = false,
                        ["<C-d>"] = false,
                    },
                },
            },
        })
        pcall(telescope.load_extension, "fzf")
    end,
}
