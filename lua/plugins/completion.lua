-- blink.cmp preselects item 1 the moment the menu opens (so Enter alone
-- still accepts it), but that preselect is not an explicit choice: plain
-- "select_next"/"select_prev" would step past it to item 2 on the very
-- first press. This applies the still-preselected item in place instead,
-- and only steps once a selection has actually been made by hand.
-- select_next/select_prev themselves apply on the next tick (vim.schedule)
-- rather than inside the keymap callback: blink.cmp's dot-repeat trick
-- opens a scratch window, which Neovim refuses ("E565") from inside a
-- mapping. Do the same here, and read the still-live state once deferred
-- rather than trusting what was true when the key was pressed.
local function select(direction)
    return function()
        local list = require("blink.cmp.completion.list")
        if not list.can_select() then
            return false
        end
        vim.schedule(function()
            if list.selected_item_idx ~= nil and not list.is_explicitly_selected then
                list.select(list.selected_item_idx, { auto_insert = true })
            elseif direction == "next" then
                list.select_next()
            else
                list.select_prev()
            end
        end)
        return true
    end
end

return {
    "saghen/blink.cmp",
    dependencies = "rafamadriz/friendly-snippets",
    version = "*",
    opts = {
        keymap = {
            preset = "none",
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            -- Tab inserts the first item as a preview; a second Tab previews
            -- the next one, and so on. Enter always accepts whatever is
            -- currently previewed.
            ["<Tab>"] = { select("next"), "snippet_forward", "fallback" },
            ["<S-Tab>"] = { select("prev"), "snippet_backward", "fallback" },
            ["<CR>"] = { "accept", "fallback_to_mappings" },
            ["<Up>"] = { select("prev"), "fallback" },
            ["<Down>"] = { select("next"), "fallback" },
            -- cancel, not hide: hide alone would leave the last previewed
            -- item sitting in the buffer instead of the text you typed
            ["<C-e>"] = { "cancel", "fallback" },
            -- Esc undoes the preview, closes the menu and still leaves
            -- insert mode, as it would without a menu
            ["<Esc>"] = {
                function(cmp)
                    cmp.cancel()
                end,
                "fallback",
            },
        },
        completion = {
            list = {
                selection = { preselect = true, auto_insert = true },
            },
            -- match and replace the whole word around the cursor, not just
            -- the part before it: accepting a completion mid-word then
            -- replaces the rest of it instead of leaving it stuck on the end
            keyword = { range = "full" },
            menu = {
                auto_show = true,
                auto_show_delay_ms = 80,
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
                auto_show = true,
                auto_show_delay_ms = 400,
                window = { border = "rounded", winblend = 0 },
            },
        },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
            -- the word already sitting under the cursor is not worth
            -- offering again; drop it and keep whatever is genuinely
            -- different (or close the menu if nothing else is left)
            transform_items = function(ctx, items)
                local typed = ctx:get_keyword()
                if typed == "" then
                    return items
                end
                return vim.tbl_filter(function(item)
                    return (item.insertText or item.label) ~= typed
                end, items)
            end,
        },
    },
}
