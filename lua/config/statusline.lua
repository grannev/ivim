-- The status line: one, global, at the bottom (laststatus = 3). Left: the
-- mode as a rounded pill, the git branch and its changes, the file. Right:
-- diagnostics as the gutter's letters, the language servers, the filetype
-- and the position. No plugin: Neovim draws it from render() on every
-- redraw, so everything here is a cheap read. The island shows the same
-- things in the top bar; lua/plugins/island.lua tells it to leave
-- 'laststatus' alone. Colours live in lua/plugins/colorscheme.lua
-- (IvimStatus*).
local M = {}

-- Nerd Font glyphs, written as escapes so no editor or tool drops them
local cap_left, cap_right = "\u{e0b6}", "\u{e0b4}"
local branch_icon = "\u{e0a0}"

local modes = {
    n = { "NORMAL", "Normal" },
    no = { "O-PENDING", "Normal" },
    i = { "INSERT", "Insert" },
    ic = { "INSERT", "Insert" },
    v = { "VISUAL", "Visual" },
    V = { "V-LINE", "Visual" },
    ["\22"] = { "V-BLOCK", "Visual" },
    s = { "SELECT", "Visual" },
    S = { "S-LINE", "Visual" },
    ["\19"] = { "S-BLOCK", "Visual" },
    R = { "REPLACE", "Replace" },
    Rv = { "V-REPLACE", "Replace" },
    c = { "COMMAND", "Command" },
    t = { "TERMINAL", "Terminal" },
    r = { "PROMPT", "Command" },
    ["!"] = { "SHELL", "Command" },
}

-- a literal % in a file name would start a statusline item
local function escape(text)
    return (text:gsub("%%", "%%%%"))
end

local function hl(group, text)
    return "%#" .. group .. "#" .. text
end

local function mode_pill()
    local mode = vim.api.nvim_get_mode().mode
    local entry = modes[mode] or modes[mode:sub(1, 1)] or { mode:upper(), "Normal" }
    local name, kind = entry[1], entry[2]
    return hl("IvimStatusModeCap" .. kind, cap_left)
        .. hl("IvimStatusMode" .. kind, " " .. name .. " ")
        .. hl("IvimStatusModeCap" .. kind, cap_right)
end

local function git(buf)
    local dict = vim.b[buf].gitsigns_status_dict
    if not dict or not dict.head or dict.head == "" then
        return ""
    end
    local parts = { hl("IvimStatusBranch", branch_icon .. " " .. escape(dict.head)) }
    for _, item in ipairs({ { "added", "+", "IvimStatusAdded" }, { "changed", "~", "IvimStatusChanged" }, { "removed", "-", "IvimStatusRemoved" } }) do
        local count = dict[item[1]] or 0
        if count > 0 then
            table.insert(parts, hl(item[3], item[2] .. count))
        end
    end
    return table.concat(parts, " ")
end

local function file(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local buftype = vim.bo[buf].buftype
    local text
    if buftype == "terminal" then
        text = "terminal"
    elseif name:match("^oil://") then
        text = vim.fn.fnamemodify(name:gsub("^oil://", ""), ":~:.")
    elseif name == "" then
        text = "[No Name]"
    else
        text = vim.fn.fnamemodify(name, ":~:.")
    end
    local out = hl("IvimStatusFile", escape(text))
    if vim.bo[buf].modified then
        out = out .. hl("IvimStatusModified", " ●")
    end
    if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
        out = out .. hl("IvimStatusMuted", " [ro]")
    end
    return out
end

local function diagnostics(buf)
    local counts = vim.diagnostic.count(buf)
    local parts = {}
    for _, item in ipairs({ { 1, "E", "DiagnosticError" }, { 2, "W", "DiagnosticWarn" }, { 3, "I", "DiagnosticInfo" }, { 4, "H", "DiagnosticHint" } }) do
        local count = counts[item[1]]
        if count and count > 0 then
            table.insert(parts, hl(item[3], item[2] .. " " .. count))
        end
    end
    return table.concat(parts, "  ")
end

local function servers(buf)
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        table.insert(names, client.name)
    end
    return #names > 0 and hl("IvimStatusMuted", escape(table.concat(names, ","))) or ""
end

function M.render()
    local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local left = { mode_pill(), git(buf), file(buf) }
    local right = {
        diagnostics(buf),
        servers(buf),
        vim.bo[buf].filetype ~= "" and hl("IvimStatusText", vim.bo[buf].filetype) or "",
        hl("IvimStatusPosition", "%l:%c") .. hl("IvimStatusMuted", " %p%%"),
    }
    local function join(parts)
        return table.concat(vim.tbl_filter(function(part)
            return part ~= ""
        end, parts), hl("IvimStatusText", "   "))
    end
    return hl("IvimStatusText", " ") .. join(left) .. hl("IvimStatusText", "%=") .. join(right) .. hl("IvimStatusText", " ")
end

vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.require'config.statusline'.render()"

-- what changes without moving the cursor: the mode, git's counts, the
-- diagnostics, the servers
vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
    group = vim.api.nvim_create_augroup("ivim.statusline", { clear = true }),
    callback = function()
        vim.cmd("redrawstatus")
    end,
})
vim.api.nvim_create_autocmd("User", {
    group = "ivim.statusline",
    pattern = "GitSignsUpdate",
    callback = function()
        vim.cmd("redrawstatus")
    end,
})

return M
