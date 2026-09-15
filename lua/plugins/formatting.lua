return {
    "stevearc/conform.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
        formatters_by_ft = {
            go = { "gofmt" },
            -- ruff's formatter is black-compatible and, unlike black, comes
            -- from mason as a single binary (this machine has no pip)
            python = { "ruff_format" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            lua = { "stylua" },
            json = { "prettier" },
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
        },
        -- a missing formatter falls back to the LSP quietly instead of a
        -- warning on every save
        notify_no_formatters = false,
    },
    config = function(_, opts)
        require("conform").setup(opts)
        -- the formatters above come from mason like the language servers do;
        -- fetch the ones that are not there yet (gofmt ships with Go)
        local ok, registry = pcall(require, "mason-registry")
        if not ok then
            return
        end
        for _, name in ipairs({ "ruff", "stylua", "prettier" }) do
            local found, package = pcall(registry.get_package, name)
            if found and not package:is_installed() then
                package:install()
            end
        end
    end,
}
