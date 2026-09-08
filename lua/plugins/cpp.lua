return {
  "DanielMSussman/simpleCppTreesitterTools.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = "cpp",
  config = function()
    local cpp_tools = require("simpleCppTreesitterTools")
    local cpp_module = require("simpleCppTreesitterTools.cppModule")
    local file_helpers = require("simpleCppTreesitterTools.fileHelpers")
    local cpp_stubs = require("cpp_stubs")

    cpp_tools.setup({
      headerExtension = ".hpp",
      implementationExtension = ".cpp",
      verboseNotifications = false,
      tryToPlaceImplementationInOrder = true,
    })

    -- Upstream currently hardcodes `.h` when resolving the implementation
    -- path. Keep its implementation logic, but correctly pair foo.hpp with
    -- foo.cpp until that bug is fixed upstream.
    cpp_tools.setCurrentFiles = function()
      local header = vim.api.nvim_buf_get_name(0)
      local implementation = header:gsub("%.hpp$", ".cpp")

      cpp_tools.data.headerFile = header
      cpp_tools.data.implementationFile = implementation
      cpp_module.data = cpp_tools.data
      file_helpers.createIncludingFileIfItDoesNotExist(implementation)
    end

    -- The upstream refresh command passes a filename to :checktime, which
    -- Neovim treats as a buffer pattern and can reject for canonicalized paths.
    file_helpers.refreshImplementationBuffer = function(implementation)
      local bufnr = vim.fn.bufnr(vim.fn.fnamemodify(implementation, ":p"))
      if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) and not vim.bo[bufnr].modified then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd.checktime()
        end)
      end
    end

    local group = vim.api.nvim_create_augroup("cfg_cpp_stubs", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      pattern = "*.hpp",
      desc = "Add missing C++ definitions to the matching source file",
      callback = function(ev)
        local header = vim.api.nvim_buf_get_name(ev.buf)
        local implementation = header:gsub("%.hpp$", ".cpp")
        local implementation_buf = vim.fn.bufnr(implementation)

        -- The plugin edits the source file directly. Do not let an automatic
        -- run race with source changes that exist only in an open buffer.
        if implementation_buf ~= -1 and vim.bo[implementation_buf].modified then
          local source_name = vim.fn.fnamemodify(implementation, ":t")
          vim.notify("C++ stubs skipped: save " .. source_name .. " first", vim.log.levels.WARN)
          return
        end

        -- The plugin finds the enclosing class from the window cursor, so run
        -- in the buffer's real window rather than a temporary buffer context.
        local win = vim.fn.bufwinid(ev.buf)
        if win == -1 then
          return
        end
        vim.api.nvim_win_call(win, function()
          local ok, err = pcall(function()
            -- A newly opened header may not have completed its first parse by
            -- the time it is saved. The plugin needs a current syntax node.
            vim.treesitter.get_parser(ev.buf, "cpp"):parse()
            cpp_tools.implementMembersInClass()
            cpp_stubs.add_free_functions(ev.buf, implementation)
          end)
          if not ok then
            vim.notify("C++ stub generation failed: " .. err, vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end,
}
