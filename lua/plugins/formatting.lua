return {
    "stevearc/conform.nvim",
    dependencies = { "williamboman/mason.nvim" },
    -- keys below would otherwise make this lazy; keep it loaded so the
    -- mason installs below run at startup
    lazy = false,
    opts = {
        formatters_by_ft = {
            go = { "gofmt" },
            -- rustfmt ships with rustup/cargo, not mason (there is no
            -- standalone mason package for it); it reads the edition
            -- from Cargo.toml on its own, so no extra flags are needed.
            rust = { "rustfmt" },
            -- ruff's formatter is black-compatible and, unlike black, comes
            -- from mason as a single binary (this machine has no pip)
            python = { "ruff_format" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            lua = { "stylua" },
            json = { "prettier" },
        },
        -- formatting is on demand only (<leader>lf), never on save; the
        -- island's Format button calls vim.lsp.buf.format directly
        format_on_save = false,
        -- anything without a formatter above is formatted by its server
        default_format_opts = { lsp_format = "fallback" },
        -- a missing formatter falls back to the LSP quietly instead of a
        -- warning
        notify_no_formatters = false,
    },
    keys = {
        {
            "<leader>lf",
            function()
                require("conform").format({ async = true })
            end,
            mode = { "n", "v" },
            desc = "Format buffer",
        },
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
