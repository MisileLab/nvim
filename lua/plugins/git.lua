-- Interactive repository UI for staging, history, commits, branches, and
-- remote operations. mini.diff still owns gutter signs and hunk operations;
-- mini.git still provides :Git for direct CLI commands.
return {
  "NeogitOrg/neogit",
  cmd = "Neogit",
  opts = {
    kind = "tab",
    integrations = {
      diffview = false,
      telescope = false,
    },
  },
  keys = {
    { "<leader>gg", "<cmd>Neogit<CR>", desc = "Git status" },
    { "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Git commit" },
    { "<leader>gl", "<cmd>Neogit log<CR>", desc = "Git history" },
  },
}
