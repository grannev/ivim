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

-- what the terminal shows behind the code, on average: the wallpaper
-- through Alacritty's own background (navy-teal, #142630 to #1D343E)
local wallpaper = "#182F39"

-- Alacritty (colors.transparent_background_colors) lays every cell
-- background over the wallpaper at the window's opacity, as it does its
-- own background: shown = 0.75·bg + 0.25·W, and the wallpaper shows as
-- 0.75·#1B2B34 + 0.25·W. The background that shows as `target` on average
-- is then #1B2B34 + (target - wallpaper) / 0.75; the wallpaper's own
-- shading still comes through it.
local alacritty_bg, opacity = "#1B2B34", 0.75

local function channels(hex)
    return { tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) }
end

local function hex(rgb)
    local out = {}
    for i = 1, 3 do
        out[i] = math.max(0, math.min(255, math.floor(rgb[i] + 0.5)))
    end
    return ("#%02X%02X%02X"):format(out[1], out[2], out[3])
end

-- how a cell background shows over the wallpaper, on average: what text
-- (never translucent) has to be coloured to sit flush against it
local function shown(bg)
    local b, a, w = channels(bg), channels(alacritty_bg), channels(wallpaper)
    return hex({ opacity * b[1] + w[1] - opacity * a[1], opacity * b[2] + w[2] - opacity * a[2], opacity * b[3] + w[3] - opacity * a[3] })
end

local function through(target)
    local t, a, w = channels(target), channels(alacritty_bg), channels(wallpaper)
    return hex({ a[1] + (t[1] - w[1]) / opacity, a[2] + (t[2] - w[2]) / opacity, a[3] + (t[3] - w[3]) / opacity })
end

-- the status line's mode pills
local function mode_colours(c)
    return {
        Normal = c.blue,
        Insert = c.green,
        Visual = c.magenta,
        Replace = c.red,
        Command = c.yellow,
        Terminal = c.teal,
    }
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
    hl.IvimIntroSearchName = { fg = c.fg }
    hl.IvimIntroSearchSelected = { bg = c.bg_highlight, bold = true }

    -- the tab line (lua/plugins/ui.lua)
    hl.TabbyFill = {}
    hl.TabbyInactive = { fg = c.dark5 }
    hl.TabbyHidden = { fg = c.comment, italic = true }
    hl.TabbyCurrent = { fg = c.blue1, bg = c.bg_highlight, bold = true }

    -- the status line (lua/config/statusline.lua): the mode as a pill in its
    -- own colour, the rest as text on the clear background
    for kind, colour in pairs(mode_colours(c)) do
        hl["IvimStatusMode" .. kind] = { fg = c.black, bg = colour, bold = true }
        hl["IvimStatusModeCap" .. kind] = { fg = colour }
    end
    hl.IvimStatusText = { fg = c.fg_dark }
    hl.IvimStatusMuted = { fg = c.comment }
    hl.IvimStatusFile = { fg = c.fg, bold = true }
    hl.IvimStatusModified = { fg = c.orange }
    hl.IvimStatusBranch = { fg = c.purple }
    hl.IvimStatusAdded = { fg = c.green }
    hl.IvimStatusChanged = { fg = c.blue }
    hl.IvimStatusRemoved = { fg = c.red }
    hl.IvimStatusPosition = { fg = c.blue1 }

    -- the argument being typed in the signature float: tokyonight marks it
    -- with a background, which the clear float barely shows
    hl.BlinkCmpSignatureHelpActiveParameter = { fg = c.orange, bold = true }

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
            on_highlights = function(hl, c)
                own_groups(hl, c)
                if terminal then
                    -- tokyonight's purple-grey current line and near-black
                    -- 80th column stood out as bars over the wallpaper; these
                    -- show a step lighter than it, in its own hue
                    hl.CursorLine = { bg = through("#1F3A47") }
                    hl.ColorColumn = { bg = through("#1B333E") }
                    -- the winbar (dropbar's path) and the status line as
                    -- clear as the editor
                    hl.WinBar = { fg = c.fg_dark }
                    hl.WinBarNC = { fg = c.dark5 }
                    hl.StatusLine = { fg = c.fg_dark }
                    hl.StatusLineNC = { fg = c.dark5 }
                    -- Markdown blocks as tinted glass: a little of the theme's
                    -- colour over the wallpaper
                    local function glass(color, amount)
                        return through(mix(wallpaper, color, amount))
                    end
                    hl.RenderMarkdownCode = { bg = glass(c.bg_dark, 0.55) }
                    local inline = { fg = c.blue, bg = glass(c.terminal_black, 0.45) }
                    hl.RenderMarkdownCodeInline = inline
                    hl["@markup.raw.markdown_inline"] = inline
                    for i, color in ipairs(c.rainbow) do
                        hl["RenderMarkdownH" .. i .. "Bg"] = { bg = glass(color, 0.14) }
                    end
                    -- the scrollbar's thumb, a step past the current line
                    hl.SatelliteBar = { bg = through("#284552") }
                    -- the mode pill: its middle is a translucent background,
                    -- its rounded ends are glyphs in the text colour, which
                    -- the terminal draws solid; the ends take the colour the
                    -- middle shows as, or the middle looks shaded between
                    -- two bright caps
                    for kind, colour in pairs(mode_colours(c)) do
                        hl["IvimStatusModeCap" .. kind] = { fg = shown(colour) }
                    end
                else
                    hl.SatelliteBar = { bg = c.bg_highlight }
                end
                -- the rest of the scrollbar's track stays clear
                hl.SatelliteBackground = {}
            end,
        })
        vim.cmd.colorscheme("tokyonight-night")
    end,
}
