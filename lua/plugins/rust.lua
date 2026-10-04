-- Rust support: rustaceanvim drives rust-analyzer and owns everything that
-- needs more than plain LSP (runnables, testables, debugging, macro
-- expansion), crates.nvim handles Cargo.toml. Debugging itself (the UI,
-- generic keymaps) lives in lua/plugins/dap.lua; this file only points
-- rustaceanvim's DAP integration at a mason-installed codelldb.
return {
    {
        -- rustaceanvim is its own filetype plugin, not an nvim-lspconfig
        -- server: it starts and owns the rust-analyzer client itself. Do
        -- not add "rust_analyzer" to the server list in lua/plugins/lsp.lua
        -- as well, or two clients will race to attach to the same buffer.
        "mrcjkb/rustaceanvim",
        -- the plugin manages its own (filetype-based) lazy loading; the
        -- maintainer recommends lazy = false, and pinning the major
        -- version avoids silently picking up breaking changes
        version = "^9",
        lazy = false,
        dependencies = { "williamboman/mason.nvim", "saghen/blink.cmp" },
        config = function()
            -- rust-analyzer and codelldb come from mason, like every other
            -- server and formatter in this config (see lsp.lua and
            -- formatting.lua); install them the same way formatting.lua
            -- installs stylua/prettier/ruff.
            local function mason_pkg(name)
                local ok, registry = pcall(require, "mason-registry")
                if not ok then
                    return nil
                end
                local found, pkg = pcall(registry.get_package, name)
                if not found then
                    return nil
                end
                if not pkg:is_installed() then
                    pkg:install()
                end
                return pkg
            end

            local rust_analyzer = mason_pkg("rust-analyzer")
            local codelldb = mason_pkg("codelldb")

            -- Prefer the mason-installed binary, but still work (e.g. via a
            -- rustup toolchain on PATH) if mason has not finished
            -- installing it yet.
            local function rust_analyzer_cmd()
                if rust_analyzer and rust_analyzer:is_installed() then
                    local filename = rust_analyzer:get_receipt():get().links.bin["rust-analyzer"]
                    return { ("%s/%s"):format(rust_analyzer:get_install_path(), filename or "rust-analyzer") }
                end
                return { "rust-analyzer" }
            end

            local dap_adapter = nil
            if codelldb and codelldb:is_installed() then
                local ext = vim.uv.os_uname().sysname == "Darwin" and ".dylib" or ".so"
                local liblldb = vim.fn.expand("$MASON/opt/lldb/lib/liblldb" .. ext)
                dap_adapter = require("rustaceanvim.config").get_codelldb_adapter(vim.fn.exepath("codelldb"), liblldb)
            end

            vim.g.rustaceanvim = {
                server = {
                    cmd = rust_analyzer_cmd(),
                    capabilities = require("blink.cmp").get_lsp_capabilities(),
                    on_attach = function(_, bufnr)
                        -- inlay hints stay off (they crowd the line); <leader>th
                        -- turns them on for a buffer when wanted
                        -- Deferred a tick so these buffer-local maps win
                        -- over the generic ones lsp.lua's shared LspAttach
                        -- autocmd sets for every server, regardless of
                        -- which of the two happens to run first.
                        vim.schedule(function()
                            local map = function(keys, fn, desc)
                                vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
                            end
                            map("K", function()
                                vim.cmd.RustLsp({ "hover", "actions" })
                            end, "Hover actions")
                            map("<leader>ca", function()
                                vim.cmd.RustLsp("codeAction")
                            end, "Code action (grouped)")
                            map("<leader>rr", function()
                                vim.cmd.RustLsp("runnables")
                            end, "Runnables")
                            map("<leader>rt", function()
                                vim.cmd.RustLsp("testables")
                            end, "Testables")
                            map("<leader>rd", function()
                                vim.cmd.RustLsp("debuggables")
                            end, "Debuggables")
                            map("<leader>rm", function()
                                vim.cmd.RustLsp("expandMacro")
                            end, "Expand macro")
                            map("<leader>ro", function()
                                vim.cmd.RustLsp("openCargo")
                            end, "Open Cargo.toml")
                            map("<leader>re", function()
                                vim.cmd.RustLsp("explainError")
                            end, "Explain error")
                        end)
                    end,
                    default_settings = {
                        ["rust-analyzer"] = {
                            cargo = {
                                allFeatures = true,
                                buildScripts = { enable = true },
                            },
                            check = { command = "clippy" },
                            checkOnSave = true,
                            procMacro = { enable = true },
                            -- type hints stay; parameter-name hints stretch
                            -- every call and read as noise
                            inlayHints = { parameterHints = { enable = false } },
                            files = {
                                watcher = "client",
                                exclude = { ".direnv", ".git", ".github", ".gitlab", "target", "node_modules" },
                            },
                        },
                    },
                },
                dap = dap_adapter and { adapter = dap_adapter } or nil,
            }
        end,
    },
    {
        -- Cargo.toml support: version completion, latest-version virtual
        -- text, and upgrade actions. It registers itself as a tiny LSP
        -- server for Cargo.toml buffers (lsp.enabled below), so blink.cmp's
        -- existing "lsp" source and the standard K / <leader>ca keymaps
        -- pick it up with no extra wiring.
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml" },
        opts = {
            completion = { crates = { enabled = true } },
            lsp = { enabled = true, actions = true, completion = true, hover = true },
        },
    },
}
