-- Adapters come from your system package manager, same as LSP servers --
-- install codelldb / dlv / debugpy with pacman, not mason.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "x" }, desc = "Eval expression" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol" })

      dap.listeners.after.event_initialized["cfg"] = dapui.open
      dap.listeners.before.event_terminated["cfg"] = dapui.close
      dap.listeners.before.event_exited["cfg"] = dapui.close

      -- C/C++/Zig: prefer codelldb where it's installed (Arch AUR:
      -- codelldb-bin; more polished pretty-printing), otherwise fall back to
      -- lldb-dap. On macOS lldb-dap ships inside Xcode / Command Line Tools
      -- since Xcode 16 -- if you have a C compiler at all, you already have
      -- it, reachable via `xcrun lldb-dap`. On Linux it's sometimes on PATH
      -- as lldb-dap or the older name lldb-vscode. Rust is NOT handled here:
      -- rustaceanvim wires codelldb itself via :RustLsp debuggables.
      if vim.fn.executable("codelldb") == 1 then
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          executable = { command = "codelldb", args = { "--port", "${port}" } },
        }
        local cfg = {
          {
            name = "Launch",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
        }
        dap.configurations.c = cfg
        dap.configurations.cpp = cfg
        dap.configurations.zig = cfg
      else
        local lldb_dap
        if vim.fn.executable("xcrun") == 1 then
          local out = vim.fn.system({ "xcrun", "-f", "lldb-dap" }):gsub("%s+$", "")
          if vim.v.shell_error == 0 and out ~= "" then
            lldb_dap = out
          end
        end
        if not lldb_dap then
          for _, name in ipairs({ "lldb-dap", "lldb-vscode" }) do
            if vim.fn.executable(name) == 1 then
              lldb_dap = name
              break
            end
          end
        end

        if lldb_dap then
          dap.adapters.lldb = { type = "executable", command = lldb_dap, name = "lldb" }
          local cfg = {
            {
              name = "Launch",
              type = "lldb",
              request = "launch",
              program = function()
                return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
              end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
            },
          }
          dap.configurations.c = cfg
          dap.configurations.cpp = cfg
          dap.configurations.zig = cfg
        end
      end

      if vim.fn.executable("dlv") == 1 then
        dap.adapters.delve = {
          type = "server",
          port = "${port}",
          executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
        }
        dap.configurations.go = {
          { type = "delve", name = "Debug", request = "launch", program = "${file}" },
          { type = "delve", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
        }
      end

      if vim.fn.executable("python") == 1 then
        dap.adapters.python = {
          type = "executable",
          command = "python",
          args = { "-m", "debugpy.adapter" },
        }
        dap.configurations.python = {
          { type = "python", request = "launch", name = "Launch file", program = "${file}" },
        }
      end

      vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticWarn", linehl = "Visual" })
    end,
  },
}
