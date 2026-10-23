return {
    "nvim-treesitter/nvim-treesitter",
    -- main is the maintained rewrite. master is frozen, and its query
    -- directives no longer match a current Neovim (0.13-dev here): every
    -- markdown code block — the LSP documentation blink.cmp shows, say —
    -- raised "attempt to call method 'range'" from its injection query.
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
        local ts = require("nvim-treesitter")
        ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
        local languages = {
            "c",
            "cpp",
            "go",
            "rust",
            "ron",
            "python",
            "pascal",
            "asm",
            "nasm",
            "javascript",
            "typescript",
            "tsx",
            "bash",
            "lua",
            "vim",
            "vimdoc",
            "query",
            "html",
            "xml",
            "css",
            "json",
            "yaml",
            "toml",
            "latex",
            "bibtex",
            "markdown",
            "markdown_inline",
            "make",
            "cmake",
            "dockerfile",
        }
        -- parsers are compiled in the background with the tree-sitter CLI,
        -- which comes from mason like the servers and formatters do; on a
        -- machine without it the parsers wait for that install to finish.
        -- `install` skips parsers that are already there.
        local function install_parsers()
            ts.install(languages)
        end
        if vim.fn.executable("tree-sitter") == 1 then
            install_parsers()
        else
            local ok, registry = pcall(require, "mason-registry")
            local found, cli = false, nil
            if ok then
                found, cli = pcall(registry.get_package, "tree-sitter-cli")
            end
            if found and not cli:is_installed() then
                cli:install():once("closed", function()
                    vim.schedule(install_parsers)
                end)
            elseif found then
                install_parsers()
            end
        end
        -- main has no highlight/indent = enable: both are switched on per
        -- buffer, for whichever filetype has a parser. LaTeX keeps
        -- VimTeX's indentation, which knows environments and items.
        local keep_indent = { tex = true, plaintex = true, bib = true }
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter", { clear = true }),
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if not lang or not pcall(vim.treesitter.start, args.buf, lang) then
                    return
                end
                if not keep_indent[args.match] then
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}
