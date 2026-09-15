return {
    {
        "williamboman/mason.nvim",
        opts = {},
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            -- its default auto-enable calls vim.lsp.enable(), added in
            -- Neovim 0.11 — we're on 0.10.4 (Debian trixie), and nvim-lspconfig
            -- setup() below already does this manually anyway.
            automatic_enable = false,
            ensure_installed = {
                "gopls",
                "pyright",
                "clangd",
                "ts_ls",
                "lua_ls",
                "bashls",
                "jsonls",
                "yamlls",
                "dockerls",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            local lspconfig = require("lspconfig")

            local servers = {
                "gopls",
                "pyright",
                "clangd",
                "ts_ls",
                "lua_ls",
                "bashls",
                "jsonls",
                "yamlls",
                "dockerls",
            }
            for _, server in ipairs(servers) do
                lspconfig[server].setup({ capabilities = capabilities })
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
                    end
                    map("gd", vim.lsp.buf.definition, "Goto definition")
                    map("gr", vim.lsp.buf.references, "Goto references")
                    map("K", vim.lsp.buf.hover, "Hover docs")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                end,
            })
        end,
    },
}
