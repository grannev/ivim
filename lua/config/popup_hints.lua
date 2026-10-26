-- Popup hints: one switch (<leader>uh) for what pops up on its own while
-- typing — the completion menu and the delayed hover. Off by default:
-- completion then opens with Tab (lua/plugins/completion.lua) and
-- documentation with K. The signature float inside a call's parentheses
-- is always on.
local M = {}

vim.g.popup_hints_enabled = false

function M.enabled()
    return vim.g.popup_hints_enabled == true
end

function M.toggle()
    vim.g.popup_hints_enabled = not M.enabled()
    if not M.enabled() then
        local ok, cmp = pcall(require, "blink.cmp")
        if ok then
            pcall(cmp.hide)
        end
    end
    vim.notify(M.enabled() and "Popup hints enabled" or "Popup hints disabled", vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>uh", M.toggle, { desc = "Toggle popup hints" })

return M
