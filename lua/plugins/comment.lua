-- gc/gcc comment lines, gb/gbc comment blocks; C and C++ use /* */ for
-- both.
return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("Comment").setup({
            padding = true,
            sticky = true,
            toggler = { line = "gcc", block = "gbc" },
            opleader = { line = "gc", block = "gb" },
            mappings = { basic = true, extra = true },
            pre_hook = function()
                local ft = vim.bo.filetype
                if ft == "c" or ft == "cpp" then
                    return "/* %s */"
                end
            end,
        })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "c", "cpp" },
            callback = function()
                vim.bo.commentstring = "/* %s */"
            end,
        })
    end,
}
