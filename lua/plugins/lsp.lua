local hover_opts = {
    focusable = false,
    max_height = 10,
    close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufHidden", "BufLeave", "WinScrolled" },
}

local function hover()
    vim.lsp.buf.hover(vim.tbl_extend("force", hover_opts, { max_width = math.floor(vim.o.columns * 0.7) }))
end

-- The diagnostic under the cursor opens in a float after half a second;
-- with popup hints on (<leader>uh), the hover follows after three seconds
-- wherever there is no diagnostic to show instead.
local function setup_popups_on_hold()
    local group = vim.api.nvim_create_augroup("LspHoverOnHold", { clear = true })
    local diagnostic_timer, hover_timer

    local function stop_timer(timer)
        if timer and not timer:is_closing() then
            timer:stop()
            timer:close()
        end
        return nil
    end

    local function diagnostic_under_cursor()
        local cursor = vim.api.nvim_win_get_cursor(0)
        for _, diagnostic in ipairs(vim.diagnostic.get(0, { lnum = cursor[1] - 1 })) do
            local start_col = diagnostic.col or 0
            local end_col = diagnostic.end_col or start_col + 1
            if cursor[2] >= start_col and cursor[2] <= end_col then
                return true
            end
        end
        return false
    end

    local function has_lsp()
        return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0 }))
    end

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
        group = group,
        callback = function()
            diagnostic_timer = stop_timer(diagnostic_timer)
            hover_timer = stop_timer(hover_timer)

            diagnostic_timer = vim.uv.new_timer()
            diagnostic_timer:start(500, 0, vim.schedule_wrap(function()
                if has_lsp() and diagnostic_under_cursor() then
                    vim.diagnostic.open_float({ focus = false, scope = "cursor" })
                end
            end))

            hover_timer = vim.uv.new_timer()
            hover_timer:start(3000, 0, vim.schedule_wrap(function()
                if not (has_lsp() and vim.g.popup_hints_enabled) or diagnostic_under_cursor() then
                    return
                end
                if vim.api.nvim_win_get_config(0).relative ~= "" then
                    return
                end
                hover()
            end))
        end,
    })
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
        group = group,
        callback = function()
            diagnostic_timer = stop_timer(diagnostic_timer)
            hover_timer = stop_timer(hover_timer)
        end,
    })
end

-- the first location a request returns, opened in a new tab page
local function jump_location_in_tab(method)
    local params = vim.lsp.util.make_position_params(0, "utf-8")
    local results = vim.lsp.buf_request_sync(0, method, params, 1000)
    if not results then
        return false
    end
    local location
    for _, result in pairs(results) do
        if result.result then
            location = vim.islist(result.result) and result.result[1] or result.result
            break
        end
    end
    if not location then
        return false
    end
    local uri = location.uri or location.targetUri
    local range = location.range or location.targetSelectionRange
    if not uri or not range then
        return false
    end
    vim.cmd("tabnew " .. vim.fn.fnameescape(vim.uri_to_fname(uri)))
    vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
    vim.cmd("normal! zz")
    return true
end

local function implementation_in_tab()
    if jump_location_in_tab("textDocument/implementation") or jump_location_in_tab("textDocument/definition") then
        return
    end
    vim.notify("Implementation not found", vim.log.levels.WARN)
end

return {
    {
        "williamboman/mason.nvim",
        opts = {
            max_concurrent_installers = 1,
            ui = { border = "rounded", width = 0.85, height = 0.75 },
        },
        config = function(_, opts)
            require("mason").setup(opts)
            -- once the UI is up, fetch whatever lua/config/tools.lua lists
            -- and is not there yet
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                once = true,
                callback = function()
                    require("config.tools").ensure_all()
                end,
            })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            -- installing is lua/config/tools.lua's job; this only starts
            -- the servers. Every installed server starts on its own, except
            -- rust-analyzer: rustaceanvim (lua/plugins/rust.lua) owns that
            -- client, and a second one would race it for the buffer. stylua
            -- and ruff are in mason as conform's formatters
            -- (lua/plugins/formatting.lua), not as language servers.
            automatic_enable = { exclude = { "rust_analyzer", "stylua", "ruff" } },
        },
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp" },
        config = function()
            -- blink.cmp advertises its capabilities on its own, but only
            -- once it loads; servers may start before the first InsertEnter
            vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            })
            vim.lsp.config("pyright", {
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "basic",
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                            diagnosticMode = "workspace",
                        },
                    },
                },
            })
            vim.lsp.config("gopls", {
                settings = {
                    gopls = {
                        analyses = { unusedparams = true, shadow = true },
                        staticcheck = true,
                        gofumpt = false,
                    },
                },
            })
            vim.lsp.config("texlab", {
                settings = {
                    texlab = {
                        build = {
                            executable = "latexmk",
                            args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                            onSave = false,
                            forwardSearchAfter = false,
                        },
                        forwardSearch = { executable = "evince", args = { "%p" } },
                    },
                },
            })
            vim.lsp.config("jsonls", { settings = { json = { validate = { enable = true } } } })
            vim.lsp.config("html", {
                filetypes = { "html" },
                settings = {
                    html = {
                        format = { enable = false },
                        hover = { documentation = true, references = true },
                    },
                },
            })
            vim.lsp.config("cssls", {
                settings = {
                    css = { validate = true },
                    scss = { validate = true },
                    less = { validate = true },
                },
            })

            -- clangd covers both C and C++, but the two want a different
            -- fallback language standard, and one clangd process cannot
            -- switch initializationOptions per buffer. Split it into two
            -- clients that both spawn clangd, one per language, so each
            -- gets its own fallback flags.
            vim.lsp.config("clangd", {}) -- load the lsp/clangd.lua preset
            local clangd_base = vim.tbl_deep_extend("force", vim.deepcopy(vim.lsp.config["clangd"]), {
                cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
            })
            vim.lsp.config("clangd", vim.tbl_deep_extend("force", clangd_base, {
                filetypes = { "c", "c.doxygen", "objc", "cuda" },
            }))
            vim.lsp.config("clangd_cpp", vim.tbl_deep_extend("force", clangd_base, {
                filetypes = { "cpp", "cpp.doxygen", "objcpp" },
                -- only used as a fallback where a project's own
                -- compile_commands.json does not already say otherwise
                init_options = { fallbackFlags = { "-std=c++11" } },
            }))
            -- clangd_cpp is no mason server, so automatic_enable never
            -- sees it; clangd itself is enabled here too in case it comes
            -- from the system rather than mason
            vim.lsp.enable({ "clangd", "clangd_cpp" })

            setup_popups_on_hold()

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
                    end
                    map("gd", vim.lsp.buf.definition, "Go to definition")
                    map("gD", vim.lsp.buf.declaration, "Go to declaration")
                    map("gi", vim.lsp.buf.implementation, "Go to implementation")
                    map("gr", vim.lsp.buf.references, "Go to references")
                    map("K", hover, "Hover documentation")
                    map("<leader>gt", implementation_in_tab, "Go to implementation in new tab")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    map("[d", function()
                        vim.diagnostic.jump({ count = -1, float = true })
                    end, "Previous diagnostic")
                    map("]d", function()
                        vim.diagnostic.jump({ count = 1, float = true })
                    end, "Next diagnostic")
                    map("<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
                end,
            })
        end,
    },
}
