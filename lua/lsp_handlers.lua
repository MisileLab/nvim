--- LSP result routing.
---
--- Default behaviour on multiple results is a vim.ui.select prompt, which is
--- slow to scan. These send anything with >1 result straight to the quickfix
--- list, and jump directly when there's exactly one.
local M = {}

--- @param opts table? forwarded to the LSP request
local function on_list(opts)
  return function(list)
    local items = list.items
    if #items == 1 then
      -- Single hit: just go there, no list, no prompt.
      vim.fn.setqflist({}, " ", list)
      vim.cmd.cfirst()
    else
      vim.fn.setqflist({}, " ", list)
      vim.cmd.copen()
    end
    if opts and opts.after then
      opts.after()
    end
  end
end

local function goto_with_qf(fn)
  return function()
    fn({ on_list = on_list() })
  end
end

--- Buffer-local keymaps. Called from the LspAttach autocmd.
--- @param buf integer
function M.attach(buf)
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
  end

  -- 0.12's defaults (grr, gri, grt, grn, gra, K, gO) stay as they are; these
  -- override only the ones where quickfix routing is a clear win.
  map("grr", goto_with_qf(vim.lsp.buf.references), "References -> quickfix")
  map("gri", goto_with_qf(vim.lsp.buf.implementation), "Implementations -> quickfix")
  map("grt", goto_with_qf(vim.lsp.buf.type_definition), "Type definitions -> quickfix")
  map("gd", goto_with_qf(vim.lsp.buf.definition), "Definitions -> quickfix")

  -- fastaction replaces the numbered code-action menu with single keypresses
  if pcall(require, "fastaction") then
    vim.keymap.set({ "n", "x" }, "gra", function()
      require("fastaction").code_action()
    end, { buffer = buf, desc = "Code action (fastaction)" })
  end

  -- Workspace-wide diagnostics, new in 0.12, into the quickfix list
  map("<leader>cw", function()
    vim.diagnostic.setqflist({ open = true })
  end, "Workspace diagnostics -> quickfix")
end

return M
