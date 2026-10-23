-- In Neovide, :q in the last window goes back to the start screen instead
-- of closing the editor; :q on the start screen itself still quits. :wq
-- and :x write first, :q! drops the changes, and a file with unsaved
-- changes stops :q as usual. With other windows or tab pages open, these
-- close the window as they always do. lua/config/neovide.lua turns it on.
local M = {}

local function is_float(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
end

-- the only window left: quitting it would close the editor
local function last_window()
    if is_float(0) or #vim.api.nvim_list_tabpages() > 1 then
        return false
    end
    local windows = vim.tbl_filter(function(win)
        return not is_float(win)
    end, vim.api.nvim_tabpage_list_wins(0))
    return #windows == 1
end

local function back_to_menu(bang)
    local old = vim.api.nvim_get_current_buf()
    if vim.bo[old].modified and not bang then
        vim.api.nvim_echo({ { "E37: No write since last change (add ! to override)" } }, true, { err = true })
        return
    end
    vim.cmd(bang and "enew!" or "enew")
    -- the file closes, as :q would have closed it, unless another window
    -- still shows it
    if vim.api.nvim_buf_is_valid(old) and vim.fn.bufwinid(old) == -1 then
        pcall(vim.api.nvim_buf_delete, old, { force = bang })
    end
    require("config.intro").open()
end

--- :q, or :wq / :x with `write` set to "write" / "update".
function M.quit(bang, write)
    if write then
        vim.cmd(write .. (bang and "!" or ""))
    end
    if not last_window() or require("config.intro").is_empty(vim.api.nvim_get_current_buf()) then
        vim.cmd(bang and "quit!" or "quit")
        return
    end
    back_to_menu(bang)
end

function M.setup()
    local commands = {
        { "IvimQuit", "q", nil },
        { "IvimWriteQuit", "wq", "write" },
        { "IvimExit", "x", "update" },
    }
    for _, command in ipairs(commands) do
        local name, typed, write = command[1], command[2], command[3]
        vim.api.nvim_create_user_command(name, function(args)
            M.quit(args.bang, write)
        end, { bang = true, desc = ":" .. typed .. ", back to the start screen in the last window" })
        -- only the whole command line "q" (or "q!"), nothing that merely
        -- contains it
        vim.cmd(("cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s'"):format(
            typed,
            typed,
            name,
            typed
        ))
    end
end

return M
