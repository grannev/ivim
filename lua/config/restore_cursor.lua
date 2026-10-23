-- reopen a file where it was left
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(event)
        local filetype = vim.bo[event.buf].filetype
        if filetype == "gitcommit" or filetype == "gitrebase" then
            return
        end
        local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
            vim.cmd("normal! zz")
        end
    end,
})
