-- Headless checks of the configuration; run them with ./tests/run.sh,
-- which sets up the throwaway directories this expects. Each check is a
-- feature that worked once and could break on a plugin update or a
-- careless edit. Prints one line per check, exits non-zero on a failure.
local failures = 0

local function report(ok, name, err)
    io.stdout:write((ok and "ok    " or "FAIL  ") .. name .. "\n")
    if not ok then
        failures = failures + 1
        io.stdout:write("      " .. tostring(err):gsub("\n", "\n      ") .. "\n")
    end
end

local function test(name, fn)
    vim.cmd("silent! tabonly | silent! only")
    local ok, err = xpcall(fn, debug.traceback)
    report(ok, name, err)
end

local function check(value, what)
    if not value then
        error(what, 2)
    end
    return value
end

local function eq(actual, expected, what)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(what, vim.inspect(expected), vim.inspect(actual)), 2)
    end
end

local function wait_for(predicate, ms)
    return vim.wait(ms or 10000, predicate, 50)
end

local function clients()
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        names[client.name] = (names[client.name] or 0) + 1
    end
    return names
end

-- floating windows, leaving out mini.animate's short-lived animation ones
local function floats()
    return vim.tbl_filter(function(win)
        local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
        return vim.api.nvim_win_get_config(win).relative ~= "" and not name:find("^minianimate://")
    end, vim.api.nvim_list_wins())
end

local function keys(lhs)
    vim.api.nvim_feedkeys(vim.keycode(lhs), "mx", false)
end

local function run()
    test("startup leaves no messages", function()
        eq(vim.api.nvim_exec2("messages", { output = true }).output, "", ":messages")
        eq(vim.g.colors_name, "tokyonight-night", "colorscheme")
    end)

    -- lazy.nvim fires VeryLazy on UIEnter, which a headless run never sees
    vim.api.nvim_exec_autocmds("UIEnter", {})
    wait_for(function()
        return package.loaded["neoscroll"] ~= nil and package.loaded["which-key"] ~= nil
    end, 5000)

    test("island contract: island.nvim eager, no status line plugin, gitsigns", function()
        local spec = require("lazy.core.config").plugins["island.nvim"]
        check(spec, "island.nvim is in the plugin spec")
        eq(spec.lazy, false, "island.nvim lazy")
        vim.cmd("edit sample.lua")
        check(wait_for(function()
            return vim.b.gitsigns_status_dict ~= nil
        end, 5000), "gitsigns sets vim.b.gitsigns_status_dict")
        eq(package.loaded["lualine"], nil, "lualine loaded")
    end)

    test("status line: global, at the bottom, mode, file, git, position", function()
        eq(vim.o.laststatus, 3, "laststatus")
        vim.cmd("edit sample.lua")
        check(wait_for(function()
            return vim.b.gitsigns_status_dict ~= nil
        end, 5000), "gitsigns for the branch")
        local text = require("config.statusline").render():gsub("%%#[^#]+#", "")
        for _, part in ipairs({ "NORMAL", "sample.lua", "%l:%c", "lua" }) do
            check(text:find(part, 1, true), ("%q in the status line: %s"):format(part, text))
        end
        check(text:find(vim.b.gitsigns_status_dict.head, 1, true), "the branch in the status line: " .. text)
    end)

    test("keymaps", function()
        local expected = {
            { "n", " ff" }, { "n", " fg" }, { "n", " e" }, { "n", "-" },
            { "n", " xx" }, { "n", " sr" }, { "n", " ss" }, { "n", " sl" }, { "n", " rr" },
            { "n", " lf" }, { "n", " uh" }, { "n", " ih" }, { "n", " ch" }, { "n", " Db" },
            { "n", " tt" }, { "n", "<A-Right>" }, { "n", "<C-\\>" }, { "n", "]c" }, { "n", "]t" },
            { "n", "<C-d>" }, { "n", "n" }, { "n", "<ScrollWheelDown>" }, { "n", " fs" },
        }
        for _, map in ipairs(expected) do
            check(not vim.tbl_isempty(vim.fn.maparg(map[2], map[1], false, true)), "no mapping for " .. map[2])
        end
    end)

    test("C and C++ each get their own clangd, with treesitter", function()
        vim.cmd("edit folds.c")
        check(wait_for(function()
            return clients()["clangd"]
        end), "clangd attaches to C")
        check(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "treesitter on C")
        vim.cmd("edit todo.cpp")
        check(wait_for(function()
            return clients()["clangd_cpp"]
        end), "clangd_cpp attaches to C++")
        eq(clients()["clangd"], nil, "plain clangd on C++")
        check(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "treesitter on C++ (cpp parser)")
    end)

    test("signature float inside a call's parentheses, nothing inserted", function()
        vim.cmd("edit folds.c")
        check(wait_for(function()
            return clients()["clangd"]
        end), "clangd attaches to C")
        local function signature_text()
            local cmp = package.loaded["blink.cmp"]
            if not (cmp and cmp.is_signature_visible()) then
                return nil
            end
            local win = require("blink.cmp.signature.window").win:get_win()
            return table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
        end
        -- Insert mode holds the main loop until it ends (feedkeys "x!"), so
        -- the checks run from timers inside it and Esc ends it at the end
        local function poll(predicate, ms, done)
            local waited = 0
            local function step()
                if predicate() or waited >= ms then
                    return done(predicate())
                end
                waited = waited + 50
                vim.defer_fn(step, 50)
            end
            vim.defer_fn(step, 50)
        end
        local seen = {}
        poll(function()
            return (signature_text() or ""):find("int a, int b", 1, true)
        end, 10000, function(shown)
            seen.text = signature_text()
            seen.shown = shown
            if shown then
                seen.config = vim.api.nvim_win_get_config(require("blink.cmp.signature.window").win:get_win())
            end
            -- out of the call, the float closes
            vim.api.nvim_feedkeys(vim.keycode("<Down><End>"), "n", false)
            poll(function()
                return signature_text() == nil
            end, 3000, function(closed)
                seen.closed = closed
                vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
            end)
        end)
        local line = vim.fn.getline(10)
        -- right before "2" in add(1, 2): no "(" or "," typed
        vim.api.nvim_win_set_cursor(0, { 10, line:find("2)", 1, true) - 1 })
        vim.api.nvim_feedkeys("i", "nx!", false)
        check(seen.shown, "the signature float shows add's parameters: " .. tostring(seen.text))
        check(seen.config.relative ~= "" and seen.config.border, "the signature is a bordered float")
        check(seen.closed, "the float closes outside the call")
        eq(vim.fn.getline(10), line, "the line after Insert mode")
        eq(vim.fn.mode(), "n", "back in Normal mode")
    end)

    test("Lua: lua_ls, and formatters never start as servers", function()
        vim.cmd("edit sample.lua")
        check(wait_for(function()
            return clients()["lua_ls"]
        end), "lua_ls attaches")
        vim.wait(500)
        eq(clients()["stylua"], nil, "stylua client")
        eq(clients()["ruff"], nil, "ruff client")
    end)

    test("Rust: one rust-analyzer from rustaceanvim, Rust keys", function()
        vim.cmd("edit rs/src/main.rs")
        check(wait_for(function()
            return clients()["rust-analyzer"]
        end, 20000), "rust-analyzer attaches")
        vim.wait(500)
        eq(clients()["rust-analyzer"], 1, "rust-analyzer clients")
        eq(clients()["rust_analyzer"], nil, "a second, lspconfig rust_analyzer client")
        check(wait_for(function()
            return vim.fn.maparg(" rR", "n", false, true).buffer == 1
        end, 2000), "<leader>rR runnables in the Rust buffer")
        if vim.fn.executable("codelldb") == 1 then
            check(vim.g.rustaceanvim.dap and vim.g.rustaceanvim.dap.adapter, "codelldb DAP adapter")
        end
    end)

    test("Telescope previewer highlights with nvim-treesitter main", function()
        require("lazy").load({ plugins = { "telescope.nvim" } })
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local a = 1" })
        require("telescope.previewers.utils").highlighter(buf, "lua")
    end)

    test("gutter letters and TODO comments lit from the leader on", function()
        eq(vim.deep_equal(vim.diagnostic.config().signs.text, { "E", "W", "I", "H" }), true, "diagnostic signs")
        vim.cmd("edit todo.cpp")
        local buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_cursor(0, { 4, 0 })
        -- a redraw parses the tree todo-comments asks whether this is a
        -- comment; it then only updates visible lines on its own timer,
        -- which headless never gets to, so its highlight is called here
        vim.cmd("redraw!")
        require("todo-comments.highlight").highlight(buf, 0, 3)
        local ns = require("todo-comments.config").ns
        check(#vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) > 0, "todo-comments highlighted nothing")
        vim.cmd("redraw!")

        -- the screen row of a buffer line (the winbar sits above line 1)
        local function row_of(lnum)
            return vim.fn.screenpos(0, lnum, 1).row
        end
        local function col_of(row, char)
            for col = 1, vim.o.columns do
                if vim.fn.screenstring(row, col) == char then
                    return col
                end
            end
            error(("%q not on screen row %d"):format(char, row))
        end
        -- /* TODO: Something */: the leader looks like the text after TODO
        local one, two = row_of(1), row_of(2)
        eq(vim.fn.screenattr(one, col_of(one, "/")), vim.fn.screenattr(one, col_of(one, "S")), "/* vs Something")
        -- int x = 1; // FIXME: later: the code keeps its own colours
        eq(vim.fn.screenattr(two, col_of(two, "/")), vim.fn.screenattr(two, col_of(two, "l")), "// vs later")
        check(vim.fn.screenattr(two, col_of(two, "i")) ~= vim.fn.screenattr(two, col_of(two, "/")), "code before // is not lit")

        local signs = {}
        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
            if mark[4].sign_text and (mark[4].sign_hl_group or ""):match("^TodoSign") then
                signs[#signs + 1] = vim.trim(mark[4].sign_text)
            end
        end
        eq(table.concat(signs, " "), "T F N", "TODO signs")
    end)

    test("winbar path, scrollbar, rainbow brackets, CSV table, rendered Markdown", function()
        vim.cmd("edit folds.c")
        check(wait_for(function()
            return vim.wo.winbar ~= ""
        end, 3000), "dropbar's winbar on a C file")
        -- "printf("%d\n", add(1, 2));": the outer and inner parentheses
        -- in different colours
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.cmd("redraw!")
        local row = vim.fn.screenpos(0, 10, 1).row
        local brackets = {}
        for col = 1, vim.o.columns do
            if vim.fn.screenstring(row, col) == "(" then
                table.insert(brackets, vim.fn.screenattr(row, col))
            end
        end
        eq(#brackets, 2, "parentheses on the printf line")
        check(brackets[1] ~= brackets[2], "nested parentheses in different colours")

        local lines = {}
        for i = 1, 200 do
            lines[i] = "-- line " .. i
        end
        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.bo.filetype = "lua"
        vim.api.nvim_exec_autocmds("BufReadPost", { buffer = 0 })
        check(wait_for(function()
            vim.cmd("redraw")
            return #floats() > 0
        end, 3000), "a scrollbar on a long buffer")
        vim.cmd("bwipeout!")

        vim.fn.writefile({ "id,name", "1,Alice", "2,Bob" }, "table.csv")
        vim.cmd("edit table.csv")
        check(wait_for(function()
            return require("csvview").is_enabled(0)
        end, 3000), "csvview on in a CSV buffer")

        vim.fn.writefile({ "# Title", "", "- [ ] todo" }, "notes.md")
        vim.cmd("edit notes.md")
        local rendered = function()
            for name, id in pairs(vim.api.nvim_get_namespaces()) do
                if name:find("render-markdown", 1, true) and #vim.api.nvim_buf_get_extmarks(0, id, 0, -1, {}) > 0 then
                    return true
                end
            end
        end
        check(wait_for(function()
            vim.cmd("redraw")
            return rendered()
        end, 3000), "render-markdown draws the Markdown buffer")
    end)

    test("C body folds: zM folds function bodies", function()
        vim.cmd("edit folds.c")
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        keys("zM")
        eq(vim.fn.foldclosed(10), 10, "main's body folded")
        keys("zR")
    end)

    test("tab line numbers the tabs", function()
        vim.cmd("tabnew sample.lua")
        local line = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str
        check(line:find("1:") and line:find("2:sample.lua"), "tab line: " .. line)
    end)

    test("start screen: search line focused, Esc to the editor, / back, typing closes it", function()
        local columns, lines = vim.o.columns, vim.o.lines
        vim.o.columns, vim.o.lines = 200, 50
        vim.cmd("enew")
        local base = vim.api.nvim_get_current_win()
        require("config.intro").open()
        vim.wait(100)
        -- (its startinsert only takes effect once Neovim is back in its main
        -- loop, which a test run never returns to)
        eq(#floats(), 2, "floats with the search line focused")
        check(vim.api.nvim_get_current_win() ~= base, "cursor in the search line")
        eq(vim.wo[base].number, false, "number under the start screen")
        keys("<Esc>")
        vim.wait(100)
        eq(#floats(), 1, "floats after Esc")
        eq(vim.api.nvim_get_current_win(), base, "window after Esc")
        keys("/")
        vim.wait(100)
        eq(#floats(), 2, "floats after /")
        keys("<Esc>")
        vim.wait(100)
        keys("i")
        vim.cmd("stopinsert")
        eq(#floats(), 0, "floats after typing in the buffer")
        eq(vim.wo.number, true, "number after typing")
        vim.o.columns, vim.o.lines = columns, lines
    end)

    test("start screen search: results under the line, a file opens, a folder opens in Oil", function()
        local columns, lines = vim.o.columns, vim.o.lines
        vim.o.columns, vim.o.lines = 200, 50
        local intro = require("config.intro")
        local tag = tostring(vim.uv.hrtime())
        local file = vim.fn.getcwd() .. "/ivimsearch" .. tag .. ".lua"
        local dir = vim.fn.getcwd() .. "/ivimfolder" .. tag
        vim.fn.writefile({ "-- found" }, file)
        vim.fn.mkdir(dir)

        -- typing in the search line, as Insert mode would report it
        local function type_query(query)
            local line = vim.api.nvim_get_current_buf()
            vim.api.nvim_buf_set_lines(line, 0, -1, false, { query })
            vim.api.nvim_exec_autocmds("TextChangedI", { buffer = line })
        end

        local function search(query, expected)
            vim.cmd("enew")
            intro.open()
            vim.wait(100)
            type_query(query)
            check(wait_for(function()
                return intro.selection() == expected
            end, 15000), ("%s listed first for %q (got %s)"):format(expected, query, tostring(intro.selection())))
            eq(vim.bo.filetype, "", "still in the search line, no picker")
            keys("<CR>")
            vim.wait(300)
        end

        vim.cmd("enew")
        intro.open()
        vim.wait(100)
        local box = {}
        for _, win in ipairs(floats()) do
            for _, line in ipairs(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)) do
                if line:find("^[╭│╰]") then
                    table.insert(box, vim.fn.strdisplaywidth(line))
                end
            end
        end
        eq(#box, 3, "search box rows")
        check(box[1] == box[2] and box[2] == box[3], "search box rows of one width: " .. table.concat(box, ", "))

        search("ivimsearch" .. tag, file)
        eq(vim.api.nvim_buf_get_name(0), file, "file opened")
        search("ivimfolder" .. tag, dir)
        eq(vim.bo.filetype, "oil", "folder opened in Oil")
        check(vim.api.nvim_buf_get_name(0):find("ivimfolder" .. tag, 1, true), "Oil shows the folder")

        -- a typed path that exists opens without waiting for results
        vim.cmd("enew")
        intro.open()
        vim.wait(100)
        type_query(file)
        keys("<CR>")
        vim.wait(300)
        eq(vim.api.nvim_buf_get_name(0), file, "typed path opened")

        -- Esc leaves the results for the editor, the start screen stays
        vim.cmd("enew")
        intro.open()
        vim.wait(100)
        type_query("zzzznothing" .. tag)
        vim.wait(3000, function()
            return #floats() == 3
        end)
        eq(#floats(), 3, "start screen, search line and results")
        keys("<Esc>")
        vim.wait(200)
        eq(#floats(), 1, "only the start screen after Esc")
        intro.close()
        vim.o.columns, vim.o.lines = columns, lines
    end)

    test("Ctrl-d and n glide the cursor line to the middle", function()
        vim.cmd("enew")
        local lines = {}
        for i = 1, 300 do
            lines[i] = "line " .. i
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        local moved = 0
        local id = vim.api.nvim_create_autocmd("CursorMoved", {
            callback = function()
                moved = moved + 1
            end,
        })
        local middle = math.ceil(vim.fn.winheight(0) / 2)
        keys("<C-d>")
        check(wait_for(function()
            return vim.fn.line(".") > 1 and vim.fn.winline() == middle
        end, 3000), ("cursor line centred after <C-d> (winline %d)"):format(vim.fn.winline()))
        check(moved > 0, "CursorMoved after the scroll")
        vim.fn.setreg("/", "line 200")
        keys("n")
        check(wait_for(function()
            return vim.fn.line(".") == 200 and vim.fn.winline() == middle
        end, 3000), ("match centred after n (line %d, winline %d)"):format(vim.fn.line("."), vim.fn.winline()))
        vim.api.nvim_del_autocmd(id)
    end)

    test(":q back to the start screen (Neovide only)", function()
        eq(vim.fn.maparg("q", "c", true), "", "a :q abbreviation outside Neovide")
        -- what lua/config/neovide.lua turns on under Neovide
        require("config.menu_quit").setup()
        local columns, lines = vim.o.columns, vim.o.lines
        vim.o.columns, vim.o.lines = 200, 50
        local function typed(cmd)
            return pcall(vim.api.nvim_feedkeys, vim.keycode(cmd), "tx", false)
        end
        -- the start screen up over an empty buffer (the cursor itself is
        -- in its search line)
        local function on_start_screen()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_get_config(win).relative == "" then
                    return require("config.intro").is_empty(vim.api.nvim_win_get_buf(win)) and #floats() >= 1
                end
            end
        end

        vim.cmd("edit sample.lua")
        local file = vim.api.nvim_get_current_buf()
        typed(":q<CR>")
        check(on_start_screen(), ":q in the last window shows the start screen")
        eq(vim.fn.buflisted(file), 0, "the file closed")

        require("config.intro").close()
        vim.cmd("edit sample.lua")
        vim.api.nvim_buf_set_lines(0, 0, 0, false, { "-- changed" })
        vim.v.errmsg = ""
        typed(":q<CR>")
        eq(vim.fn.expand("%:t"), "sample.lua", ":q with unsaved changes stays")
        eq(vim.v.errmsg, "E37: No write since last change (add ! to override)", "the E37 message")
        typed(":q!<CR>")
        check(on_start_screen(), ":q! drops the changes and shows the start screen")

        require("config.intro").close()
        vim.cmd("edit sample.lua")
        vim.api.nvim_buf_set_lines(0, 0, 0, false, { "-- written" })
        typed(":wq<CR>")
        check(on_start_screen(), ":wq shows the start screen")
        eq(vim.fn.readfile("sample.lua")[1], "-- written", ":wq wrote the file")

        -- last: after a :q that really closes a window, keys fed with
        -- nvim_feedkeys(..., "x") no longer expand abbreviations (typed
        -- ones do), and a plain :q here would end the test run
        require("config.intro").close()
        vim.cmd("edit sample.lua | vsplit")
        typed(":q<CR>")
        eq(#vim.api.nvim_tabpage_list_wins(0), 1, "windows after :q in a split")
        eq(vim.fn.expand("%:t"), "sample.lua", ":q in a split only closes the window")

        require("config.intro").close()
        vim.o.columns, vim.o.lines = columns, lines
    end)

    test(":NvimConfigHealth lists the mason packages by group", function()
        vim.cmd("edit sample.lua")
        require("config.health").run()
        local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        for _, group in ipairs(require("config.tools").groups) do
            check(text:find("## Mason: " .. group.name, 1, true), "no section for " .. group.name)
        end
        vim.cmd("close")
        eq(vim.wo.spell, false, "spell in the window under the health float")
    end)

    io.stdout:write(failures == 0 and "\nall checks passed\n" or ("\n%d check(s) failed\n"):format(failures))
    vim.cmd(failures == 0 and "qa!" or "cquit 1")
end

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.schedule(run)
    end,
})
