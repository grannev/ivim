-- Signature help while typing arguments, shown only with popup hints on
-- (lua/config/popup_hints.lua owns the options).
return {
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    config = function()
        require("config.popup_hints").apply_signature()
    end,
}
