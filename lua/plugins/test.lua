-- Adapters are only registered when their runner is installed, so this stays
-- quiet in projects that don't use them.
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neotest/nvim-nio",
    "nvim-neotest/neotest-python",
    "fredrikaverpil/neotest-golang",
  },
  keys = {
    { "<leader>Tr", function() require("neotest").run.run() end, desc = "Run nearest test" },
    { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
    { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
    { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
    { "<leader>To", function() require("neotest").output_panel.toggle() end, desc = "Output panel" },
    { "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop" },
  },
  config = function()
    local adapters = {}

    if vim.fn.executable("python") == 1 then
      table.insert(adapters, require("neotest-python")({ dap = { justMyCode = false } }))
    end
    if vim.fn.executable("go") == 1 then
      table.insert(adapters, require("neotest-golang")({ dap_go_enabled = true }))
    end
    -- rustaceanvim ships its own adapter rather than a separate plugin
    local ok, rust = pcall(require, "rustaceanvim.neotest")
    if ok then
      table.insert(adapters, rust)
    end

    require("neotest").setup({
      adapters = adapters,
      status = { virtual_text = true },
      output = { open_on_run = true },
    })
  end,
}
