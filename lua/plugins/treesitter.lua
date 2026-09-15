return {
    "nvim-treesitter/nvim-treesitter",
    -- main dropped the nvim-treesitter.configs API entirely (v1 rewrite);
    -- master still has it and is what every highlight/indent = enable
    -- style config (like this one) needs.
    branch = "master",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "c",
                "go",
                "python",
                "javascript",
                "typescript",
                "tsx",
                "lua",
                "bash",
                "json",
                "yaml",
                "markdown",
                "markdown_inline",
                "dockerfile",
                "html",
                "css",
                "vim",
                "vimdoc",
                "query",
            },
            highlight = { enable = true },
            indent = { enable = true },
        })
    end,
}
