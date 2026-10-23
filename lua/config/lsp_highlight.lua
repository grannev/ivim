-- Other uses of the symbol under the cursor light up once the cursor has
-- rested on it for a moment, and go dark as soon as it moves or typing
-- starts.
local group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true })
local highlight_timer = nil

local function stop_timer()
    if highlight_timer and not highlight_timer:is_closing() then
        highlight_timer:stop()
        highlight_timer:close()
    end
    highlight_timer = nil
end

local function schedule_highlight(bufnr)
    stop_timer()
    vim.lsp.buf.clear_references()
    highlight_timer = vim.uv.new_timer()
    highlight_timer:start(1500, 0, vim.schedule_wrap(function()
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
            return
        end
        if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then
            return
        end
        vim.lsp.buf.document_highlight()
    end))
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client or not client.server_capabilities.documentHighlightProvider then
            return
        end
        vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
            group = group,
            buffer = event.buf,
            callback = function()
                schedule_highlight(event.buf)
            end,
        })
        vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertEnter", "BufLeave", "WinLeave" }, {
            group = group,
            buffer = event.buf,
            callback = function()
                stop_timer()
                vim.lsp.buf.clear_references()
            end,
        })
    end,
})
