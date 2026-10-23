-- Popup hints: one switch (<leader>uh) for everything that pops up on its
-- own while typing — the completion menu, the signature float and the
-- delayed hover. Off by default: completion then opens with Tab
-- (lua/plugins/completion.lua) and documentation with K.
local M = {}

vim.g.popup_hints_enabled = false

function M.enabled()
    return vim.g.popup_hints_enabled == true
end

function M.signature_opts()
    return {
        bind = true,
        floating_window = M.enabled(),
        floating_window_above_cur_line = true,
        floating_window_off_x = 1,
        floating_window_off_y = 0,
        hint_enable = false,
        doc_lines = 2,
        max_height = 8,
        max_width = function()
            return math.floor(vim.api.nvim_win_get_width(0) * 0.75)
        end,
        wrap = true,
        fix_pos = false,
        close_timeout = 3000,
        always_trigger = false,
        extra_trigger_chars = M.enabled() and { "(", "," } or {},
        hi_parameter = "LspSignatureActiveParameter",
        handler_opts = { border = "rounded" },
        toggle_key = "<M-s>",
        select_signature_key = "<M-n>",
    }
end

function M.apply_signature()
    local ok, signature = pcall(require, "lsp_signature")
    if ok then
        signature.setup(M.signature_opts())
    end
end

function M.toggle()
    vim.g.popup_hints_enabled = not M.enabled()
    M.apply_signature()
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
