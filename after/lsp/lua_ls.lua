-- Example of a per-server override. "after/lsp/" beats nvim-lspconfig's
-- "lsp/" on the runtimepath, so this merges on top of its definition.
return {
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      codeLens = { enable = true },
      hint = { enable = true, arrayIndex = "Disable" },
      format = { enable = false }, -- stylua via conform instead
    },
  },
}
