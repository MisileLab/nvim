-- Neovim 0.12+ config.
--
-- Plugin layer: zpack.nvim -- a thin layer over the native vim.pack that adds
-- lazy-loading and lazy.nvim-shaped specs. Installation, updates, lockfile and
-- version pinning are all still vim.pack underneath.
--
-- Load order (see :h initialization):
--   7b  init.lua        -> leader, options, keymaps, autocmds, zpack bootstrap
--   7c  .nvim.lua       -> project-local config via exrc (see lua/override.lua)
--   11  plugin/ files sourced
--   18  VimEnter        -> queued project overrides drain LAST

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("options")
require("keymaps")
require("autocmds")
require("experimental")

---------------------------------------------------------------------------
-- Project-local config. Neovim sources .nvim.lua from the cwd at step 7c,
-- which is BEFORE plugins load -- so a project file cannot override plugin
-- settings directly. lua/override.lua gives it a queue that drains after
-- everything else, so the project always gets the last word.
--
-- 0.12 prompts for :trust on first sight of an untrusted file.
---------------------------------------------------------------------------
vim.o.exrc = true

---------------------------------------------------------------------------
-- Bootstrap zpack, then import every spec from lua/plugins/.
-- zpack enables vim.loader itself, so there is no explicit call here.
---------------------------------------------------------------------------
vim.pack.add({ { src = "https://github.com/zuqini/zpack.nvim" } })

require("zpack").setup({
  cmd_name = "Z", -- :Z update, :Z clean, :Z sync
  defaults = {
    lazy = false, -- eager unless a spec opts in; matches how this config reads
  },
})
