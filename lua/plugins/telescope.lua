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
                mappings = {
                    i = { ["<C-u>"] = false, ["<C-d>"] = false },
                },
            },
        })
        pcall(telescope.load_extension, "fzf")
    end,
}
