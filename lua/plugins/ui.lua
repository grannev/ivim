return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            view = { width = 30 },
            renderer = {
                root_folder_label = false,
                icons = { show = { file = false, folder = false, folder_arrow = true, git = false } },
            },
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = { preset = "classic", win = { border = "rounded", wo = { winblend = 0 } }, icons = { mappings = false } },
    },
    {
        "lewis6991/gitsigns.nvim",
        opts = {},
    },
}
