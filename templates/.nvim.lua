-- Project-local Neovim config. Copy to a project root and `git add` it.
-- Neovim will prompt you to :trust it the first time.
--
-- Anything touching a plugin MUST go inside on_load -- this file is sourced
-- before plugins exist.

local override = require("override")

override.on_load(function()
  -- Different formatter for just this project
  -- require("conform").formatters_by_ft.python = { "black" }

  -- Tweak an LSP server's settings here only
  -- vim.lsp.config.gopls.settings = {
  --   gopls = { analyses = { ST1000 = false } },
  -- }

  -- Project run/test commands, bound locally
  -- vim.keymap.set("n", "<leader>pr", "<cmd>!make run<CR>", { desc = "Run project" })
  -- vim.keymap.set("n", "<leader>pt", "<cmd>!make test<CR>", { desc = "Test project" })
end)

-- Plain options need no deferral
-- vim.o.tabstop = 4
-- vim.o.shiftwidth = 4
