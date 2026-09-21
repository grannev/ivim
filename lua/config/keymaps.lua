local map = vim.keymap.set

local function termcodes(keys)
    return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function insert_newline()
    vim.api.nvim_feedkeys(termcodes("<CR>"), "n", false)
end

local function smart_enter()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local before_cursor = line:sub(1, cursor[2])
    local after_cursor = line:sub(cursor[2] + 1)

    if before_cursor:sub(-1) ~= "{" then
        insert_newline()
        return
    end

    local closing_tail = after_cursor:match("^%s*}(.*)$")
    if not closing_tail and not after_cursor:match("^%s*$") then
        insert_newline()
        return
    end

    local base_indent = line:match("^%s*") or ""
    local shiftwidth = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop
    local indent_step = vim.bo.expandtab and string.rep(" ", shiftwidth) or "\t"
    local inner_indent = base_indent .. indent_step
    local closing_line = base_indent .. "}" .. (closing_tail or "")

    vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1], false, {
        before_cursor,
        inner_indent,
        closing_line,
    })
    vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, #inner_indent })
end

-- IDE-like editing: delete the previous word and expand a new brace block.
map({ "i", "c" }, "<C-BS>", "<C-w>", { desc = "Delete previous word" })
map({ "i", "c" }, "<C-w>", "<Nop>", { desc = "Use Ctrl-Backspace to delete a word" })
map("i", "<CR>", smart_enter, { desc = "New line or expand block" })

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- resize splits
map("n", "<C-Up>", ":resize -2<CR>")
map("n", "<C-Down>", ":resize +2<CR>")
map("n", "<C-Left>", ":vertical resize -2<CR>")
map("n", "<C-Right>", ":vertical resize +2<CR>")

-- move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- file explorer
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

-- telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })

-- diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostics" })
