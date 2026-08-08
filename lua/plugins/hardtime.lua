-- Blocks repeated hjkl and other lazy motions so you reach for counts, words,
-- and flash instead. Nags by design -- :Hardtime toggle when you're fighting
-- it rather than learning from it.
return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  event = "BufReadPost",
  opts = {
    disabled_filetypes = {
      "qf", "netrw", "help", "checkhealth", "grug-far",
      "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches",
      "dap-repl", "neotest-summary", "neotest-output-panel",
      "minifiles", "ministarter",
    },
  },
}
