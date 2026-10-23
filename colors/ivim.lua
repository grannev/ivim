-- Graphite surfaces and restrained accents for a quiet editing canvas.
vim.cmd("highlight clear")
vim.o.background = "dark"
vim.g.colors_name = "ivim"

local p = {
    bg = "#1C1C1E",
    guide = "#20313A",
    border = "#3A3A3C",
    text = "#DADADD",
    muted = "#8E8E93",
    faint = "#55555B",
    blue = "#8AB4F8",
    purple = "#BEA0D6",
    green = "#A1BEA0",
    yellow = "#D6BE8C",
    red = "#E89797",
    selection = "#343F52",
    reference = "#2B3442",
    rule = "#2E2E32",
}
local groups = {
    Normal = { fg = p.text },
    NormalNC = { fg = p.text },
    NormalFloat = { fg = p.text },
    FloatBorder = { fg = p.border },
    FloatTitle = { fg = p.text, bold = true },
    CursorLine = { bg = p.guide },
    CursorLineNr = { fg = p.text, bold = true },
    ColorColumn = { bg = p.guide },
    LineNr = { fg = p.faint },
    SignColumn = {},
    FoldColumn = { fg = p.faint },
    EndOfBuffer = { fg = p.faint },
    NonText = { fg = p.faint },
    Whitespace = { fg = p.faint },
    WinSeparator = { fg = p.border },
    Visual = { bg = p.selection },
    Search = { fg = p.text, bg = p.selection },
    IncSearch = { fg = p.bg, bg = p.blue },
    CurSearch = { fg = p.bg, bg = p.blue },
    MatchParen = { fg = p.blue, bold = true },
    Comment = { fg = p.muted, italic = true },
    String = { fg = p.green },
    Character = { fg = p.green },
    Number = { fg = p.yellow },
    Boolean = { fg = p.yellow },
    Constant = { fg = p.yellow },
    Identifier = { fg = p.text },
    Function = { fg = p.blue },
    Statement = { fg = p.purple },
    Keyword = { fg = p.purple },
    Type = { fg = p.blue },
    PreProc = { fg = p.purple },
    Special = { fg = p.blue },
    Delimiter = { fg = p.muted },
    Operator = { fg = p.muted },
    Todo = { fg = p.yellow, bold = true },
    Error = { fg = p.red },
    ErrorMsg = { fg = p.red },
    WarningMsg = { fg = p.yellow },
    Directory = { fg = p.blue },
    Title = { fg = p.text, bold = true },
    Pmenu = { fg = p.text },
    PmenuSel = { bg = p.selection, bold = true },
    PmenuSbar = {},
    PmenuThumb = { bg = p.border },
    Folded = { fg = p.muted, bg = p.guide },
    TabLine = { fg = p.muted },
    TabLineSel = { fg = p.text, bold = true },
    TabLineFill = {},
    GitSignsAdd = { fg = "#64856A" },
    GitSignsChange = { fg = "#667F9F" },
    GitSignsDelete = { fg = "#A26C70" },
    SpellBad = { sp = p.red, undercurl = true },
    SpellCap = { sp = p.blue, undercurl = true },
    SpellLocal = { sp = p.blue, undercurl = true },
    SpellRare = { sp = p.purple, undercurl = true },
    LspReferenceText = { bg = p.reference },
    LspReferenceRead = { bg = p.reference },
    LspReferenceWrite = { bg = p.reference, bold = true },
    LspInlayHint = { fg = p.faint, italic = true },
    LspSignatureActiveParameter = { fg = p.blue, bold = true, underline = true },
    LightBulbSign = { fg = p.yellow },
    -- todo-comments keywords (TODO:, FIXME:, ...) on purpose leave the
    -- muted palette: these are the vivid Catppuccin Mocha accents, so a
    -- keyword stands out of an italic grey comment
    TodoColorError = { fg = "#F38BA8" },
    TodoColorWarn = { fg = "#F9E2AF" },
    TodoColorInfo = { fg = "#89DCEB" },
    TodoColorHint = { fg = "#94E2D5" },
    TodoColorDefault = { fg = "#F2CDCD" },
    -- the start screen (lua/config/intro.lua): the logo's rows run from
    -- blue to purple, the keys are blue, the rest stays quiet
    IvimIntroLogo1 = { fg = "#8AB4F8" },
    IvimIntroLogo2 = { fg = "#94B0F1" },
    IvimIntroLogo3 = { fg = "#9FACEA" },
    IvimIntroLogo4 = { fg = "#A9A8E4" },
    IvimIntroLogo5 = { fg = "#B4A4DD" },
    IvimIntroLogo6 = { fg = "#BEA0D6" },
    IvimIntroShadow = { fg = p.faint },
    IvimIntroKey = { fg = p.blue, bold = true },
    IvimIntroDesc = { fg = p.text },
    IvimIntroMuted = { fg = p.muted },
    IblIndent = { fg = p.rule },
    IblScope = { fg = p.border },
    TabbyFill = {},
    TabbyInactive = { fg = p.muted },
    TabbyHidden = { fg = p.faint, italic = true },
    TabbyCurrent = { fg = p.text, bold = true },
    TelescopeNormal = { link = "NormalFloat" },
    TelescopeBorder = { link = "FloatBorder" },
    TelescopeSelection = { bg = p.selection },
    TelescopeMatching = { fg = p.blue, bold = true },
    TelescopePromptPrefix = { fg = p.blue },
    TelescopeTitle = { link = "FloatTitle" },
    BlinkCmpMenu = { link = "Pmenu" },
    BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpMenuSelection = { link = "PmenuSel" },
    BlinkCmpDoc = { link = "NormalFloat" },
    BlinkCmpDocBorder = { link = "FloatBorder" },
}
local links = {
    ["@comment"] = "Comment",
    ["@string"] = "String",
    ["@character"] = "Character",
    ["@number"] = "Number",
    ["@boolean"] = "Boolean",
    ["@constant"] = "Constant",
    ["@variable"] = "Identifier",
    ["@property"] = "Identifier",
    ["@module"] = "Identifier",
    ["@function"] = "Function",
    ["@function.call"] = "Function",
    ["@method"] = "Function",
    ["@method.call"] = "Function",
    ["@constructor"] = "Function",
    ["@type"] = "Type",
    ["@operator"] = "Operator",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"] = "Delimiter",
    ["@tag"] = "Function",
    ["@tag.attribute"] = "Identifier",
    ["@lsp.type.keyword"] = "@keyword",
    ["@lsp.type.function"] = "@function",
    ["@lsp.type.method"] = "@method",
    ["@lsp.type.parameter"] = "@variable.parameter",
    ["@lsp.type.property"] = "@property",
    ["@lsp.type.type"] = "@type",
}
for name, target in pairs(links) do
    groups[name] = { link = target }
end
for _, name in ipairs({
    "@keyword",
    "@keyword.conditional",
    "@keyword.coroutine",
    "@keyword.exception",
    "@keyword.function",
    "@keyword.import",
    "@keyword.operator",
    "@keyword.repeat",
    "@keyword.return",
    "@keyword.type",
}) do
    groups[name] = { fg = p.purple, italic = true }
end
groups["@variable.parameter"] = { fg = p.text, italic = true }
groups["@variable.builtin"] = { fg = p.purple, italic = true }
groups["@function.builtin"] = { fg = p.blue, italic = true }
groups["@type.builtin"] = { fg = p.blue, italic = true }
groups["@string.escape"] = { fg = p.blue }
groups["@attribute"] = { fg = p.yellow, italic = true }
for name, color in pairs({ Error = p.red, Warn = p.yellow, Info = p.blue, Hint = p.muted }) do
    groups["Diagnostic" .. name] = { fg = color }
    groups["DiagnosticUnderline" .. name] = { sp = color, underline = true }
end
for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
end
