return {
  "TheLeoP/powershell.nvim",
  ft = "ps1",
  dependencies = { "Saghen/blink.cmp", "mfussenegger/nvim-dap" },
  opts = function()
    return {
      bundle_path = vim.fn.stdpath("data") .. "/powershell-editor-services",
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    }
  end,
}
