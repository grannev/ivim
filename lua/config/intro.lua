-- The start screen: iVim in block letters and the handful of keys worth
-- knowing in an empty editor. It replaces Neovim's own intro (shortmess I)
-- and behaves like it: a float drawn over the empty buffer, gone as soon
-- as there is something else to look at — typing, another buffer, another
-- window. Colours live in lua/plugins/colorscheme.lua (IvimIntro*).
local M = {}

vim.opt.shortmess:append("I")

local logo = {
    "██╗ ██╗   ██╗ ██╗ ███╗   ███╗",
    "╚═╝ ██║   ██║ ╚═╝ ████╗ ████║",
    "██╗ ██║   ██║ ██╗ ██╔████╔██║",
    "██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
    "██║  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
    "╚═╝   ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
}

local hints = {
    { "Space ff", "find a file" },
    { "Space fg", "search the project" },
    { "Space e", "file explorer" },
    { "Space sl", "restore the session" },
    { "Ctrl-\\", "terminal" },
    { "Space", "every other key" },
    { ":q", "quit" },
}

local key_width = 12
local ns = vim.api.nvim_create_namespace("ivim.intro")
local group = vim.api.nvim_create_augroup("ivim.intro", { clear = true })
-- the open intro: its float, the window it covers and that window's
-- options as they were
local state = nil

local function build()
    local version = vim.version()
    local subtitle = ("Neovim %d.%d.%d"):format(version.major, version.minor, version.patch)

    local hint_width = 0
    for _, hint in ipairs(hints) do
        hint_width = math.max(hint_width, key_width + #hint[2])
    end
    local width = math.max(vim.fn.strdisplaywidth(logo[1]), hint_width)

    local lines, marks = {}, {}
    local function add(text, pad, ranges)
        table.insert(lines, string.rep(" ", pad) .. text)
        for _, range in ipairs(ranges or {}) do
            table.insert(marks, { #lines - 1, pad + range[1], pad + range[2], range[3] })
        end
    end
    local function centered(text)
        return math.floor((width - vim.fn.strdisplaywidth(text)) / 2)
    end

    -- the letters' faces take the row's shade of the blue-to-purple
    -- gradient, their box-drawing shadows stay grey
    for row, text in ipairs(logo) do
        local ranges, col = {}, 0
        for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            local hl = char == "█" and ("IvimIntroLogo" .. row) or (char ~= " " and "IvimIntroShadow" or nil)
            local last = ranges[#ranges]
            if hl and last and last[3] == hl and last[2] == col then
                last[2] = col + #char
            elseif hl then
                table.insert(ranges, { col, col + #char, hl })
            end
            col = col + #char
        end
        add(text, centered(text), ranges)
    end
    add("", 0)
    add(subtitle, centered(subtitle), { { 0, #subtitle, "IvimIntroMuted" } })
    add("", 0)
    add("", 0)

    local pad = math.floor((width - hint_width) / 2)
    for i, hint in ipairs(hints) do
        local key = hint[1] .. string.rep(" ", key_width - #hint[1])
        add(key .. hint[2], pad, {
            { 0, #hint[1], "IvimIntroKey" },
            { key_width, key_width + #hint[2], "IvimIntroDesc" },
        })
        if i < #hints then
            add("", 0)
        end
    end
    return lines, marks, width
end

local function placement(width, height)
    return {
        relative = "editor",
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        width = width,
        height = height,
    }
end

local function fits(width, height)
    return vim.o.columns >= width + 4 and vim.o.lines >= height + 2
end

-- the covered window's own chrome (line number, current line, the 80th
-- column) would show through around the float
local chrome = { number = false, relativenumber = false, cursorline = false, colorcolumn = "", signcolumn = "no" }

function M.close()
    if not state then
        return
    end
    vim.api.nvim_clear_autocmds({ group = group })
    if vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    if vim.api.nvim_win_is_valid(state.base_win) then
        for option, value in pairs(state.saved) do
            vim.wo[state.base_win][option] = value
        end
    end
    state = nil
end

function M.open()
    M.close()
    local lines, marks, width = build()
    if not fits(width, #lines) then
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for _, mark in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, ns, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4] })
    end
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    local config = placement(width, #lines)
    config.style = "minimal"
    config.border = "none"
    config.focusable = false
    config.zindex = 1
    config.noautocmd = true
    local win = vim.api.nvim_open_win(buf, false, config)
    vim.wo[win].winblend = 0
    vim.wo[win].winhighlight = "NormalFloat:Normal"

    local base_win = vim.api.nvim_get_current_win()
    local saved = {}
    for option, value in pairs(chrome) do
        saved[option] = vim.wo[base_win][option]
        vim.wo[base_win][option] = value
    end
    state = { win = win, base_win = base_win, saved = saved }

    vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "BufLeave", "WinLeave", "TabLeave" }, {
        group = group,
        callback = M.close,
    })
    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = function()
            if not fits(width, #lines) then
                M.close()
                return
            end
            vim.api.nvim_win_set_config(state.win, placement(width, #lines))
        end,
    })
end

-- only where Neovim would show its intro: started without files, without
-- stdin, on a screen, in an empty unnamed buffer
local from_stdin = false
vim.api.nvim_create_autocmd("StdinReadPre", {
    callback = function()
        from_stdin = true
    end,
})
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.argc() > 0 or from_stdin or #vim.api.nvim_list_uis() == 0 then
            return
        end
        local buf = vim.api.nvim_get_current_buf()
        local empty = vim.api.nvim_buf_get_name(buf) == ""
            and vim.bo[buf].buftype == ""
            and not vim.bo[buf].modified
            and vim.api.nvim_buf_line_count(buf) == 1
            and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
        if empty then
            M.open()
        end
    end,
})

return M
