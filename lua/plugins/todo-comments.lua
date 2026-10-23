-- The comment leader in front of a keyword (/*, //, --, #) takes the
-- keyword's colour too, so the whole comment is lit, not only what follows
-- the keyword. It reads where todo-comments put its keyword highlights and
-- adds the leader on each redraw.
local function light_leaders()
    local todo_ns = require("todo-comments.config").ns
    local ns = vim.api.nvim_create_namespace("ivim.todo_leader")
    local ranges = {}
    vim.api.nvim_set_decoration_provider(ns, {
        on_win = function(_, _, buf, toprow, botrow)
            ranges = {}
            local marks = vim.api.nvim_buf_get_extmarks(buf, todo_ns, { toprow, 0 }, { botrow, -1 }, { details = true })
            for _, mark in ipairs(marks) do
                local kw = (mark[4].hl_group or ""):match("^TodoBg(.+)$")
                if kw then
                    local row, col = mark[2], mark[3]
                    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
                    -- the run of punctuation right before the keyword
                    local leader = line:sub(1, col):match("()[^%s%w_]+%s*$")
                    if leader then
                        ranges[row] = { leader - 1, col, "TodoFg" .. kw }
                    end
                end
            end
        end,
        on_line = function(_, _, buf, row)
            local range = ranges[row]
            if range then
                vim.api.nvim_buf_set_extmark(buf, ns, row, range[1], {
                    end_col = range[2],
                    hl_group = range[3],
                    priority = 500,
                    ephemeral = true,
                })
            end
        end,
    })
end

return {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
        { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
        { "<leader>xt", "<cmd>TodoTrouble<CR>", desc = "Todo comments in Trouble" },
        { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Find todo comments" },
    },
    opts = {
        signs = true,
        sign_priority = 8,
        -- a letter in the gutter, like the diagnostics signs. The plugin's
        -- own keywords merge with these, so FIX, PERF and TEST are spelled
        -- out to replace their Nerd Font icons (FIX also owns FIXME)
        keywords = {
            TODO = { icon = "T", color = "info" },
            FIX = { icon = "F", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
            HACK = { icon = "H", color = "warning" },
            WARN = { icon = "W", color = "warning", alt = { "WARNING", "XXX" } },
            NOTE = { icon = "N", color = "hint", alt = { "INFO" } },
            PERF = { icon = "P", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
            TEST = { icon = "T", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
        },
        -- the colours are groups in lua/plugins/colorscheme.lua, brighter than the rest
        -- of the palette so a keyword stands out of a muted comment
        colors = {
            error = { "TodoColorError" },
            warning = { "TodoColorWarn" },
            info = { "TodoColorInfo" },
            hint = { "TodoColorHint" },
            default = { "TodoColorDefault" },
            test = { "TodoColorDefault" },
        },
        highlight = {
            multiline = false,
            -- "before" would colour from the start of the line, code in
            -- front of a trailing comment included; light_leaders() below
            -- colours just the comment leader instead
            before = "",
            keyword = "wide",
            after = "fg",
            pattern = [[.*<(KEYWORDS)\s*:]],
            comments_only = true,
            max_line_len = 200,
        },
        search = {
            command = "rg",
            args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
            pattern = [[\b(KEYWORDS):]],
        },
    },
    config = function(_, opts)
        require("todo-comments").setup(opts)
        light_leaders()
    end,
}
