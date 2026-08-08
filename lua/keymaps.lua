local map = vim.keymap.set

-- Neovim 0.12 already ships LSP defaults, so they are NOT redefined here:
--   K    hover          grn  rename        gra  code action
--   grr  references     gri  implementation  grt  type definition
--   gO   document symbols            <C-s>  signature help (insert)
-- See :h lsp-defaults

-- Also NOT defined here, because 0.12 gives them to you in core:
--   visual mode  an / in    grow / shrink treesitter node selection
--                ]n / [n    next / previous sibling node
--   gx                      follow a link, incl. LSP documentLink
-- If treesitter isn't active, an/in fall back to LSP selectionRange.

-- <Esc> is owned by multicursor.nvim (clears cursors, else nohlsearch).
-- See lua/plugins/editing.lua.

-- New 0.12 commands worth a binding
map("x", "<leader>xu", ":uniq<CR>", { desc = "Deduplicate selected lines" })
map("n", "<leader>xU", ":%uniq<CR>", { desc = "Deduplicate buffer" })

-- Keep the unnamed/clipboard register clean: c, d and x write to their own
-- registers so yanked text survives a delete.
-- Delete this block if it ever feels more clever than useful.
for _, key in ipairs({ "c", "C", "d", "D", "x", "X" }) do
  local reg = '"' .. key:lower()
  map({ "n", "x" }, key, reg .. key)
end

-- Better up/down over wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>")
map("n", "<S-l>", "<cmd>bnext<CR>")
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Line moving is mini.move (<A-hjkl>), see plugin/mini.lua

-- Keep selection when indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Terminal (0.12 handles terminals much better; no plugin needed)
map("n", "<leader>t", function()
  vim.cmd("botright 15split | terminal")
  vim.cmd("startinsert")
end, { desc = "Terminal split" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })

-- Free in 0.12, no keymap needed, worth knowing:
--   an / in   expand / shrink treesitter node selection (visual mode)
--   ]n / [n   next / previous treesitter node
--   :restart  restart Neovim in place
-- :Undotree, :Diff and :restart keymaps live in plugin/experimental.lua
