local ENDPOINT = "https://ais.misile.xyz/v1/chat/completions"
local MODEL = "gpt-6-luna"
local API_KEY_ENV = "AIS_API_KEY"
local DUET_AUTO_DELAY = 1500

local function setup_duet_auto()
  local duet = require("minuet.duet")
  local group = vim.api.nvim_create_augroup("cfg_minuet_duet_auto", { clear = true })
  local state = {
    enabled = true,
    generation = 0,
    in_flight = false,
    dirty = false,
  }

  local ignored_filetypes = {
    gitcommit = true,
    markdown = true,
    text = true,
  }

  local function eligible(buf)
    if not state.enabled or buf ~= vim.api.nvim_get_current_buf() then
      return false
    end

    local bo = vim.bo[buf]
    local name = vim.api.nvim_buf_get_name(buf)
    local tail = vim.fn.fnamemodify(name, ":t")
    return bo.buftype == ""
      and bo.modifiable
      and not bo.readonly
      and not ignored_filetypes[bo.filetype]
      and tail ~= ".env"
      and not vim.startswith(tail, ".env.")
  end

  local schedule
  schedule = function(buf)
    state.generation = state.generation + 1
    local generation = state.generation

    vim.defer_fn(function()
      if generation ~= state.generation or not vim.api.nvim_buf_is_valid(buf) or not eligible(buf) then
        return
      end
      if state.in_flight then
        state.dirty = true
        return
      end

      state.in_flight = true
      state.dirty = false
      local ok, err = pcall(duet.action.predict)
      if not ok then
        state.in_flight = false
        vim.notify("Minuet duet auto prediction failed: " .. err, vim.log.levels.ERROR)
      end
    end, DUET_AUTO_DELAY)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = group,
    callback = function(ev)
      schedule(ev.buf)
    end,
    desc = "Automatically request a Minuet duet prediction after edits settle",
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MinuetDuetRequestStarted",
    callback = function()
      -- This also observes predictions started manually via <A-y>.
      state.in_flight = true
    end,
    desc = "Track active Minuet duet requests",
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MinuetDuetRequestFinished",
    callback = function()
      state.in_flight = false
      if state.dirty then
        state.dirty = false
        schedule(vim.api.nvim_get_current_buf())
      end
    end,
    desc = "Continue Minuet duet auto prediction after an in-flight request",
  })

  vim.api.nvim_create_user_command("MinuetDuetAutoToggle", function()
    state.enabled = not state.enabled
    state.generation = state.generation + 1
    state.dirty = false
    if not state.enabled then
      duet.action.dismiss()
    end
    vim.notify("Minuet duet auto: " .. (state.enabled and "on" or "off"))
  end, { desc = "Toggle automatic Minuet duet prediction" })

  vim.keymap.set({ "n", "i" }, "<A-y>", duet.action.predict, { desc = "Minuet duet: predict" })
  vim.keymap.set({ "n", "i" }, "<A-a>", duet.action.apply, { desc = "Minuet duet: apply" })
  vim.keymap.set({ "n", "i" }, "<A-e>", duet.action.dismiss, { desc = "Minuet duet: dismiss" })
  vim.keymap.set("i", "<Tab>", function()
    if duet.action.is_visible() then
      duet.action.apply()
    elseif vim.snippet.active({ direction = 1 }) then
      vim.snippet.jump(1)
    else
      -- Feed an unmapped Tab so this mapping cannot call itself recursively.
      vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
    end
  end, { desc = "Apply Minuet duet, jump snippet, or insert Tab" })
end

return {
  {
    -- Minuet's duet frontend predicts the next edit and previews it as a diff.
    -- Upstream only exposes manual prediction, so setup_duet_auto() adds a
    -- debounced automatic trigger without patching the plugin itself.
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    opts = {
      provider = "openai_compatible",
      request_timeout = 8,
      throttle = 1500,
      debounce = 600,
      notify = "warn",
      provider_options = {
        openai_compatible = {
          name = "ais",
          end_point = ENDPOINT,
          model = MODEL,
          api_key = API_KEY_ENV, -- the NAME of the env var, not the value
          stream = true,
          optional = { max_tokens = 512 },
        },
      },
      virtualtext = { auto_trigger_ft = {} },
      duet = {
        provider = "openai_compatible",
        request_timeout = 15,
        recent_edits = { enabled = true },
        provider_options = {
          openai_compatible = {
            name = "ais",
            end_point = ENDPOINT,
            model = MODEL,
            api_key = API_KEY_ENV,
            -- Duet rewrites a whole editable region; a small max_tokens value
            -- makes otherwise valid responses get truncated and rejected.
            optional = {},
          },
        },
      },
    },
    config = function(_, opts)
      require("minuet").setup(opts)
      setup_duet_auto()
    end,
  },

  {
    -- blink owns ordinary LSP/path/snippet/buffer completion. Minuet is kept
    -- out of the completion menu so Duet is its only active suggestion mode.
    "Saghen/blink.cmp",
    sem_version = "1.*",
    -- NOT lazy. It registers LSP capabilities, which must happen before any
    -- server is enabled. Deferring this to InsertEnter means servers attach
    -- without completion capabilities -- exactly the silent breakage that was
    -- in the old config.
    lazy = false,
    opts = {
      keymap = {
        preset = "default",
        -- Accept the selected completion with Enter. If nothing has been
        -- selected yet, accept the first candidate; otherwise keep Enter's
        -- normal newline behaviour when the completion menu is closed.
        ["<CR>"] = { "select_and_accept", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        -- Avoid sending an LLM request merely because Insert mode started.
        trigger = { prefetch_on_insert = false },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    config = function(_, opts)
      require("blink.cmp").setup(opts)
      -- Hand blink's capabilities to every server. In a distro this happens
      -- invisibly; here it is one explicit line you can actually find.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(nil, false),
      })
    end,
  },
}
