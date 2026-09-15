return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            -- lualine ships this theme itself (lualine/themes/OceanicNext.lua).
            options = { theme = "OceanicNext", globalstatus = true },
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {},
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        enabled = false,
        main = "ibl",
        opts = {},
    },
    {
        "lewis6991/gitsigns.nvim",
        opts = {},
    },
}
