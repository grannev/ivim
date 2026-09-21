vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt

o.number = true
o.relativenumber = false
o.mouse = "a"
o.clipboard = "unnamedplus"
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.signcolumn = "yes"
o.updatetime = 250
o.timeoutlen = 300
o.splitright = true
o.splitbelow = true
o.list = false
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.inccommand = "split"
o.cursorline = true
o.colorcolumn = "80"
o.scrolloff = 8
o.termguicolors = true
o.showmode = false
o.ruler = false
o.showcmd = false
o.cmdheight = 0
o.showtabline = 0
o.pumheight = 8
o.winborder = "rounded"
-- Use the terminal background without blending in underlying buffer text.
o.winblend = 0
o.pumblend = 0
o.fillchars = { eob = " " }

vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    underline = true,
    severity_sort = true,
    update_in_insert = false,
    signs = { text = { [1] = "●", [2] = "●", [3] = "·", [4] = "·" } },
    float = { border = "rounded", source = "if_many", header = "", prefix = "" },
})

o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true
