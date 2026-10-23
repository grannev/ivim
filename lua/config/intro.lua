-- The start screen: iVim in block letters, a search line for files and
-- folders anywhere on the system, and the handful of keys worth knowing in
-- an empty editor. It replaces Neovim's own intro (shortmess I) and goes
-- away like it as soon as there is something else to look at — typing in
-- the buffer, another buffer, another window.
--
-- The cursor starts in the search line. Typing hands the query over to
-- the system search (lua/config/system_search.lua), and closing that
-- without opening anything brings the start screen back. Esc leaves the
-- line for the editor, where the hints apply; / goes back to it. Colours
-- live in lua/plugins/colorscheme.lua (IvimIntro*).
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
    { "Space ff", "find a file in the project" },
    { "Space fg", "search the project" },
    { "Space e", "file explorer" },
    { "Space sl", "restore the session" },
    { "Ctrl-\\", "terminal" },
    { "Space", "every other key" },
    { ":q", "quit" },
}

local placeholder = "Search files and folders on the system"
local caption = "Esc  the editor     /  back to the search"
local search_icon = ""
local key_width = 12
local width = 46
local ns = vim.api.nvim_create_namespace("ivim.intro")
local group = vim.api.nvim_create_augroup("ivim.intro", { clear = true })
-- the open start screen: its float, the search line's float while the
-- cursor is in it, the window and buffer underneath and that window's
-- options as they were
local state = nil

local function is_empty(buf)
    return vim.api.nvim_buf_get_name(buf) == ""
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

-- the lines, their highlights and the row of the search line
local function build()
    local version = vim.version()
    local subtitle = ("Neovim %d.%d.%d"):format(version.major, version.minor, version.patch)

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

    -- the letters' faces take the row's shade of the blue-to-cyan
    -- gradient, their box-drawing shadows stay dim
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

    -- the search line: a rounded box; while the cursor is in it, a float
    -- covers its inside (open_search)
    local rule = string.rep("─", width - 2)
    local top, bottom = "╭" .. rule .. "╮", "╰" .. rule .. "╯"
    add(top, 0, { { 0, #top, "IvimIntroSearchBorder" } })
    local inner = width - 6
    local text = placeholder .. string.rep(" ", inner - vim.fn.strdisplaywidth(placeholder))
    local middle = "│ " .. search_icon .. " " .. text .. " │"
    local icon_start = #"│ "
    local text_start = icon_start + #search_icon + 1
    add(middle, 0, {
        { 0, #"│", "IvimIntroSearchBorder" },
        { icon_start, icon_start + #search_icon, "IvimIntroSearchIcon" },
        { text_start, text_start + #text, "IvimIntroSearchPlaceholder" },
        { #middle - #"│", #middle, "IvimIntroSearchBorder" },
    })
    local search_row = #lines - 1
    add(bottom, 0, { { 0, #bottom, "IvimIntroSearchBorder" } })
    add(caption, centered(caption), { { 0, #caption, "IvimIntroMuted" } })
    add("", 0)

    local hint_width = 0
    for _, hint in ipairs(hints) do
        hint_width = math.max(hint_width, key_width + #hint[2])
    end
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
    return lines, marks, search_row
end

local function placement(height)
    return {
        relative = "editor",
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        width = width,
        height = height,
    }
end

-- the inside of the search box, right of the icon
local function search_placement()
    local intro = placement(state.height)
    return {
        relative = "editor",
        row = intro.row + state.search_row,
        col = intro.col + 4,
        width = width - 6,
        height = 1,
    }
end

local function fits(height)
    return vim.o.columns >= width + 4 and vim.o.lines >= height + 2
end

-- the covered window's own chrome (line number, current line, the 80th
-- column) would show through around the float
local chrome = { number = false, relativenumber = false, cursorline = false, colorcolumn = "", signcolumn = "no" }

local function close_search()
    if state and state.search_win and vim.api.nvim_win_is_valid(state.search_win) then
        vim.api.nvim_win_close(state.search_win, true)
    end
    if state then
        state.search_win = nil
    end
end

function M.close()
    if not state then
        return
    end
    vim.api.nvim_clear_autocmds({ group = group })
    close_search()
    if vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    if vim.api.nvim_win_is_valid(state.base_win) then
        for option, value in pairs(state.saved) do
            vim.wo[state.base_win][option] = value
        end
    end
    if vim.api.nvim_buf_is_valid(state.base_buf) then
        pcall(vim.keymap.del, "n", "/", { buffer = state.base_buf })
    end
    state = nil
end

-- the query goes to the system search; closing that without opening
-- anything brings the start screen back
local function search(query)
    vim.cmd("stopinsert")
    vim.schedule(function()
        if not state then
            return
        end
        local base_buf = state.base_buf
        -- the picker returns to the window it was opened from: the empty
        -- buffer's, not the search line's
        if vim.api.nvim_win_is_valid(state.base_win) then
            vim.api.nvim_set_current_win(state.base_win)
        end
        M.close()
        require("config.system_search").open({
            default_text = query,
            on_cancel = function()
                local buf = vim.api.nvim_get_current_buf()
                if buf == base_buf and is_empty(buf) then
                    M.open()
                end
            end,
        })
    end)
end

-- Esc in the search line: back to the empty buffer, the start screen stays
local function leave_search()
    vim.cmd("stopinsert")
    vim.schedule(function()
        if not state then
            return
        end
        close_search()
        if vim.api.nvim_win_is_valid(state.base_win) then
            vim.api.nvim_set_current_win(state.base_win)
        end
    end)
end

local function open_search()
    if not state or (state.search_win and vim.api.nvim_win_is_valid(state.search_win)) then
        return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    -- no completion menu in a search line
    vim.b[buf].completion = false

    local function show_placeholder()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        if vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
            vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
                virt_text = { { placeholder, "IvimIntroSearchPlaceholder" } },
                virt_text_pos = "overlay",
            })
        end
    end
    show_placeholder()

    local config = search_placement()
    config.style = "minimal"
    config.border = "none"
    config.zindex = 2
    -- entering it must not count as leaving the empty buffer (BufLeave,
    -- WinEnter below)
    config.noautocmd = true
    state.search_win = vim.api.nvim_open_win(buf, true, config)
    vim.wo[state.search_win].winhighlight = "NormalFloat:Normal"
    vim.wo[state.search_win].winblend = 0

    local opts = { buffer = buf, nowait = true }
    vim.keymap.set({ "i", "n" }, "<Esc>", leave_search, opts)
    vim.keymap.set({ "i", "n" }, "<C-c>", leave_search, opts)
    vim.keymap.set({ "i", "n" }, "<CR>", function()
        search(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
    end, opts)
    vim.api.nvim_create_autocmd("TextChangedI", {
        group = group,
        buffer = buf,
        callback = function()
            local query = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
            if query:match("%S") then
                search(query)
            else
                show_placeholder()
            end
        end,
    })
    vim.cmd("startinsert")
end

function M.open()
    M.close()
    local lines, marks, search_row = build()
    if not fits(#lines) then
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for _, mark in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, ns, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4] })
    end
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    local config = placement(#lines)
    config.style = "minimal"
    config.border = "none"
    config.focusable = false
    config.zindex = 1
    config.noautocmd = true
    local win = vim.api.nvim_open_win(buf, false, config)
    vim.wo[win].winblend = 0
    vim.wo[win].winhighlight = "NormalFloat:Normal"

    local base_win = vim.api.nvim_get_current_win()
    local base_buf = vim.api.nvim_get_current_buf()
    local saved = {}
    for option, value in pairs(chrome) do
        saved[option] = vim.wo[base_win][option]
        vim.wo[base_win][option] = value
    end
    state = {
        win = win,
        base_win = base_win,
        base_buf = base_buf,
        saved = saved,
        height = #lines,
        search_row = search_row,
    }

    -- typing in the empty buffer, or leaving it, ends the start screen
    vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "BufLeave" }, {
        group = group,
        buffer = base_buf,
        callback = M.close,
    })
    -- so does any window but the empty one and the search line
    vim.api.nvim_create_autocmd("WinEnter", {
        group = group,
        callback = function()
            local current = vim.api.nvim_get_current_win()
            if state and current ~= state.base_win and current ~= state.search_win then
                M.close()
            end
        end,
    })
    vim.api.nvim_create_autocmd("TabLeave", { group = group, callback = M.close })
    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = function()
            if not fits(state.height) then
                M.close()
                return
            end
            vim.api.nvim_win_set_config(state.win, placement(state.height))
            if state.search_win and vim.api.nvim_win_is_valid(state.search_win) then
                vim.api.nvim_win_set_config(state.search_win, search_placement())
            end
        end,
    })
    vim.keymap.set("n", "/", open_search, { buffer = base_buf, desc = "Search files and folders on the system" })

    open_search()
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
        if is_empty(vim.api.nvim_get_current_buf()) then
            M.open()
        end
    end,
})

return M
