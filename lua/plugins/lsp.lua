--- Servers you want on. Installed with your system package manager, not mason.
--- Listing one that isn't installed is harmless -- it's skipped silently.
--- Check dedicated language plugins first; see AGENTS.md.
--- To customise a server, drop a file in after/lsp/<name>.lua ("after" so it
--- wins over nvim-lspconfig's own lsp/ definition).
local servers = {
  "lua_ls", "bashls", "jsonls", "yamlls", "tombi", "marksman",
  "tsc", "svelte", "astro", "tailwindcss",
  -- rust_analyzer is owned by rustaceanvim, see lua/plugins/rust.lua
  "clangd", "zls", "gopls",
  "ty", "ruff",
  -- powershell.nvim owns powershell_es, see lua/plugins/powershell.lua
  "hls", "nushell", "vala_ls", "dartls",
  "kotlin_language_server", "omnisharp", "ruby_lsp", "metals", "nil_ls",
}

return {
  {
    -- Full type info for the Neovim Lua API. You edit this config; without it
    -- lua_ls has no idea what vim.pack or vim.lsp.config are.
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
    },
  },

  {
    -- Code actions as a single keypress instead of a numbered menu.
    "Chaitanyabsprip/fastaction.nvim",
    opts = { dismiss_keys = { "j", "k", "<c-c>", "q" } },
  },

  {
    -- In 0.12 nvim-lspconfig's only job is shipping lsp/<name>.lua files on
    -- the runtimepath. No setup() call, and deliberately no config function
    -- that could clobber anything.
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "Saghen/blink.cmp",
      "Chaitanyabsprip/fastaction.nvim",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      vim.lsp.config("*", { root_markers = { ".git" } })
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      local enabled, skipped = {}, {}
      for _, name in ipairs(servers) do
        local cfg = vim.lsp.config[name]
        local cmd = cfg and cfg.cmd
        -- A function cmd means the server launches itself; trust it.
        local exe = type(cmd) == "table" and cmd[1] or nil
        if exe == nil or vim.fn.executable(exe) == 1 then
          table.insert(enabled, name)
        else
          table.insert(skipped, name .. " (" .. exe .. ")")
        end
      end

      vim.lsp.enable(enabled)

      vim.api.nvim_create_user_command("LspSkipped", function()
        if #skipped == 0 then
          vim.notify("All configured servers found on PATH")
        else
          vim.notify("Not installed:\n  " .. table.concat(skipped, "\n  "))
        end
      end, { desc = "Servers configured but missing a binary" })
    end,
  },
}
