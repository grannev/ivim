-- :NvimConfigHealth (<leader>ch) opens a float listing what this config
-- relies on — system tools, mason packages, state directories and the
-- island connection; r in that float (or :NvimConfigRepair, <leader>cr)
-- installs whatever is missing.
local M = {}

-- package names for apt and pacman; the binary is what gets checked
local system_tools = {
    { cmd = "git", apt = "git", pacman = "git" },
    { cmd = "rg", apt = "ripgrep", pacman = "ripgrep" },
    { cmd = { "fd", "fdfind" }, apt = "fd-find", pacman = "fd" },
    { cmd = "curl", apt = "curl", pacman = "curl" },
    { cmd = "tar", apt = "tar", pacman = "tar" },
    { cmd = "unzip", apt = "unzip", pacman = "unzip" },
    { cmd = "gzip", apt = "gzip", pacman = "gzip" },
    { cmd = "npm", apt = "npm", pacman = "npm" },
    { cmd = { "python3", "python" }, apt = "python3", pacman = "python" },
    { cmd = "cc", apt = "gcc", pacman = "gcc" },
    { cmd = "make", apt = "make", pacman = "make" },
    { cmd = "sed", apt = "sed", pacman = "sed" },
    { cmd = "lazygit", apt = "lazygit", pacman = "lazygit" },
    { cmd = "latexmk", apt = "latexmk", pacman = "texlive-binextra" },
    { cmd = "evince", apt = "evince", pacman = "evince" },
}

local optional_tools = { "go", "rustc", "cargo", "xelatex", "lualatex" }

local tools = require("config.tools")

local function package_manager()
    for _, name in ipairs({ "apt", "pacman" }) do
        if vim.fn.executable(name) == 1 then
            return name
        end
    end
end

local function executable(cmd)
    for _, name in ipairs(type(cmd) == "table" and cmd or { cmd }) do
        if vim.fn.executable(name) == 1 then
            return true
        end
    end
    return false
end

local function directory(path)
    return vim.fn.isdirectory(vim.fn.expand(path)) == 1
end

local function mason_installed(name)
    return directory(vim.fn.stdpath("data") .. "/mason/packages/" .. name)
end

local function add_section(lines, title)
    table.insert(lines, "")
    table.insert(lines, "## " .. title)
end

local function add_check(lines, label, value, hint)
    local line = (value and "OK  " or "NO  ") .. label
    if hint and hint ~= "" then
        line = line .. "  -> " .. hint
    end
    table.insert(lines, line)
end

local function open_float(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    local width = math.min(math.floor(vim.o.columns * 0.9), 92)
    local height = math.min(math.floor(vim.o.lines * 0.8), math.max(#lines + 2, 18))
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        width = width,
        height = height,
        style = "minimal",
        title = " Neovim config health ",
        title_pos = "center",
    })
    -- markdown highlighting without the markdown filetype: its FileType
    -- autocmds (spellcheck in lua/config/spell.lua) would run in the
    -- window that was current before this one
    pcall(vim.treesitter.start, buf, "markdown")

    local opts = { buffer = buf, silent = true }
    vim.keymap.set("n", "q", "<cmd>close<CR>", opts)
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", opts)
    vim.keymap.set("n", "r", function()
        vim.cmd("close")
        M.repair()
    end, { buffer = buf, silent = true, desc = "Repair missing dependencies" })
end

local function open_terminal_command(command)
    local ok, terminal = pcall(require, "toggleterm.terminal")
    if ok then
        terminal.Terminal:new({ cmd = command, direction = "float", close_on_exit = false, hidden = true }):toggle()
        return
    end
    vim.cmd("botright split | resize 12 | terminal " .. command)
end

function M.repair()
    local manager = package_manager()
    local missing_packages = {}
    for _, tool in ipairs(system_tools) do
        if not executable(tool.cmd) and manager and not vim.tbl_contains(missing_packages, tool[manager]) then
            table.insert(missing_packages, tool[manager])
        end
    end

    local missing_mason = vim.tbl_filter(function(name)
        return not mason_installed(name)
    end, tools.packages())

    vim.fn.mkdir(vim.fn.stdpath("state") .. "/undo", "p")
    vim.fn.mkdir(vim.fn.stdpath("state") .. "/sessions", "p")

    if #missing_mason > 0 then
        vim.cmd("MasonInstall " .. table.concat(missing_mason, " "))
    end
    if #missing_packages > 0 then
        local install = manager == "apt" and "sudo apt install " or "sudo pacman -S --needed "
        open_terminal_command(install .. table.concat(missing_packages, " "))
        return
    end
    if #missing_mason > 0 then
        vim.notify("Started Mason install: " .. table.concat(missing_mason, ", "), vim.log.levels.INFO)
        return
    end
    vim.notify("Nothing to repair", vim.log.levels.INFO)
end

function M.run()
    local manager = package_manager() or "apt"
    local version = vim.version()
    local lines = {
        "# Neovim config health",
        "",
        "Config: " .. vim.fn.stdpath("config"),
        "Data:   " .. vim.fn.stdpath("data"),
        "State:  " .. vim.fn.stdpath("state"),
        "CWD:    " .. vim.fn.getcwd(),
    }

    add_section(lines, "Core")
    add_check(lines, "Neovim >= 0.12", vim.fn.has("nvim-0.12") == 1, ("%d.%d.%d"):format(version.major, version.minor, version.patch))
    add_check(lines, "lazy.nvim installed", directory(vim.fn.stdpath("data") .. "/lazy/lazy.nvim"))

    add_section(lines, "System tools")
    for _, tool in ipairs(system_tools) do
        local name = type(tool.cmd) == "table" and tool.cmd[1] or tool.cmd
        add_check(lines, name, executable(tool.cmd), manager .. ": " .. tool[manager])
    end

    add_section(lines, "Optional language tools")
    for _, cmd in ipairs(optional_tools) do
        add_check(lines, cmd, executable(cmd))
    end

    for _, group in ipairs(tools.groups) do
        add_section(lines, "Mason: " .. group.name)
        for _, name in ipairs(group.packages) do
            add_check(lines, name, mason_installed(name))
        end
    end

    add_section(lines, "State directories")
    add_check(lines, "undo dir", directory(vim.fn.stdpath("state") .. "/undo"))
    add_check(lines, "sessions dir", directory(vim.fn.stdpath("state") .. "/sessions"))

    -- the island is the status line (lua/plugins/island.lua); without its
    -- token the plugin stays silent and nothing else says so
    add_section(lines, "Island")
    local token = (vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config") .. "/island-shell/nvim-token"
    add_check(lines, "nvim-token", vim.fn.filereadable(token) == 1, vim.fn.fnamemodify(token, ":~"))
    add_check(lines, "island.nvim loaded", package.loaded["island"] ~= nil)
    add_check(lines, "status line hidden (laststatus = 0)", vim.o.laststatus == 0)
    add_check(lines, "RPC server", vim.v.servername ~= "", vim.v.servername)

    add_section(lines, "Live LSP")
    local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    if vim.tbl_isempty(clients) then
        table.insert(lines, "NO  no LSP attached to current buffer")
    else
        for _, client in ipairs(clients) do
            table.insert(lines, "OK  attached: " .. client.name)
        end
    end

    vim.list_extend(lines, { "", "Press r to repair missing dependencies.", "Press q or Esc to close." })
    open_float(lines)
end

vim.api.nvim_create_user_command("NvimConfigHealth", M.run, {})
vim.api.nvim_create_user_command("NvimConfigRepair", M.repair, {})
vim.keymap.set("n", "<leader>ch", M.run, { desc = "Neovim config health" })
vim.keymap.set("n", "<leader>cr", M.repair, { desc = "Neovim config repair" })

return M
