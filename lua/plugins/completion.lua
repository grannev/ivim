-- Completion stays out of the way until asked for: Tab after a word opens
-- the menu, Tab/Shift-Tab then move through it and Enter accepts. With
-- popup hints on (<leader>uh, lua/config/popup_hints.lua) the menu opens
-- by itself as you type. Enter with the menu closed goes to
-- lua/config/smart_enter.lua.
--
-- Inside a call's parentheses in Insert mode the function's signature
-- shows in a float above the line, the argument being typed in bold; it
-- inserts nothing. It follows the cursor and closes outside the call.

-- whether the cursor sits after a "(" that has not been closed yet, on
-- this line or a few above (arguments spread over lines); strings and
-- comments are not told apart, the server has the last word
local function inside_parens()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local first = math.max(1, row - 10)
    local lines = vim.api.nvim_buf_get_lines(0, first - 1, row, false)
    lines[#lines] = lines[#lines]:sub(1, col)
    local depth = 0
    for i = #lines, 1, -1 do
        local line = lines[i]
        for j = #line, 1, -1 do
            local char = line:sub(j, j)
            if char == ")" then
                depth = depth + 1
            elseif char == "(" then
                if depth == 0 then
                    return true
                end
                depth = depth - 1
            end
        end
    end
    return false
end

-- blink.cmp opens the signature on "(" and "," and then keeps it in step
-- with the cursor; this opens it too when the cursor arrives inside a
-- call some other way: entering Insert mode there, the arrow keys, typing
-- after it closed. One request per pause, not per key.
local function follow_calls()
    local timer = assert(vim.uv.new_timer())
    vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI" }, {
        group = vim.api.nvim_create_augroup("ivim.signature", { clear = true }),
        callback = function()
            timer:stop()
            timer:start(
                100,
                0,
                vim.schedule_wrap(function()
                    local cmp = require("blink.cmp")
                    if vim.fn.mode() == "i" and not cmp.is_signature_visible() and inside_parens() then
                        cmp.show_signature()
                    end
                end)
            )
        end,
    })
end

return {
    "saghen/blink.cmp",
    dependencies = "rafamadriz/friendly-snippets",
    version = "1.*",
    event = "InsertEnter",
    config = function(_, opts)
        require("blink.cmp").setup(opts)
        follow_calls()
    end,
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
        signature = {
            enabled = true,
            window = {
                border = "rounded",
                max_height = 8,
                -- the signature alone; K shows the documentation
                show_documentation = false,
                direction_priority = { "n", "s" },
            },
        },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
    },
}
