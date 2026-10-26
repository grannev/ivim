-- Completion inserts a function as its name and empty brackets with the
-- cursor between them, never the parameter names: servers send calls as
-- snippets like add(${1:int a}, ${2:int b}), whose placeholders land in
-- the brackets as text in Select mode. Here every tabstop goes, the
-- brackets that held only tabstops are emptied, and the cursor ends where
-- the first tabstop was ($0, which ends the snippet at once). The
-- signature float (lua/plugins/completion.lua) shows the parameters.
local M = {}

local mark = "\1"

-- each tabstop ($1, ${1}, ${1:text}, ${1|a,b|}, $0) as one mark; escaped
-- characters and variables stay as they are
local function mark_tabstops(snippet)
    local out = {}
    local i = 1
    while i <= #snippet do
        local char = snippet:sub(i, i)
        if char == "\\" then
            table.insert(out, snippet:sub(i, i + 1))
            i = i + 2
        elseif char == "$" and snippet:sub(i + 1):match("^%d") then
            table.insert(out, mark)
            i = i + #snippet:sub(i + 1):match("^%d+") + 1
        elseif char == "$" and snippet:sub(i + 1):match("^{%d") then
            -- to the matching "}", across nested placeholders
            local depth, j = 0, i + 1
            while j <= #snippet do
                local c = snippet:sub(j, j)
                if c == "\\" then
                    j = j + 1
                elseif c == "{" then
                    depth = depth + 1
                elseif c == "}" then
                    depth = depth - 1
                    if depth == 0 then
                        break
                    end
                end
                j = j + 1
            end
            table.insert(out, mark)
            i = j + 1
        else
            table.insert(out, char)
            i = i + 1
        end
    end
    return table.concat(out)
end

function M.strip(snippet)
    local text = mark_tabstops(snippet)
    -- (a, b), <T>, [i], {x}: brackets holding only tabstops and the commas
    -- between them become empty brackets with one mark inside
    for _, pair in ipairs({ { "%(", "%)" }, { "<", ">" }, { "%[", "%]" }, { "{", "}" } }) do
        text = text:gsub(pair[1] .. "([" .. mark .. ",%s]*)" .. pair[2], function(inner)
            if inner:find(mark, 1, true) then
                return pair[1]:gsub("%%", "") .. mark .. pair[2]:gsub("%%", "")
            end
        end)
    end
    local first = text:find(mark, 1, true)
    if first then
        text = text:sub(1, first - 1) .. "$0" .. text:sub(first + 1):gsub(mark, "")
    end
    return text
end

return M
