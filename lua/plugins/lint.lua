-- Async linting for tools that aren't language servers. Replaces the
-- none-ls / eslint extras from the old config with something far lighter.
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      markdown = { "markdownlint-cli2" },
      dockerfile = { "hadolint" },
      sh = { "shellcheck" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      svelte = { "eslint_d" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("cfg_lint", { clear = true }),
      callback = function()
        -- Missing linters are skipped rather than erroring, same spirit as
        -- the LSP server gating.
        lint.try_lint(nil, { ignore_errors = true })
      end,
    })
  end,
}
