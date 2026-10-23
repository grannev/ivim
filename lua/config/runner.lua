-- <leader>rr writes the current file and runs it in a floating terminal
-- from the working directory; the terminal stays until Enter.
local function has_in_cwd(marker)
    local path = vim.fn.getcwd() .. "/" .. marker
    return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

local function open_runner_terminal(cmd)
    local Terminal = require("toggleterm.terminal").Terminal
    local full_cmd = table.concat({
        "cd",
        vim.fn.shellescape(vim.fn.getcwd()),
        "&&",
        cmd,
        ";",
        "printf '\\n[process exited] press Enter to close...'",
        ";",
        "read _",
    }, " ")
    Terminal:new({
        cmd = full_cmd,
        direction = "float",
        close_on_exit = true,
        hidden = true,
        float_opts = {
            width = function()
                return math.floor(vim.o.columns * 0.85)
            end,
            height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
        },
    }):toggle()
end

local function run_current_file()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
        vim.notify("No file to run", vim.log.levels.WARN)
        return
    end
    vim.cmd("write")

    local ft = vim.bo.filetype
    local src = vim.fn.shellescape(file)
    local cmd
    if ft == "python" then
        -- Debian ships python3 without a plain "python"
        cmd = (vim.fn.executable("python") == 1 and "python " or "python3 ") .. src
    elseif ft == "sh" or ft == "bash" then
        cmd = "bash " .. src
    elseif ft == "go" then
        cmd = "go run " .. src
    elseif ft == "rust" then
        if has_in_cwd("Cargo.toml") then
            cmd = "cargo run"
        else
            cmd = "rustc " .. src .. " -o /tmp/nvim_run_rust && /tmp/nvim_run_rust"
        end
    elseif ft == "c" then
        cmd = "gcc " .. src .. " -Wall -Wextra -std=c11 -o /tmp/nvim_run_c && /tmp/nvim_run_c"
    elseif ft == "cpp" then
        cmd = "g++ " .. src .. " -Wall -Wextra -std=c++20 -o /tmp/nvim_run_cpp && /tmp/nvim_run_cpp"
    else
        vim.notify("No runner for filetype: " .. ft, vim.log.levels.WARN)
        return
    end
    open_runner_terminal(cmd)
end

vim.keymap.set("n", "<leader>rr", run_current_file, { desc = "Run current file" })
