-- PlatformIO wrapper. Lazy-loaded on its own commands rather than eager, since
-- it's only relevant inside embedded/PlatformIO projects.
--
-- Pulls in telescope + which-key even though mini.nvim already covers pickers
-- and the leader menu -- nvim-platformio hard-requires them itself (its own
-- minimal test config lists the same deps), so they're not optional here.
--
-- Requires the `platformio` CLI on PATH (pipx install platformio), same as
-- every other tool in this config: not mason-managed.
return {
  "anurag3301/nvim-platformio.lua",
  cmd = { "Pioinit", "Piorun", "Piocmdh", "Piocmdf", "Piolib", "Piomon", "Piodebug", "Piodb" },
  dependencies = {
    "akinsho/toggleterm.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-lua/plenary.nvim",
    "folke/which-key.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    vim.g.pioConfig = {
      lsp = "clangd", -- or "ccls"
      clangd_source = "ccls", -- or "compiledb"
      picker_backend = "auto",
      menu_key = "<leader>\\",
      debug = false,
    }
    local pok, platformio = pcall(require, "platformio")
    if pok then
      platformio.setup(vim.g.pioConfig)
    end
  end,
}
