return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- before anything that reads highlight groups
  opts = {
    flavour = "mocha",
    integrations = {
      blink_cmp = true,
      mini = { enabled = true },
      native_lsp = { enabled = true, underlines = { errors = { "undercurl" } } },
      treesitter = true,
      dap = true,
      dap_ui = true,
      neotest = true,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
