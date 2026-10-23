-- Inlay hints are off until <leader>ih; the switch is global, so buffers
-- whose server attaches later follow it too.
local group = vim.api.nvim_create_augroup("LspInlayHints", { clear = true })
local enabled = false

local function set_inlay_hints(bufnr, value)
    pcall(vim.lsp.inlay_hint.enable, value, { bufnr = bufnr })
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.inlayHintProvider then
            set_inlay_hints(event.buf, enabled)
        end
    end,
})

vim.keymap.set("n", "<leader>ih", function()
    enabled = not enabled
    set_inlay_hints(vim.api.nvim_get_current_buf(), enabled)
    vim.notify(enabled and "Inlay hints enabled" or "Inlay hints disabled", vim.log.levels.INFO)
end, { desc = "Toggle inlay hints" })
