return {
    "saghen/blink.cmp",
    dependencies = "rafamadriz/friendly-snippets",
    version = "*",
    opts = {
        keymap = {
            preset = "none",
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            ["<CR>"] = { "accept", "fallback_to_mappings" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<Esc>"] = { "hide", "fallback" },
        },
        completion = {
            list = {
                selection = { preselect = true, auto_insert = false },
            },
            menu = {
                auto_show = true,
                auto_show_delay_ms = 80,
                border = "rounded",
                max_height = 8,
                winblend = 0,
                draw = {
                    columns = {
                        { "kind_icon" },
                        { "label", "label_description", gap = 1 },
                        { "kind" },
                    },
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 400,
                window = { border = "rounded", winblend = 0 },
            },
        },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
    },
}
