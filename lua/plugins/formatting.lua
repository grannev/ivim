return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            go = { "gofmt" },
            python = { "black" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            lua = { "stylua" },
            json = { "prettier" },
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
        },
    },
}
