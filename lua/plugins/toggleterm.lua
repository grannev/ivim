local lazygit = nil

local function open_lazygit()
    if not lazygit then
        lazygit = require("toggleterm.terminal").Terminal:new({
            cmd = "lazygit",
            direction = "float",
            hidden = true,
            close_on_exit = true,
            float_opts = {
                width = function()
                    return math.floor(vim.o.columns * 0.95)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.9)
                end,
            },
            -- lazygit closes its own panels with Esc; the terminal-wide
            -- Esc below would steal it
            on_open = function(term)
                vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = term.bufnr, nowait = true })
            end,
        })
    end
    lazygit.dir = vim.fn.getcwd()
    lazygit:toggle()
end

return {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
        { "<C-\\>", "<cmd>ToggleTerm direction=float<CR>", desc = "Toggle floating terminal" },
        { "<C-\\>", "<cmd>ToggleTerm direction=float<CR>", mode = "t", desc = "Toggle floating terminal" },
        { "<Esc>", [[<C-\><C-n>]], mode = "t", desc = "Exit terminal mode" },
        { "<leader>gg", open_lazygit, desc = "Open LazyGit" },
    },
    opts = {
        direction = "float",
        shade_terminals = false,
        start_in_insert = true,
        persist_size = true,
        close_on_exit = true,
        float_opts = {
            border = "rounded",
            width = function()
                return math.floor(vim.o.columns * 0.85)
            end,
            height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
        },
    },
}
