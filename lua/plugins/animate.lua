-- Motion, split between two plugins so nothing is animated twice:
-- neoscroll owns scrolling (Ctrl-d/u/f/b/e/y, zz/zt/zb, the mouse wheel),
-- mini.animate owns windows resizing, opening and closing — its own scroll
-- animation stays off. The cursor itself is not animated anywhere: a
-- cursor that trails behind each keypress reads as lag. The durations are
-- short for the same reason: the motion should be over before the next key.

-- Neovide glides the scroll itself (lua/config/neovide.lua); neither
-- plugin loads there, and Ctrl-d/u and n/N only keep the centring.
if vim.g.neovide then
    vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half a page" })
    vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half a page" })
    vim.keymap.set("n", "n", "nzzzv", { desc = "Next match, centred" })
    vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous match, centred" })
    return {}
end

-- neoscroll silences CursorMoved while it scrolls, one line at a time.
-- Once it stops, everything listening — the island's cursor position, the
-- LSP highlight and popup timers — hears about the cursor's final place.
-- mini.animate sits that one event out, should its cursor animation ever
-- be turned back on.
local function cursor_arrived()
    local disabled = vim.g.minianimate_disable
    vim.g.minianimate_disable = true
    pcall(vim.api.nvim_exec_autocmds, "CursorMoved", {})
    vim.g.minianimate_disable = disabled
end

local function scroll_keys()
    local neoscroll = require("neoscroll")
    local modes = { "n", "v", "x" }
    local function map(keys, fn, desc)
        vim.keymap.set(modes, keys, fn, { desc = desc })
    end

    -- half a page, then the cursor line glides to the middle of the window
    -- (post_hook below), like <C-d>zz did before
    map("<C-d>", function()
        neoscroll.ctrl_d({ duration = 150, info = "center" })
    end, "Scroll down half a page")
    map("<C-u>", function()
        neoscroll.ctrl_u({ duration = 150, info = "center" })
    end, "Scroll up half a page")
    map("<C-f>", function()
        neoscroll.ctrl_f({ duration = 250 })
    end, "Scroll down a page")
    map("<C-b>", function()
        neoscroll.ctrl_b({ duration = 250 })
    end, "Scroll up a page")
    map("<C-e>", function()
        neoscroll.scroll(0.1, { move_cursor = false, duration = 60 })
    end, "Scroll down a little")
    map("<C-y>", function()
        neoscroll.scroll(-0.1, { move_cursor = false, duration = 60 })
    end, "Scroll up a little")
    map("zz", function()
        neoscroll.zz({ half_win_duration = 120 })
    end, "Center the cursor line")
    map("zt", function()
        neoscroll.zt({ half_win_duration = 120 })
    end, "Cursor line to the top")
    map("zb", function()
        neoscroll.zb({ half_win_duration = 120 })
    end, "Cursor line to the bottom")

    -- the wheel scrolls the window under the pointer, three lines a notch
    for keys, lines in pairs({ ["<ScrollWheelDown>"] = 3, ["<ScrollWheelUp>"] = -3 }) do
        map(keys, function()
            local win = vim.fn.getmousepos().winid
            if win == 0 then
                return
            end
            neoscroll.scroll(lines, { move_cursor = false, duration = 50, winid = win })
        end, "Scroll with the mouse")
    end

    -- n/N jump to the match, open folds around it and glide it to the
    -- middle of the window
    for _, key in ipairs({ "n", "N" }) do
        vim.keymap.set("n", key, function()
            local ok, err = pcall(vim.cmd, "normal! " .. vim.v.count1 .. key)
            if not ok then
                vim.api.nvim_echo({ { (err:gsub("^Vim%(normal%):", "")), "ErrorMsg" } }, false, {})
                return
            end
            vim.cmd("normal! zv")
            neoscroll.zz({ half_win_duration = 120 })
        end, { desc = key == "n" and "Next match, centred" or "Previous match, centred" })
    end
end

return {
    {
        "karb94/neoscroll.nvim",
        event = "VeryLazy",
        config = function()
            require("neoscroll").setup({
                -- every key is mapped by hand in scroll_keys()
                mappings = {},
                hide_cursor = true,
                stop_eof = true,
                respect_scrolloff = false,
                cursor_scrolls_alone = true,
                -- fast at first, slowing down as it arrives
                easing = "quadratic",
                -- only CursorMoved (see cursor_arrived); WinScrolled keeps
                -- firing so the indent guides follow the scroll
                ignored_events = { "CursorMoved" },
                -- neoscroll calls this before it lifts eventignore and
                -- marks the scroll as finished: anything done right here
                -- would be ignored, or taken as part of the same scroll
                post_hook = function(info)
                    vim.schedule(function()
                        cursor_arrived()
                        if info == "center" then
                            require("neoscroll").zz({ half_win_duration = 80 })
                        end
                    end)
                end,
            })
            scroll_keys()
        end,
    },
    {
        "nvim-mini/mini.animate",
        version = false,
        event = "VeryLazy",
        config = function()
            local animate = require("mini.animate")
            animate.setup({
                cursor = { enable = false },
                scroll = { enable = false },
                resize = {
                    timing = animate.gen_timing.quadratic({ easing = "out", duration = 80, unit = "total" }),
                },
                open = {
                    timing = animate.gen_timing.quadratic({ easing = "out", duration = 90, unit = "total" }),
                },
                close = {
                    timing = animate.gen_timing.quadratic({ easing = "out", duration = 90, unit = "total" }),
                },
            })
        end,
    },
}
