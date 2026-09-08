return {
  "benomahony/uv.nvim",
  ft = "python",
  opts = {
    -- uv.nvim only has adapters for Telescope and Snacks; core uv commands
    -- and virtual-environment activation do not require either picker.
    picker_integration = false,
  },
  config = function(_, opts)
    require("uv").setup(opts)
  end,
}
