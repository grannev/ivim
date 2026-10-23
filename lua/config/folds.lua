-- Treesitter folds everywhere, all open by default. C and C++ get manual
-- folds instead that hide only a function's body and keep its signature
-- on screen: za folds the body under the cursor, zM folds every top-level
-- body, zR opens them again.
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "0"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.CustomFoldExpr()"
vim.opt.foldtext = "v:lua.CustomFoldText()"
vim.opt.fillchars:append({ fold = " " })

function _G.CustomFoldExpr()
    -- preprocessor lines never start a fold
    if vim.fn.getline(vim.v.lnum):match("^%s*#") then
        return "0"
    end
    return vim.treesitter.foldexpr()
end

function _G.CustomFoldText()
    local fold_size = vim.v.foldend - vim.v.foldstart + 1
    return "+- " .. fold_size .. " lines: ..."
end

-- the first "{" at or below the cursor, unless a ";" or a preprocessor
-- line says this is not a definition
local function find_open_brace_from_cursor()
    local current_line = vim.fn.line(".")
    local scan_until = math.min(current_line + 80, vim.fn.line("$"))
    for line_nr = current_line, scan_until do
        local line = vim.fn.getline(line_nr)
        if line:match("^%s*#") then
            return nil
        end
        local brace_col = line:find("{", 1, true)
        if brace_col then
            return line_nr, brace_col
        end
        if line:find(";", 1, true) then
            return nil
        end
    end
    return nil
end

local function matching_close_brace(open_line, open_col)
    local old_cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { open_line, open_col - 1 })
    vim.cmd("normal! %")
    local close_line = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_win_set_cursor(0, old_cursor)
    if close_line == open_line then
        return nil
    end
    return close_line
end

local function create_body_fold()
    local open_line, open_col = find_open_brace_from_cursor()
    if not open_line then
        return false
    end
    local close_line = matching_close_brace(open_line, open_col)
    if not close_line then
        return false
    end
    local body_start, body_end = open_line + 1, close_line - 1
    if body_start > body_end then
        return false
    end
    vim.cmd(body_start .. "," .. body_end .. "fold")
    return true
end

local function toggle_c_body_fold()
    if vim.fn.foldclosed(".") ~= -1 or vim.fn.foldlevel(".") > 0 then
        vim.cmd("normal! za")
        return
    end
    if not create_body_fold() then
        vim.cmd("normal! za")
    end
end

local function brace_delta(line)
    local opens = select(2, line:gsub("{", ""))
    local closes = select(2, line:gsub("}", ""))
    return opens - closes
end

local function create_all_body_folds()
    vim.cmd("normal! zE")
    local depth = 0
    local folds_created = 0
    for line_nr = 1, vim.fn.line("$") do
        local line = vim.fn.getline(line_nr)
        if not line:match("^%s*#") then
            local open_col = line:find("{", 1, true)
            if depth == 0 and open_col then
                local close_line = matching_close_brace(line_nr, open_col)
                if close_line and close_line > line_nr + 1 then
                    vim.cmd((line_nr + 1) .. "," .. (close_line - 1) .. "fold")
                    folds_created = folds_created + 1
                end
            end
            depth = math.max(0, depth + brace_delta(line))
        end
    end
    if folds_created == 0 then
        vim.notify("No function body folds found", vim.log.levels.INFO)
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function(event)
        vim.opt_local.foldmethod = "manual"
        vim.opt_local.foldenable = true
        vim.opt_local.foldlevel = 99
        local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = desc })
        end
        map("za", toggle_c_body_fold, "Toggle C/C++ function body fold")
        map("<leader>z", toggle_c_body_fold, "Toggle C/C++ function body fold")
        map("zM", function()
            create_all_body_folds()
            vim.cmd("normal! zM")
        end, "Close all C/C++ function body folds")
        map("zR", "<cmd>normal! zR<CR>", "Open all C/C++ function body folds")
    end,
})

vim.keymap.set("n", "<leader>z", "za", { desc = "Toggle fold" })
