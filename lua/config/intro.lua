-- The start screen: iVim in block letters, a search line for files and
-- folders anywhere on the system, and the handful of keys worth knowing in
-- an empty editor. It replaces Neovim's own intro (shortmess I) and goes
-- away like it as soon as there is something else to look at — typing in
-- the buffer, another buffer, another window.
--
-- The cursor starts in the search line. Typing lists matches right under
-- it, in place of the hints (lua/config/system_search.lua runs the
-- search); Up/Down choose, Enter opens a file, or a folder in Oil. Esc
-- leaves the line for the editor, where the hints apply; / goes back to
-- it. Colours live in lua/plugins/colorscheme.lua (IvimIntro*).
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
local results_help = "↑↓ choose    Enter open    Esc the editor"
-- every character of the search box takes one cell, in any font
local prompt = "›"
local key_width = 12
local width = 64
-- the search line's text starts after "│ › "
local input_col = 4
-- a pause in typing before a search starts, ms
local debounce = 120
local ns = vim.api.nvim_create_namespace("ivim.intro")
local group = vim.api.nvim_create_augroup("ivim.intro", { clear = true })
-- the open start screen: its float, the search line's and the results'
-- floats, the window and buffer underneath and that window's options as
-- they were, and the current search
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
    -- covers its inside from input_col on
    local rule = string.rep("─", width - 2)
    local top, bottom = "╭" .. rule .. "╮", "╰" .. rule .. "╯"
    add(top, 0, { { 0, #top, "IvimIntroSearchBorder" } })
    local inner = width - input_col - 2
    local text = placeholder .. string.rep(" ", inner - vim.fn.strdisplaywidth(placeholder))
    local left = "│ " .. prompt .. " "
    local middle = left .. text .. " │"
    add(middle, 0, {
        { 0, #"│", "IvimIntroSearchBorder" },
        { #"│ ", #"│ " + #prompt, "IvimIntroSearchIcon" },
        { #left, #left + #text, "IvimIntroSearchPlaceholder" },
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

-- the inside of the search box, right of the prompt
local function search_placement()
    local intro = placement(state.height)
    return {
        relative = "editor",
        row = intro.row + state.search_row,
        col = intro.col + input_col,
        width = width - input_col - 2,
        height = 1,
    }
end

-- everything under the search box: the results cover the hints
local function results_placement()
    local intro = placement(state.height)
    local first = state.search_row + 2
    return {
        relative = "editor",
        row = intro.row + first,
        col = intro.col,
        width = width,
        height = state.height - first,
    }
end

local function fits(height)
    return vim.o.columns >= width + 4 and vim.o.lines >= height + 2
end

-- the covered window's own chrome (line number, current line, the 80th
-- column) would show through around the float
local chrome = { number = false, relativenumber = false, cursorline = false, colorcolumn = "", signcolumn = "no" }

local function close_win(name)
    if state and state[name] and vim.api.nvim_win_is_valid(state[name]) then
        vim.api.nvim_win_close(state[name], true)
    end
    if state then
        state[name] = nil
    end
end

local function stop_search()
    if not state then
        return
    end
    state.generation = state.generation + 1
    if state.timer then
        state.timer:stop()
    end
    for _, job in ipairs(state.jobs or {}) do
        pcall(job.kill, job, 15)
    end
    state.jobs = nil
end

-- Results ----------------------------------------------------------------

-- "~/it/coding/ivim/" shortened on the left to fit `room` cells
local function fit_left(text, room)
    if room <= 1 then
        return ""
    end
    if vim.fn.strdisplaywidth(text) <= room then
        return text
    end
    local chars = vim.fn.strchars(text)
    local keep = vim.fn.strcharpart(text, chars - (room - 1))
    return "…" .. keep
end

local function render_results()
    if not state or not state.results_win or not vim.api.nvim_win_is_valid(state.results_win) then
        return
    end
    local buf = vim.api.nvim_win_get_buf(state.results_win)
    local height = vim.api.nvim_win_get_height(state.results_win)
    -- the last two rows: a blank one and the keys
    local rows = height - 2
    local lines, marks = {}, {}
    local results = state.results
    local first = math.max(1, math.min(state.selected - rows + 1, #results - rows + 1))

    for i = first, math.min(#results, first + rows - 1) do
        local path = results[i]
        local is_dir = vim.fn.isdirectory(path) == 1
        local name = vim.fs.basename(path) .. (is_dir and "/" or "")
        -- a name too long for the list keeps its start
        local room = width - 6
        if vim.fn.strdisplaywidth(name) > room then
            name = vim.fn.strcharpart(name, 0, room - 1) .. "…"
        end
        local parent = vim.fn.fnamemodify(vim.fs.dirname(path), ":~")
        parent = parent == "/" and "/" or parent .. "/"
        local lead = "  " .. name
        local where = fit_left(parent, width - vim.fn.strdisplaywidth(lead) - 4)
        local line = where == "" and lead or lead .. "  " .. where
        table.insert(lines, line)
        local row = #lines - 1
        table.insert(marks, { row, 2, #lead, is_dir and "Directory" or "IvimIntroSearchName" })
        if where ~= "" then
            table.insert(marks, { row, #lead + 2, #line, "IvimIntroMuted" })
        end
        if i == state.selected then
            table.insert(marks, { row, "line", "IvimIntroSearchSelected" })
        end
    end
    if #results == 0 then
        local status = state.jobs and "  searching…" or "  nothing found"
        table.insert(lines, status)
        table.insert(marks, { 0, 0, #status, "IvimIntroMuted" })
    end
    while #lines < height - 1 do
        table.insert(lines, "")
    end
    local help = string.rep(" ", math.floor((width - vim.fn.strdisplaywidth(results_help)) / 2)) .. results_help
    table.insert(lines, help)
    table.insert(marks, { #lines - 1, 0, #help, "IvimIntroMuted" })

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, mark in ipairs(marks) do
        if mark[2] == "line" then
            vim.api.nvim_buf_set_extmark(buf, ns, mark[1], 0, { line_hl_group = mark[3], priority = 10 })
        else
            vim.api.nvim_buf_set_extmark(buf, ns, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4], priority = 20 })
        end
    end
end

local function open_results()
    if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
        return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    local config = results_placement()
    config.style = "minimal"
    config.border = "none"
    config.focusable = false
    config.zindex = 3
    config.noautocmd = true
    state.results_win = vim.api.nvim_open_win(buf, false, config)
    vim.wo[state.results_win].winhighlight = "NormalFloat:Normal"
    vim.wo[state.results_win].winblend = 0
end

-- run the search for `query`, replacing any search still running; results
-- stream in and the list redraws as they come
local function run_search(query)
    stop_search()
    state.results, state.selected = {}, 1
    if not vim.trim(query):match("%S") then
        close_win("results_win")
        return
    end
    open_results()
    local search = require("config.system_search")
    local generation = state.generation
    -- several searches at once (plocate and fd), their lines merged and
    -- each path kept once
    local found, seen = {}, {}
    local function update()
        if state and state.generation == generation then
            state.results = search.rank(query, found)
            state.selected = math.min(state.selected, math.max(1, #state.results))
            render_results()
        end
    end
    local redraw = vim.uv.new_timer()
    local running = 0
    local function finished()
        running = running - 1
        if running > 0 then
            return
        end
        redraw:stop()
        redraw:close()
        if state and state.generation == generation then
            state.jobs = nil
        end
        update()
    end
    state.jobs = {}
    for _, cmd in ipairs(search.commands(query)) do
        local pending = ""
        local ok, job = pcall(vim.system, cmd, {
            text = true,
            stdout = function(_, data)
                if not data then
                    return
                end
                local chunk = pending .. data
                local last_newline = chunk:match(".*()\n")
                if last_newline then
                    for line in chunk:sub(1, last_newline - 1):gmatch("[^\n]+") do
                        line = line:gsub("/$", "")
                        if not seen[line] then
                            seen[line] = true
                            table.insert(found, line)
                        end
                    end
                    pending = chunk:sub(last_newline + 1)
                else
                    pending = chunk
                end
            end,
        }, vim.schedule_wrap(finished))
        if ok then
            running = running + 1
            table.insert(state.jobs, job)
        end
    end
    if running == 0 then
        redraw:close()
        state.jobs = nil
        update()
        return
    end
    -- show what has arrived so far while fd is still walking the disk
    redraw:start(150, 150, vim.schedule_wrap(update))
    render_results()
end

-- Opening and leaving ------------------------------------------------------

local function open_target(target)
    vim.cmd("stopinsert")
    vim.schedule(function()
        if state and vim.api.nvim_win_is_valid(state.base_win) then
            vim.api.nvim_set_current_win(state.base_win)
        end
        M.close()
        -- a folder opens in Oil (default_file_explorer)
        vim.cmd.edit(vim.fn.fnameescape(target))
    end)
end

local function accept(query)
    if not state then
        return
    end
    local target = require("config.system_search").typed_path(query) or state.results[state.selected]
    if target then
        open_target(target)
    end
end

local function move(step)
    if not state or #state.results == 0 then
        return
    end
    state.selected = (state.selected - 1 + step) % #state.results + 1
    render_results()
end

-- Esc in the search line: back to the empty buffer, the start screen stays
local function leave_search()
    vim.cmd("stopinsert")
    vim.schedule(function()
        if not state then
            return
        end
        stop_search()
        close_win("results_win")
        close_win("search_win")
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

    local function query()
        return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    end
    local function show_placeholder()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        if query() == "" then
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

    local function map(keys, fn)
        for _, key in ipairs(type(keys) == "table" and keys or { keys }) do
            vim.keymap.set({ "i", "n" }, key, fn, { buffer = buf, nowait = true })
        end
    end
    map({ "<Esc>", "<C-c>" }, leave_search)
    map("<CR>", function()
        accept(query())
    end)
    map({ "<Down>", "<C-n>", "<Tab>" }, function()
        move(1)
    end)
    map({ "<Up>", "<C-p>", "<S-Tab>" }, function()
        move(-1)
    end)

    state.timer = state.timer or vim.uv.new_timer()
    vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
        group = group,
        buffer = buf,
        callback = function()
            show_placeholder()
            local text = query()
            state.timer:stop()
            state.timer:start(debounce, 0, vim.schedule_wrap(function()
                if state and state.search_win then
                    run_search(text)
                end
            end))
        end,
    })
    vim.cmd("startinsert")
end

function M.close()
    if not state then
        return
    end
    vim.api.nvim_clear_autocmds({ group = group })
    stop_search()
    if state.timer then
        state.timer:close()
    end
    close_win("results_win")
    close_win("search_win")
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

--- Whether `buf` is the empty, unnamed buffer the start screen covers.
M.is_empty = is_empty

--- What Enter would open now (for the tests).
function M.selection()
    return state and state.results[state.selected]
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
        results = {},
        selected = 1,
        generation = 0,
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
            if state.results_win and vim.api.nvim_win_is_valid(state.results_win) then
                vim.api.nvim_win_set_config(state.results_win, results_placement())
                render_results()
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
