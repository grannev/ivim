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

local function floats()
    return vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative ~= ""
    end, vim.api.nvim_list_wins())
end

local function keys(lhs)
    vim.api.nvim_feedkeys(vim.keycode(lhs), "mx", false)
end

local function run()
    test("startup leaves no messages", function()
        eq(vim.api.nvim_exec2("messages", { output = true }).output, "", ":messages")
        eq(vim.g.colors_name, "ivim", "colorscheme")
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

    test("keymaps", function()
        local expected = {
            { "n", " ff" }, { "n", " fg" }, { "n", " e" }, { "n", "-" }, { "n", " gg" },
            { "n", " xx" }, { "n", " sr" }, { "n", " ss" }, { "n", " sl" }, { "n", " rr" },
            { "n", " lf" }, { "n", " uh" }, { "n", " ih" }, { "n", " ch" }, { "n", " Db" },
            { "n", " tt" }, { "n", "<A-Right>" }, { "n", "<C-\\>" }, { "n", "]c" }, { "n", "]t" },
            { "n", "<C-d>" }, { "n", "n" }, { "n", "<ScrollWheelDown>" },
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

        local function col_of(row, char)
            for col = 1, vim.o.columns do
                if vim.fn.screenstring(row, col) == char then
                    return col
                end
            end
            error(("%q not on screen row %d"):format(char, row))
        end
        -- /* TODO: Something */: the leader looks like the text after TODO
        eq(vim.fn.screenattr(1, col_of(1, "/")), vim.fn.screenattr(1, col_of(1, "S")), "/* vs Something")
        -- int x = 1; // FIXME: later: the code keeps its own colours
        eq(vim.fn.screenattr(2, col_of(2, "/")), vim.fn.screenattr(2, col_of(2, "l")), "// vs later")
        check(vim.fn.screenattr(2, col_of(2, "i")) ~= vim.fn.screenattr(2, col_of(2, "/")), "code before // is not lit")

        local signs = {}
        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
            if mark[4].sign_text and (mark[4].sign_hl_group or ""):match("^TodoSign") then
                signs[#signs + 1] = vim.trim(mark[4].sign_text)
            end
        end
        eq(table.concat(signs, " "), "T F N", "TODO signs")
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

    test("start screen opens, hides the chrome and goes on typing", function()
        local columns, lines = vim.o.columns, vim.o.lines
        vim.o.columns, vim.o.lines = 200, 50
        vim.cmd("enew")
        require("config.intro").open()
        eq(#floats(), 1, "floats while open")
        eq(vim.wo.number, false, "number while open")
        keys("i")
        vim.cmd("stopinsert")
        eq(#floats(), 0, "floats after typing")
        eq(vim.wo.number, true, "number after typing")
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
