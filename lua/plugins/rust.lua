-- rustaceanvim configures and owns rust_analyzer itself, so it must NOT also
-- appear in the servers table in lua/plugins/lsp.lua -- two clients would
-- attach. Successor to the archived rust-tools.nvim.
return {
  "mrcjkb/rustaceanvim",
  -- zpack needs sem_version for a semver range (plain `version` only takes an
  -- exact branch/tag/commit). Pinned to major 9 rather than tracking "*" --
  -- rustaceanvim's majors have historically carried config-breaking changes,
  -- so this stays put across patch/minor bumps and needs a manual bump (and
  -- a changelog check) whenever it falls behind again.
  sem_version = "^9",
  ft = "rust",
  init = function()
    vim.g.rustaceanvim = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = true,
            check = { command = "clippy" },
          },
        },
      },
    }
  end,
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "rust",
      group = vim.api.nvim_create_augroup("cfg_rust", { clear = true }),
      callback = function(ev)
        vim.keymap.set("n", "<leader>cR", function()
          vim.cmd.RustLsp("runnables")
        end, { buffer = ev.buf, desc = "Rust runnables" })
        vim.keymap.set("n", "<leader>dR", function()
          vim.cmd.RustLsp("debuggables")
        end, { buffer = ev.buf, desc = "Rust debuggables" })
      end,
    })
  end,
}
