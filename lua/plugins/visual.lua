-- What the editor shows around and inside the code: the path to the symbol
-- under the cursor above each window, a scrollbar with marks, brackets
-- coloured by depth, CSV as a table and Markdown rendered in place. Their
-- colours come from tokyonight and lua/plugins/colorscheme.lua.
return {
    {
        -- the winbar: file › class › function under the cursor; each part
        -- opens a menu of its siblings on click or with <leader>;
        "Bekaboo/dropbar.nvim",
        event = { "BufReadPost", "BufNewFile" },
        keys = {
            {
                "<leader>;",
                function()
                    require("dropbar.api").pick()
                end,
                desc = "Pick a symbol in the winbar",
            },
            {
                "[;",
                function()
                    require("dropbar.api").goto_context_start()
                end,
                desc = "Start of the current context",
            },
        },
        opts = {},
    },
    {
        -- a scrollbar along each window's right edge, with where the
        -- cursor, search matches, diagnostics and git changes are
        "lewis6991/satellite.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            current_only = false,
            -- opaque: blended over the transparent terminal it would take
            -- the colours of whatever text is under it
            winblend = 0,
            excluded_filetypes = { "oil", "TelescopePrompt", "lazy", "mason", "help", "Trouble" },
            handlers = {
                cursor = { enable = true },
                search = { enable = true },
                diagnostic = { enable = true },
                gitsigns = { enable = true },
                marks = { enable = false },
                quickfix = { enable = false },
            },
        },
    },
    {
        -- brackets coloured by nesting depth, from the treesitter parsers
        "HiPhish/rainbow-delimiters.nvim",
        -- its test submodule sits on gitlab, which this network cannot
        -- reach; the plugin does not need it
        submodules = false,
        -- it attaches on FileType, which a BufReadPost-triggered load
        -- arrives too late for; its authors advise against lazy-loading
        lazy = false,
    },
    {
        -- a CSV/TSV file shown as an aligned table with a sticky header;
        -- the text itself is untouched
        "hat0uma/csvview.nvim",
        ft = { "csv", "tsv" },
        cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
        opts = {
            view = {
                display_mode = "border",
                header_lnum = true,
                sticky_header = { enabled = true, separator = "─" },
            },
            keymaps = {
                -- if / af: a field; Tab / Shift-Tab: field to field; Enter
                -- / Shift-Enter: row to row (only in CSV buffers)
                textobject_field_inner = { "if", mode = { "o", "x" } },
                textobject_field_outer = { "af", mode = { "o", "x" } },
                jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
                jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
                jump_next_row = { "<Enter>", mode = { "n", "v" } },
                jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
            },
        },
        config = function(_, opts)
            local csvview = require("csvview")
            csvview.setup(opts)
            -- on in every CSV buffer, the one that loaded the plugin too
            local function enable(buf)
                if not csvview.is_enabled(buf) then
                    csvview.enable(buf)
                end
            end
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "csv", "tsv" },
                callback = function(args)
                    enable(args.buf)
                end,
            })
            enable(vim.api.nvim_get_current_buf())
        end,
    },
    {
        -- Markdown drawn in place: headings, code blocks, lists, checkboxes,
        -- tables, quotes; the raw text comes back under the cursor and in
        -- Insert mode. Hover docs (K) are Markdown too and render as well.
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        opts = {
            -- no LaTeX converter (pylatexenc) is installed
            latex = { enabled = false },
            code = { width = "block", left_pad = 2, right_pad = 2 },
            heading = { width = "block", left_pad = 1, right_pad = 2 },
        },
    },
}
