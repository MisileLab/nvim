-- Neovim 0.12 features that are new, experimental, or not on by default.
-- Everything here is guarded: these are the parts of core most likely to move
-- under you, and none of them should be able to break startup.

-- ui2: experimental redesign of the messages and cmdline UI. The closest thing
-- core has to noice.nvim. Delete this block if it misbehaves.
local ok, ui2 = pcall(require, "vim._core.ui2")
if ok and pcall(ui2.enable) then
  vim.o.cmdheight = 0
end

-- Built-in plugins shipped with 0.12. Guarded on the command existing.
local function if_command(name, fn)
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if vim.fn.exists(":" .. name) == 2 then
        fn()
      end
    end,
  })
end

if_command("Undotree", function()
  vim.keymap.set("n", "<leader>u", "<cmd>Undotree<CR>", { desc = "Undo tree" })
end)

if_command("Diff", function()
  vim.keymap.set("n", "<leader>gd", "<cmd>Diff<CR>", { desc = "Diff" })
end)

vim.keymap.set("n", "<leader>R", "<cmd>restart<CR>", { desc = "Restart Neovim" })
