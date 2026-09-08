-- nvim-treesitter `main` installs parsers and ships queries; that is all.
-- Highlighting/folds/indent are turned on by the FileType autocmd in
-- lua/autocmds.lua. It explicitly does not support lazy-loading.
--
-- Requires tree-sitter-cli >= 0.26.1 from your package manager (NOT npm).
return {
  "nvim-treesitter/nvim-treesitter",
  version = "main",
  lazy = false,
  build = function()
    vim.cmd("TSUpdate")
  end,
  config = function()
    require("nvim-treesitter").install({
      "bash", "c", "cpp", "css", "diff", "git_config", "git_rebase", "gitcommit",
      "go", "html", "javascript", "json", "lua", "luadoc", "markdown",
      "markdown_inline", "python", "query", "regex", "rust", "svelte", "toml",
      "tsx", "typescript", "vim", "vimdoc", "yaml", "zig",
    })
  end,
}
