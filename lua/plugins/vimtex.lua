-- LaTeX: latexmk in continuous mode, the PDF in Evince. VimTeX's own
-- mappings are off; the ones below exist only in tex buffers.
return {
    "lervag/vimtex",
    lazy = false,
    init = function()
        vim.g.vimtex_view_method = "general"
        vim.g.vimtex_view_general_viewer = "evince"
        vim.g.vimtex_view_general_options = "@pdf"
        vim.g.vimtex_compiler_method = "latexmk"
        vim.g.vimtex_compiler_latexmk = {
            continuous = 1,
            callback = 1,
            executable = "latexmk",
            options = { "-verbose", "-file-line-error", "-synctex=1", "-interaction=nonstopmode" },
        }
        vim.g.vimtex_quickfix_mode = 0
        vim.g.vimtex_mappings_enabled = 0
        vim.g.vimtex_indent_enabled = 1
    end,
    config = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "tex",
            callback = function(event)
                local map = function(keys, cmd, desc)
                    vim.keymap.set("n", keys, cmd, { buffer = event.buf, desc = desc })
                end
                map("<leader>ll", "<cmd>VimtexCompile<CR>", "LaTeX compile")
                map("<leader>lv", "<cmd>VimtexView<CR>", "LaTeX view PDF")
                map("<leader>le", "<cmd>VimtexErrors<CR>", "LaTeX errors")
                map("<leader>lt", "<cmd>VimtexTocToggle<CR>", "LaTeX table of contents")
                map("<leader>lk", "<cmd>VimtexStop<CR>", "LaTeX stop compiler")
                map("<leader>lc", "<cmd>VimtexClean<CR>", "LaTeX clean aux files")
                map("<leader>li", "<cmd>VimtexInfo<CR>", "LaTeX info")
            end,
        })
    end,
}
