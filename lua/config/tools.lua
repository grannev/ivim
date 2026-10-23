-- Everything this config fetches through mason, in one list: language
-- servers, formatters, the debugger and the tree-sitter CLI. The mason
-- spec (lua/plugins/lsp.lua) installs whatever is missing at startup,
-- treesitter.lua waits here for the CLI, and :NvimConfigHealth checks the
-- same list. Add a package here and nowhere else.
local M = {}

M.groups = {
    {
        name = "language servers",
        -- mason-lspconfig starts each of these (lua/plugins/lsp.lua)
        packages = {
            "lua-language-server",
            "pyright",
            "bash-language-server",
            "html-lsp",
            "css-lsp",
            "json-lsp",
            "yaml-language-server",
            "typescript-language-server",
            "dockerfile-language-server",
            "texlab",
            "gopls",
            "clangd",
            -- started by rustaceanvim, not mason-lspconfig (rust.lua)
            "rust-analyzer",
        },
    },
    {
        name = "formatters",
        -- conform (lua/plugins/formatting.lua); gofmt and rustfmt come with
        -- their toolchains
        packages = { "ruff", "stylua", "prettier" },
    },
    {
        name = "debugger",
        -- nvim-dap through rustaceanvim (rust.lua)
        packages = { "codelldb" },
    },
    {
        name = "tree-sitter CLI",
        -- compiles the parsers (lua/plugins/treesitter.lua)
        packages = { "tree-sitter-cli" },
    },
}

function M.packages()
    local names = {}
    for _, group in ipairs(M.groups) do
        vim.list_extend(names, group.packages)
    end
    return names
end

-- package name -> callbacks waiting for its install to finish
local waiting = {}

--- Call `on_ready` once `name` is installed: right away if it already is,
--- otherwise when ensure_all() finishes installing it.
function M.when_installed(name, on_ready)
    local ok, registry = pcall(require, "mason-registry")
    if ok and registry.is_installed(name) then
        on_ready()
        return
    end
    waiting[name] = waiting[name] or {}
    table.insert(waiting[name], on_ready)
end

--- Install every package that is missing. Skipped without a UI: headless
--- runs (tests, scripts) should not start downloads.
function M.ensure_all()
    if #vim.api.nvim_list_uis() == 0 then
        return
    end
    local registry = require("mason-registry")
    registry.refresh(function()
        for _, name in ipairs(M.packages()) do
            local found, package = pcall(registry.get_package, name)
            if found and not package:is_installed() then
                package:install():once("closed", vim.schedule_wrap(function()
                    if package:is_installed() then
                        for _, on_ready in ipairs(waiting[name] or {}) do
                            on_ready()
                        end
                    end
                    waiting[name] = nil
                end))
            end
        end
    end)
end

return M
