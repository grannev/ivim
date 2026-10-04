return {
    {
        "williamboman/mason.nvim",
        opts = {},
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            -- Servers are enabled explicitly below so their capabilities are
            -- configured through Neovim's native LSP API first.
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

            local servers = {
                "gopls",
                "pyright",
                "ts_ls",
                "lua_ls",
                "bashls",
                "jsonls",
                "yamlls",
                "dockerls",
            }
            for _, server in ipairs(servers) do
                vim.lsp.config(server, { capabilities = capabilities })
            end

            -- clangd covers both C and C++, but the two want a different
            -- fallback language standard, and one clangd process cannot
            -- switch initializationOptions per buffer. Split it into two
            -- clients that both spawn clangd, one per language, so each
            -- gets its own fallback flags.
            vim.lsp.config("clangd", {}) -- load the lsp/clangd.lua preset
            local clangd_base = vim.deepcopy(vim.lsp.config["clangd"])
            vim.lsp.config("clangd", vim.tbl_deep_extend("force", clangd_base, {
                capabilities = capabilities,
                filetypes = { "c", "c.doxygen", "objc", "cuda" },
            }))
            vim.lsp.config("clangd_cpp", vim.tbl_deep_extend("force", clangd_base, {
                capabilities = capabilities,
                filetypes = { "cpp", "cpp.doxygen", "objcpp" },
                -- only used as a fallback where a project's own
                -- compile_commands.json does not already say otherwise
                init_options = { fallbackFlags = { "-std=c++11" } },
            }))
            table.insert(servers, "clangd")
            table.insert(servers, "clangd_cpp")

            vim.lsp.enable(servers)

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
