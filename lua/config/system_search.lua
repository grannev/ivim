-- Search the whole system for files and folders by name (<leader>fs, and
-- the search line on the start screen, lua/config/intro.lua). Each query
-- runs plocate when it is installed, fd otherwise; Enter opens a file, or
-- a folder in Oil, and a query that is itself an existing path opens that.
local M = {}

local fd = vim.fn.executable("fd") == 1 and "fd" or "fdfind"
-- kernel and runtime trees are not files anyone opens, and the rest are
-- big enough to drown every query
local excluded = { "/proc", "/sys", "/dev", "/run", ".git", "node_modules" }
local max_results = "500"

local function command(query)
    query = vim.trim(query or "")
    if query == "" then
        return nil
    end
    if vim.fn.executable("plocate") == 1 then
        return { "plocate", "--ignore-case", "--limit", max_results, "--", query }
    end
    local cmd = { fd, "--hidden", "--ignore-case", "--fixed-strings", "--absolute-path", "--max-results", max_results }
    for _, pattern in ipairs(excluded) do
        vim.list_extend(cmd, { "--exclude", pattern })
    end
    -- "coding/ivim" matches against the whole path, a bare name only the
    -- file or folder name
    if query:find("/", 1, true) then
        table.insert(cmd, "--full-path")
    end
    vim.list_extend(cmd, { "--", query, "/" })
    return cmd
end

-- the query itself, when it names something that exists: ~/it/coding,
-- /etc/hosts, ./src
local function typed_path(query)
    query = vim.trim(query or "")
    if not query:match("^[~/.]") then
        return nil
    end
    local path = vim.fn.fnamemodify(vim.fn.expand(query), ":p")
    if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
        return path
    end
end

local function entry_maker(path)
    path = path:gsub("/$", "")
    local is_dir = vim.fn.isdirectory(path) == 1
    local shown = vim.fn.fnamemodify(path, ":~") .. (is_dir and "/" or "")
    return {
        value = path,
        path = path,
        ordinal = shown,
        is_dir = is_dir,
        display = function(entry)
            local icon, hl = "", "Directory"
            if not entry.is_dir then
                local ok, devicons = pcall(require, "nvim-web-devicons")
                icon, hl = "", "Normal"
                if ok then
                    local name = vim.fn.fnamemodify(entry.path, ":t")
                    local found, found_hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
                    icon, hl = found or icon, found_hl or hl
                end
            end
            return icon .. " " .. shown, { { { 0, #icon }, hl } }
        end,
    }
end

-- Files preview as Telescope previews them; a folder lists its entries,
-- read at once — Telescope's own folder preview fills in asynchronously
-- and errors when the folder was opened (and the preview closed) first.
local function previewer()
    local previewers = require("telescope.previewers")
    local conf = require("telescope.config").values
    return previewers.new_buffer_previewer({
        title = "Preview",
        define_preview = function(self, entry)
            if not entry.is_dir then
                conf.buffer_previewer_maker(entry.path, self.state.bufnr, { bufname = self.state.bufname })
                return
            end
            local ok, names = pcall(vim.fn.readdir, entry.path)
            local lines = {}
            for _, name in ipairs(ok and names or {}) do
                local is_dir = vim.fn.isdirectory(entry.path .. "/" .. name) == 1
                table.insert(lines, name .. (is_dir and "/" or ""))
            end
            table.sort(lines, function(a, b)
                local a_dir, b_dir = a:sub(-1) == "/", b:sub(-1) == "/"
                if a_dir ~= b_dir then
                    return a_dir
                end
                return a:lower() < b:lower()
            end)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, ok and lines or { "(cannot read this folder)" })
            for i, line in ipairs(lines) do
                if line:sub(-1) == "/" then
                    vim.api.nvim_buf_set_extmark(self.state.bufnr, vim.api.nvim_create_namespace("ivim.system_search"), i - 1, 0, {
                        end_col = #line,
                        hl_group = "Directory",
                    })
                end
            end
        end,
    })
end

--- Open the picker. `default_text` starts the query; `on_cancel` runs
--- when it is closed without opening anything.
function M.open(opts)
    opts = opts or {}
    require("lazy").load({ plugins = { "telescope.nvim" } })
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
        .new({}, {
            prompt_title = "Files and folders on the system",
            default_text = opts.default_text,
            finder = finders.new_async_job({ command_generator = command, entry_maker = entry_maker }),
            sorter = conf.file_sorter({}),
            previewer = previewer(),
            -- one fd run per pause in typing, not per key
            debounce = 150,
            -- between equally good matches, the shorter path
            tiebreak = function(current, existing)
                return #current.ordinal < #existing.ordinal
            end,
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    local picker = action_state.get_current_picker(prompt_bufnr)
                    local query = picker:_get_prompt()
                    -- this picker's own selection: action_state's global one
                    -- still holds the previous picker's until results arrive
                    local entry = picker:get_selection()
                    local target = typed_path(query) or (entry and entry.value)
                    -- nothing to open yet (Enter before the first results):
                    -- the picker stays, with the query
                    if not target then
                        return
                    end
                    actions.close(prompt_bufnr)
                    -- a folder opens in Oil (default_file_explorer)
                    vim.cmd.edit(vim.fn.fnameescape(target))
                end)
                local function cancel()
                    actions.close(prompt_bufnr)
                    if opts.on_cancel then
                        vim.schedule(opts.on_cancel)
                    end
                end
                -- one Esc closes it, as it closes the start screen's line
                map({ "i", "n" }, "<Esc>", cancel)
                map({ "i", "n" }, "<C-c>", cancel)
                return true
            end,
        })
        :find()
end

vim.keymap.set("n", "<leader>fs", function()
    M.open()
end, { desc = "Find files and folders on the system" })

return M
