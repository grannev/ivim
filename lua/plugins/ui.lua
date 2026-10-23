-- The tab line: "N:name+" per tab page, so Alt-N has a number to aim at,
-- and on a narrow screen the tabs around the current one stay visible
-- while the rest collapse into "... N". Colours live in
-- lua/plugins/colorscheme.lua (Tabby*).
local function tabline(line)
    local max_name_length = 11

    local function tab_info(tabid)
        local bufnr = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tabid))
        local name = vim.api.nvim_buf_get_name(bufnr)
        name = name == "" and "No Name" or vim.fn.fnamemodify(name, ":t")
        if #name > max_name_length then
            name = name:sub(1, max_name_length - 2) .. ".."
        end
        local nr = vim.api.nvim_tabpage_get_number(tabid)
        return { nr = nr, text = nr .. ":" .. name .. (vim.bo[bufnr].modified and "+" or "") }
    end

    local function hidden_width(count)
        return count > 0 and #(" ... " .. count .. " ") or 0
    end

    local function total_width(infos, first, last)
        local width = hidden_width(first - 1) + hidden_width(#infos - last)
        for i = first, last do
            width = width + #infos[i].text + 2
        end
        return width
    end

    -- grow the visible range around the current tab, one side at a time,
    -- for as long as it fits
    local function visible_range(infos, current, available)
        local first, last = current, current
        while true do
            local can_left = first > 1 and total_width(infos, first - 1, last) <= available
            local can_right = last < #infos and total_width(infos, first, last + 1) <= available
            if can_left and (not can_right or current - first <= last - current) then
                first = first - 1
            elseif can_right then
                last = last + 1
            else
                break
            end
        end
        return first, last
    end

    local infos, current = {}, 1
    for i, tabid in ipairs(vim.api.nvim_list_tabpages()) do
        infos[i] = tab_info(tabid)
        if tabid == vim.api.nvim_get_current_tabpage() then
            current = i
        end
    end
    local first, last = visible_range(infos, current, math.max(vim.o.columns - 4, 20))

    local result = { hl = "TabbyFill" }
    if first > 1 then
        table.insert(result, { " ... " .. first - 1 .. " ", hl = "TabbyHidden" })
    end
    for i = first, last do
        table.insert(result, {
            "%" .. infos[i].nr .. "T " .. infos[i].text .. " %T",
            hl = i == current and "TabbyCurrent" or "TabbyInactive",
        })
    end
    if last < #infos then
        table.insert(result, { " " .. #infos - last .. " ... ", hl = "TabbyHidden" })
    end
    table.insert(result, line.spacer())
    return result
end

return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "classic",
            delay = 300,
            win = { border = "rounded", wo = { winblend = 0 } },
            icons = { mappings = false },
        },
    },
    {
        "nanozuki/tabby.nvim",
        event = "VimEnter",
        config = function()
            require("tabby").setup({ line = tabline })
        end,
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = { char = "│", tab_char = "│", highlight = { "IblIndent" } },
            scope = {
                enabled = true,
                char = "│",
                highlight = { "IblScope" },
                show_start = false,
                show_end = false,
            },
            exclude = {
                filetypes = { "help", "terminal", "Trouble", "lazy", "mason", "oil", "TelescopePrompt" },
            },
        },
    },
}
