-- One repo, many modules. Replaces telescope + neo-tree + lualine +
-- bufferline + which-key + surround + autopairs + gitsigns.
--
-- Install the mini.nvim monorepo OR the standalone mini.* repos, never both.
-- The old config had both and require("mini.ai") resolved to whichever hit
-- the runtimepath first.
return {
  "nvim-mini/mini.nvim",
  lazy = false,
  config = function()
    require("mini.icons").setup()
    MiniIcons.mock_nvim_web_devicons()

    require("mini.ai").setup()
    require("mini.surround").setup()
    require("mini.pairs").setup()
    require("mini.statusline").setup()
    require("mini.diff").setup()
    require("mini.git").setup()
    require("mini.notify").setup()
    require("mini.extra").setup()
    require("mini.bracketed").setup()
    require("mini.move").setup()
    require("mini.indentscope").setup({ symbol = "|" })

    local hipatterns = require("mini.hipatterns")
    hipatterns.setup({
      highlighters = {
        hex_color = hipatterns.gen_highlighter.hex_color(),
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      },
    })

    require("mini.misc").setup()

    require("mini.pick").setup({ window = { config = { border = "rounded" } } })
    require("mini.files").setup({ windows = { preview = true, width_preview = 60 } })

    local clue = require("mini.clue")
    clue.setup({
      triggers = {
        { mode = "n", keys = "<Leader>" },
        { mode = "x", keys = "<Leader>" },
        { mode = "n", keys = "g" },
        { mode = "x", keys = "g" },
        { mode = "n", keys = "]" },
        { mode = "n", keys = "[" },
        { mode = "n", keys = "z" },
        { mode = "n", keys = '"' },
        { mode = "i", keys = "<C-r>" },
      },
      clues = {
        clue.gen_clues.builtin_completion(),
        clue.gen_clues.g(),
        clue.gen_clues.marks(),
        clue.gen_clues.registers(),
        clue.gen_clues.windows(),
        clue.gen_clues.z(),
        { mode = "n", keys = "<Leader>f", desc = "+find" },
        { mode = "n", keys = "<Leader>c", desc = "+code" },
        { mode = "n", keys = "<Leader>b", desc = "+buffer" },
        { mode = "n", keys = "<Leader>d", desc = "+debug" },
        { mode = "n", keys = "<Leader>T", desc = "+test" },
        { mode = "n", keys = "<Leader>s", desc = "+search/replace" },
        { mode = "n", keys = "<Leader>m", desc = "+multicursor" },
        { mode = "n", keys = "<Leader>p", desc = "+project" },
        { mode = "n", keys = "<Leader>g", desc = "+git/github" },
        { mode = "n", keys = "<Leader>w", desc = "+window" },
      },
      window = { config = { border = "rounded" } },
    })

    local map = vim.keymap.set
    map("n", "<leader>ff", "<cmd>Pick files<CR>", { desc = "Find files" })
    map("n", "<leader>fg", "<cmd>Pick grep_live<CR>", { desc = "Grep" })
    map("n", "<leader>fb", function()
      MiniPick.builtin.buffers({ include_current = false })
    end, { desc = "Find buffers" })
    map("n", "<leader>fh", "<cmd>Pick help<CR>", { desc = "Help" })
    map("n", "<leader>fd", "<cmd>Pick diagnostic<CR>", { desc = "Diagnostics" })
    map("n", "<leader>fr", "<cmd>Pick resume<CR>", { desc = "Resume last pick" })
    map("n", "<leader>fs", "<cmd>Pick lsp scope='document_symbol'<CR>", { desc = "Symbols" })

    map("n", "<leader>e", function()
      local path = vim.api.nvim_buf_get_name(0)
      if vim.uv.fs_stat(path) then
        MiniFiles.open(path)
      else
        MiniFiles.open()
      end
    end, { desc = "File explorer" })
  end,
}
