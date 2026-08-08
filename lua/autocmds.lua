local function augroup(name)
  return vim.api.nvim_create_augroup("cfg_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("yank"),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("cursor"),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Treesitter highlighting + folds. In 0.12 this is core -- nvim-treesitter
-- only supplies the parsers and queries, it does not turn anything on.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter"),
  callback = function(ev)
    local ok = pcall(vim.treesitter.start, ev.buf)
    if ok then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Close throwaway buffers with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("quickclose"),
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- Trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim"),
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- LSP: buffer-local behaviour. Kept here rather than in the plugin spec so it
-- is findable, and so it applies to every client including rustaceanvim's.
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lspattach"),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    require("lsp_handlers").attach(ev.buf)

    -- Highlight other references to the symbol under the cursor
    if client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("cfg_lsphl_" .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave" }, {
        group = group,
        buffer = ev.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
        group = group,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- 0.12 renders code lens as virtual LINES rather than cramped virtual
    -- text, which makes it a real replacement for symbol-usage.nvim.
    if client:supports_method("textDocument/codeLens") then
      vim.lsp.codelens.refresh({ bufnr = ev.buf })
      vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TextChanged" }, {
        group = vim.api.nvim_create_augroup("cfg_codelens_" .. ev.buf, { clear = true }),
        buffer = ev.buf,
        callback = function()
          vim.lsp.codelens.refresh({ bufnr = ev.buf })
        end,
      })
      vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, { buffer = ev.buf, desc = "Run code lens" })
    end

    -- 0.12: renames matching HTML/JSX tags as you type, replacing nvim-ts-autotag
    if client:supports_method("textDocument/linkedEditingRange") then
      pcall(vim.lsp.linked_editing_range.enable, true, { bufnr = ev.buf })
    end

    if client:supports_method("textDocument/inlayHint") then
      vim.keymap.set("n", "<leader>ch", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
      end, { buffer = ev.buf, desc = "Toggle inlay hints" })
    end
  end,
})
