vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt

o.number = true
o.relativenumber = false
o.mouse = "a"
o.clipboard = "unnamedplus"
o.breakindent = true
o.wrap = false
o.ignorecase = true
o.smartcase = true
o.signcolumn = "yes:1"
-- CursorHold after a second's rest: soon enough for the code-action mark
-- (lua/plugins/lightbulb.lua), rare enough that a pause in typing does not
-- set off LSP requests, island updates and a swap-file write each time.
-- The diagnostic and hover popups run on their own timers
-- (lua/plugins/lsp.lua).
o.updatetime = 1000
o.timeoutlen = 400
o.splitright = true
o.splitbelow = true
o.list = false
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.inccommand = "split"
o.cursorline = true
o.colorcolumn = "80"
o.scrolloff = 8
o.sidescrolloff = 8
o.termguicolors = true
o.showmode = false
o.ruler = false
o.showcmd = false
-- the command line has the last row to itself, right under the status
-- line (lua/config/statusline.lua)
o.cmdheight = 1
-- the tab line appears once there is a second tab page (:tabnew)
o.showtabline = 1
o.pumheight = 8
o.winborder = "rounded"
-- Use the terminal background without blending in underlying buffer text.
o.winblend = 0
o.pumblend = 0
o.fillchars = { eob = " " }

o.undofile = true
o.undodir = vim.fn.stdpath("state") .. "/undo"
o.undolevels = 10000
o.undoreload = 10000
vim.fn.mkdir(o.undodir:get()[1], "p")

vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    underline = true,
    severity_sort = true,
    update_in_insert = false,
    signs = { text = { [1] = "E", [2] = "W", [3] = "I", [4] = "H" } },
    float = { border = "rounded", source = true, header = "", prefix = "" },
})

o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true
