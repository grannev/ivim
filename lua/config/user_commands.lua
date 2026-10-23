vim.api.nvim_create_user_command("LspInfo", function()
    vim.cmd("checkhealth vim.lsp")
end, {})

vim.api.nvim_create_user_command("LspClients", function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if vim.tbl_isempty(clients) then
        print("No LSP clients attached to current buffer")
        return
    end
    for _, client in ipairs(clients) do
        print(client.name)
    end
end, {})
