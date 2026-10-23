-- Russian and English spellcheck, on by itself for prose filetypes. The
-- dictionaries are fetched by Neovim the first time spell is switched on.
vim.opt.spelllang = { "ru", "en_us" }

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "tex", "plaintex", "markdown", "text", "gitcommit" },
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "ru,en_us"
        vim.opt_local.spellcapcheck = ""
    end,
})

vim.keymap.set("n", "<leader>sp", function()
    vim.opt_local.spell = not vim.opt_local.spell:get()
    vim.notify(vim.opt_local.spell:get() and "Spellcheck enabled" or "Spellcheck disabled", vim.log.levels.INFO)
end, { desc = "Toggle spellcheck" })
vim.keymap.set("n", "<leader>sa", "zg", { desc = "Add word to spell dictionary" })
vim.keymap.set("n", "<leader>sA", "zG", { desc = "Add word to spell dictionary temporarily" })
vim.keymap.set("n", "<leader>su", "zug", { desc = "Undo spell add" })
vim.keymap.set("n", "<leader>sf", "z=", { desc = "Spell suggestions" })
