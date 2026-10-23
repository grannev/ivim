-- Completion stays out of the way until asked for: Tab after a word opens
-- the menu, Tab/Shift-Tab then move through it and Enter accepts. With
-- popup hints on (<leader>uh, lua/config/popup_hints.lua) the menu opens
-- by itself as you type. Enter with the menu closed goes to
-- lua/config/smart_enter.lua.
return {
    "saghen/blink.cmp",
    dependencies = "rafamadriz/friendly-snippets",
    version = "1.*",
    event = "InsertEnter",
    opts = {
        keymap = {
            preset = "default",
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide" },
            ["<CR>"] = {
                function(cmp)
                    if cmp.is_visible() then
                        return cmp.accept()
                    end
                    require("config.smart_enter").enter()
                    return true
                end,
            },
            ["<Tab>"] = {
                function(cmp)
                    if cmp.is_visible() then
                        cmp.select_next()
                        return true
                    end
                    -- at the start of a line or after a space Tab indents
                    local col = vim.api.nvim_win_get_cursor(0)[2]
                    local before = vim.api.nvim_get_current_line():sub(col, col)
                    if col == 0 or before:match("%s") then
                        return false
                    end
                    if not vim.g.popup_hints_enabled then
                        cmp.show()
                        return true
                    end
                    return false
                end,
                "fallback",
            },
            ["<S-Tab>"] = {
                function(cmp)
                    if cmp.is_visible() then
                        cmp.select_prev()
                        return true
                    end
                    return false
                end,
                "fallback",
            },
        },
        completion = {
            menu = {
                auto_show = function()
                    return vim.g.popup_hints_enabled == true
                end,
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
                auto_show = false,
                window = { border = "rounded", winblend = 0 },
            },
        },
        -- lsp_signature.nvim (lua/plugins/signature.lua) shows signatures
        signature = { enabled = false },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
    },
}
