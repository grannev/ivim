-- tokyonight, night style: deep navy, blue, azure and cyan accents. In a
-- terminal the background stays transparent, so the wallpaper shows
-- through like before; Neovide paints the theme's own navy and makes the
-- window translucent instead (lua/config/neovide.lua). tokyonight colours
-- every installed plugin on its own (plugins.auto); the groups below are
-- the ones only this config has. colors/ivim.lua, the old graphite
-- palette, is still there: :colorscheme ivim.

-- a step of the way from one #rrggbb colour to another
local function mix(from, to, t)
    local function channel(hex, i)
        return tonumber(hex:sub(2 * i, 2 * i + 1), 16)
    end
    local rgb = {}
    for i = 1, 3 do
        rgb[i] = math.floor(channel(from, i) + (channel(to, i) - channel(from, i)) * t + 0.5)
    end
    return ("#%02X%02X%02X"):format(rgb[1], rgb[2], rgb[3])
end

local function own_groups(hl, c)
    -- todo-comments keywords (lua/plugins/todo-comments.lua): the vivid
    -- accents, so a keyword stands out of an italic comment
    hl.TodoColorError = { fg = c.red }
    hl.TodoColorWarn = { fg = c.yellow }
    hl.TodoColorInfo = { fg = c.cyan }
    hl.TodoColorHint = { fg = c.teal }
    hl.TodoColorDefault = { fg = c.magenta }

    -- the start screen (lua/config/intro.lua): the logo's rows run from
    -- blue through azure to cyan
    for row = 1, 6 do
        hl["IvimIntroLogo" .. row] = { fg = mix(c.blue, c.cyan, (row - 1) / 5) }
    end
    hl.IvimIntroShadow = { fg = c.blue7 }
    hl.IvimIntroKey = { fg = c.blue1, bold = true }
    hl.IvimIntroDesc = { fg = c.fg }
    hl.IvimIntroMuted = { fg = c.comment }
    hl.IvimIntroSearchBorder = { fg = c.blue1 }
    hl.IvimIntroSearchIcon = { fg = c.cyan, bold = true }
    hl.IvimIntroSearchPlaceholder = { fg = c.comment, italic = true }

    -- the tab line (lua/plugins/ui.lua)
    hl.TabbyFill = {}
    hl.TabbyInactive = { fg = c.dark5 }
    hl.TabbyHidden = { fg = c.comment, italic = true }
    hl.TabbyCurrent = { fg = c.blue1, bg = c.bg_highlight, bold = true }

    -- the code-action mark in the gutter (lua/plugins/lightbulb.lua)
    hl.LightBulbSign = { fg = c.yellow }

    -- Neovim's own diff text groups, which tokyonight leaves at Neovim's
    -- defaults (:Lazy logs, git output in floats)
    hl.Added = { fg = c.git.add }
    hl.Changed = { fg = c.git.change }
    hl.Removed = { fg = c.git.delete }
end

return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local terminal = not vim.g.neovide
        require("tokyonight").setup({
            style = "night",
            transparent = terminal,
            styles = {
                comments = { italic = true },
                keywords = { italic = true },
                sidebars = terminal and "transparent" or "dark",
                floats = terminal and "transparent" or "dark",
            },
            on_highlights = own_groups,
        })
        vim.cmd.colorscheme("tokyonight-night")
    end,
}
