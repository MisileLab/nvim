--- Deferred override queue for project-local .nvim.lua files.
---
--- exrc runs at step 7c, before any plugin has loaded. Anything a project
--- wants to override -- a formatter, an LSP setting, a keymap -- has to wait
--- until after plugin setup. This queue drains on VimEnter via vim.schedule,
--- which is FIFO, so it lands after zpack's own deferred work.
---
--- Gotcha worth knowing: exrc walks upward from cwd to $HOME, so a .nvim.lua
--- in a subdirectory is sourced BEFORE one in a parent. Both get queued here,
--- and both run -- in that same order.
---
--- Usage in a project's .nvim.lua:
---
---   require("override").on_load(function()
---     require("conform").formatters_by_ft.python = { "black" }
---     vim.lsp.config.gopls.settings = { gopls = { analyses = { ST1000 = false } } }
---   end)
local M = {}

local queue = {}

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  group = vim.api.nvim_create_augroup("cfg_override", { clear = true }),
  callback = function()
    for _, fn in ipairs(queue) do
      vim.schedule(function()
        local ok, err = pcall(fn)
        if not ok then
          vim.notify(".nvim.lua override failed:\n" .. tostring(err), vim.log.levels.ERROR)
        end
      end)
    end
    queue = nil
  end,
})

--- Run fn after all plugins have been set up.
---@param fn function
function M.on_load(fn)
  if queue then
    table.insert(queue, fn)
  else
    -- VimEnter already fired (e.g. :source'd by hand) -- just run it
    vim.schedule(fn)
  end
end

return M
