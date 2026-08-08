return {
  {
    -- Treesitter-aware jump labels. The operator-pending integration is the
    -- part that actually changes how you edit.
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = true } } },
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
      { "r", function() require("flash").remote() end, mode = "o", desc = "Remote flash" },
    },
  },

  {
    -- Real multiple cursors, not macro replay: every cursor edits live.
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local map = vim.keymap.set
      map({ "n", "x" }, "<C-Down>", function() mc.lineAddCursor(1) end, { desc = "Cursor below" })
      map({ "n", "x" }, "<C-Up>", function() mc.lineAddCursor(-1) end, { desc = "Cursor above" })
      map({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "Add cursor at next match" })
      map({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "Skip this match" })
      map({ "n", "x" }, "<leader>mA", mc.matchAllAddCursors, { desc = "Cursor on every match" })
      map("x", "<leader>mi", mc.insertVisual, { desc = "Insert on each line" })
      map("x", "<leader>ma", mc.appendVisual, { desc = "Append on each line" })

      -- Esc clears cursors instead of leaving them stranded
      map("n", "<Esc>", function()
        if mc.hasCursors() then
          mc.clearCursors()
        else
          vim.cmd("nohlsearch")
        end
      end, { desc = "Clear cursors / highlight" })

      mc.addKeymapLayer(function(layer)
        layer({ "n", "x" }, "<left>", mc.prevCursor)
        layer({ "n", "x" }, "<right>", mc.nextCursor)
        layer("n", "<C-c>", mc.clearCursors)
      end)
    end,
  },

  {
    -- <C-a>/<C-x> on dates, booleans, semver, hex -- not just integers.
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>", function() require("dial.map").manipulate("increment", "normal") end, mode = "n" },
      { "<C-x>", function() require("dial.map").manipulate("decrement", "normal") end, mode = "n" },
      { "<C-a>", function() require("dial.map").manipulate("increment", "visual") end, mode = "x" },
      { "<C-x>", function() require("dial.map").manipulate("decrement", "visual") end, mode = "x" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal_int,
          augend.integer.alias.hex,
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%H:%M"],
          augend.semver.alias.semver,
          augend.constant.alias.bool,
          augend.constant.new({ elements = { "and", "or" }, word = true }),
          augend.constant.new({ elements = { "&&", "||" }, word = false }),
        },
      })
    end,
  },

  {
    -- Project-wide find & replace in a live preview buffer.
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      {
        "<leader>sr",
        function() require("grug-far").open({ transient = true }) end,
        desc = "Search & replace (project)",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ transient = true, prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Replace word under cursor",
      },
    },
  },
}
