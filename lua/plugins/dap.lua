-- Debugging via nvim-dap. Nothing here is Rust-specific: this file only
-- wires up the generic UI, signs and keymaps. lua/plugins/rust.lua points
-- rustaceanvim's codelldb adapter at it; another language would plug into
-- the same "dap" and gain the same UI and keys for free.
return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                dependencies = { "nvim-neotest/nvim-nio" },
                opts = {},
            },
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {},
            },
        },
        keys = {
            { "<leader>bb", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
            {
                "<leader>bB",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "Conditional breakpoint",
            },
            { "<leader>bc", function() require("dap").continue() end, desc = "Continue / start" },
            { "<leader>bi", function() require("dap").step_into() end, desc = "Step into" },
            { "<leader>bo", function() require("dap").step_over() end, desc = "Step over" },
            { "<leader>bO", function() require("dap").step_out() end, desc = "Step out" },
            { "<leader>br", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
            { "<leader>bt", function() require("dap").terminate() end, desc = "Terminate" },
            { "<leader>bu", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
            { "<F5>", function() require("dap").continue() end, desc = "Continue / start" },
            { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
            { "<F10>", function() require("dap").step_over() end, desc = "Step over" },
            { "<F11>", function() require("dap").step_into() end, desc = "Step into" },
        },
        config = function()
            -- Quiet dot/diamond signs to match the diagnostics gutter
            -- markers in config/options.lua, reusing their highlight groups.
            vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", numhl = "" })
            vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticError", numhl = "" })
            vim.fn.sign_define("DapBreakpointRejected", { text = "●", texthl = "DiagnosticHint", numhl = "" })
            vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", numhl = "" })

            local dap, dapui = require("dap"), require("dapui")
            -- Open the UI the moment a session starts and close it when the
            -- session ends, instead of relying on <leader>bu every time.
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
    },
}
