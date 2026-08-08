-- GitHub issues/PRs as editable buffers. Shells out to the `gh` CLI for
-- auth, so `gh auth login` must be done once outside Neovim.
return {
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim", -- picker backend for Octo's list views
      "nvim-mini/mini.nvim", -- mini.icons is mocked as nvim-web-devicons, see mini.lua
    },
    cmd = "Octo",
    opts = {},
    keys = {
      { "<leader>go", "<cmd>Octo<CR>", desc = "Octo actions" },
      { "<leader>gpl", "<cmd>Octo pr list<CR>", desc = "List PRs" },
      { "<leader>gpc", "<cmd>Octo pr create<CR>", desc = "Create PR" },
      { "<leader>gil", "<cmd>Octo issue list<CR>", desc = "List issues" },
      { "<leader>gic", "<cmd>Octo issue create<CR>", desc = "Create issue" },
    },
  },
}
