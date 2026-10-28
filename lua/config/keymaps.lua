local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<CR>", { desc = "Write" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- IDE-like editing: delete the previous word (terminals send Ctrl-Backspace
-- as either <C-BS> or <C-h>, Alt-Backspace as <M-BS>) and the next one
map({ "i", "c" }, "<C-BS>", "<C-w>", { desc = "Delete previous word" })
map({ "i", "c" }, "<M-BS>", "<C-w>", { desc = "Delete previous word" })
map("i", "<C-h>", "<C-w>", { desc = "Delete previous word" })
map("i", "<C-Del>", "<C-o>dw", { desc = "Delete next word" })
map({ "i", "c" }, "<C-w>", "<Nop>", { desc = "Use Ctrl-Backspace to delete a word" })

-- splits and window navigation
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Horizontal split" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- resize splits (Ctrl-Left/Right stay Vim's word motions, and Alt-Left/
-- Right below switch tabs, so the width goes on Ctrl-Alt)
map("n", "<C-Up>", ":resize -2<CR>")
map("n", "<C-Down>", ":resize +2<CR>")
map("n", "<C-A-Left>", ":vertical resize -2<CR>")
map("n", "<C-A-Right>", ":vertical resize +2<CR>")

-- buffers
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bl", "<cmd>ls<CR>", { desc = "List buffers" })

-- tabs: switch with Alt-Left/Right or Alt-1..9, reorder the current one
-- with its neighbour by adding Shift
map("n", "<A-Left>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<A-Right>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>tt", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>to", "<cmd>tabonly<CR>", { desc = "Only this tab" })
for i = 1, 9 do
    map("n", "<A-" .. i .. ">", i .. "gt", { desc = "Tab " .. i })
end

-- :tabmove errors past either end instead of stopping there, so this
-- checks the edge first
local function move_tab(offset)
    local current = vim.fn.tabpagenr()
    local last = vim.fn.tabpagenr("$")
    local target = current + offset
    if target < 1 or target > last then
        return
    end
    vim.cmd.tabmove({ args = { tostring(offset >= 0 and ("+" .. offset) or offset) } })
end
map("n", "<A-S-Left>", function() move_tab(-1) end, { desc = "Move tab left" })
map("n", "<A-S-Right>", function() move_tab(1) end, { desc = "Move tab right" })
-- some terminals send Alt-Shift-arrows as raw sequences Neovim does not
-- decode
map("n", "\27[1;4D", function() move_tab(-1) end)
map("n", "\27[1;4C", function() move_tab(1) end)

-- make and quickfix
map("n", "<leader>mm", "<cmd>make<CR>", { desc = "Run make" })
map("n", "<leader>mo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>mc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>mn", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
map("n", "<leader>mp", "<cmd>cprevious<CR>", { desc = "Previous quickfix item" })

-- move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Ctrl-d/u and n/N keep the cursor centred too, animated: see
-- lua/plugins/animate.lua

-- Neovim's own LSP keys (grr, grn, gra, gri, grt, grx) make every gr — Go
-- to references here — wait timeoutlen for a possible second r; gr, gi,
-- <leader>rn and <leader>ca (lua/plugins/lsp.lua) already do their jobs
for _, lhs in ipairs({ "grr", "grn", "gra", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, "n", lhs)
    pcall(vim.keymap.del, "x", lhs)
end
