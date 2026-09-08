local o = vim.o

-- Use Nushell for :terminal, :!, filters, and other external commands.
o.shell = "nu"
o.shellcmdflag = "-c"
o.shellredir = "out+err> %s"
o.shellpipe = "out+err> %s"
o.shellquote = ""
o.shellxquote = ""

-- Indentation (carried over from your old config)
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.smartindent = true

-- UI
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.scrolloff = 8
o.splitright = true
o.splitbelow = true
o.wrap = false
o.winborder = "rounded" -- 0.12: applies to all floats, incl. LSP hover

-- Search
o.ignorecase = true
o.smartcase = true
o.inccommand = "split"

-- Files
o.undofile = true
o.swapfile = false
o.updatetime = 200
o.timeoutlen = 400

-- Clipboard
o.clipboard = "unnamedplus"

-- Completion menu behaviour. blink draws its own menu, but these govern the
-- native fallback (<C-x><C-o>, cmdline completion, and 'autocomplete' if you
-- ever drop blink entirely).
-- 'nearest' is new in 0.12: sorts candidates by proximity to the cursor.
o.completeopt = "menu,menuone,noselect,popup,nearest"
o.pumheight = 12
o.pumborder = "rounded" -- new in 0.12
o.pummaxwidth = 60 -- new in 0.12; stops long completion items eating the screen

-- Per-source match limits for native completion: 5 from the current buffer,
-- 3 from tags, plus other windows. Only relevant to the native path.
o.complete = ".^5,t^3,w"

-- Folds via treesitter, but start unfolded
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99
o.foldtext = ""

-- 0.12 statusline already renders vim.diagnostic.status() and
-- vim.ui.progress_status(); mini.statusline replaces it, but this keeps the
-- busy indicator meaningful if you ever drop back to the default.
o.laststatus = 3 -- single global statusline

vim.diagnostic.config({
  virtual_text = { current_line = true },
  severity_sort = true,
  update_in_insert = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})
