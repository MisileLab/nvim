return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
      mode = { "n", "x" },
      desc = "Format",
    },
  },
  opts = {
    -- Format-on-save stays OFF, matching your old vim.g.autoformat = false.
    -- Explicit <leader>cf instead. Override per project in .nvim.lua.
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format" },
      rust = { "rustfmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      go = { "gofmt" },
      zig = { "zigfmt" },
      nix = { "nixfmt" },
      sh = { "shfmt" },
      javascript = { "oxfmt" },
      javascriptreact = { "oxfmt" },
      typescript = { "oxfmt" },
      typescriptreact = { "oxfmt" },
      svelte = { "oxfmt" },
      astro = { "oxfmt" },
      json = { "oxfmt" },
      jsonc = { "oxfmt" },
      yaml = { "oxfmt" },
      markdown = { "oxfmt" },
    },
  },
}
