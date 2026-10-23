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
            -- rust-analyzer and codelldb come from mason like every other
            -- tool here; lua/config/tools.lua lists and installs them.
            -- Prefer the mason-installed binary (its bin/ link works the
            -- same in mason 1.x and 2.x), but still work via a rustup
            -- toolchain on PATH if mason has not finished installing it.
            local function rust_analyzer_cmd()
                local bin = vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer"
                if vim.fn.executable(bin) == 1 then
                    return { bin }
                end
                return { "rust-analyzer" }
            end

            local dap_adapter = nil
            if vim.fn.executable("codelldb") == 1 then
                local ext = vim.uv.os_uname().sysname == "Darwin" and ".dylib" or ".so"
                local liblldb = vim.fn.expand("$MASON/opt/lldb/lib/liblldb" .. ext)
                dap_adapter = require("rustaceanvim.config").get_codelldb_adapter(vim.fn.exepath("codelldb"), liblldb)
            end

            vim.g.rustaceanvim = {
                server = {
                    cmd = rust_analyzer_cmd(),
                    capabilities = require("blink.cmp").get_lsp_capabilities(),
                    on_attach = function(_, bufnr)
                        -- inlay hints stay off (they crowd the line); <leader>ih
                        -- turns them on when wanted
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
                            -- <leader>rr is the generic file runner
                            -- (lua/config/runner.lua: cargo run here)
                            map("<leader>rR", function()
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
                            check = { command = "check" },
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
