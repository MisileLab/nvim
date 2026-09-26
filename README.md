# nvim

Neovim 0.12+ config on **zpack.nvim** — a thin layer over the native `vim.pack`
that adds lazy-loading and lazy.nvim-shaped specs. Installation, updates,
lockfile and version pinning are all still `vim.pack` underneath.

## Install

```sh
mv ~/.config/nvim ~/.config/nvim.bak
cp -r nvim ~/.config/nvim
nvim   # zpack bootstraps itself via vim.pack, then clones everything
```

Then `:TSUpdate`, restart, `:checkhealth`.

## Requirements

| Thing | Why |
|---|---|
| Neovim >= 0.12.0 | `vim.pack`, native LSP, core treesitter, zpack |
| `tree-sitter-cli` >= 0.26.1 | parser compilation — **package manager, not npm** |
| C compiler, `curl`, `tar` | parser builds |
| `ripgrep` | `mini.pick` live grep |
| Nerd Font | icons |
| `stylua`, `oxfmt`, … | only the formatters you use |

## Layout

```
init.lua                leader, options/keymaps/autocmds, exrc, zpack bootstrap
lua/options.lua         editor settings + diagnostic config
lua/keymaps.lua         non-LSP, non-plugin keymaps
lua/autocmds.lua        yank highlight, treesitter start, LspAttach behaviour
lua/experimental.lua    0.12 features that are new or off by default
lua/lsp_handlers.lua    LSP result routing (references -> quickfix)
lua/override.lua        deferred queue for project-local .nvim.lua
lua/plugins/*.lua       one file per concern, each returns a zpack spec
after/lsp/<name>.lua    per-server LSP overrides
templates/.nvim.lua     copy into a project root
```

## Managing plugins

```
:Z update       confirm buffer; :w applies, :q discards
:Z restore      roll everything back to the lockfile
:Z clean        remove plugins no longer in a spec
:Z sync         update + clean
:Z build <p>    re-run a build hook
```

Commit `nvim-pack-lock.json` to pin revisions across machines.

## Project-local config (`exrc`)

Drop a `.nvim.lua` in a project root (start from `templates/.nvim.lua`).
Neovim sources it at startup and prompts you to `:trust` it once.

The catch it solves: exrc runs *before* plugins load, so a project file can't
reach into plugin config directly. `lua/override.lua` gives it a queue that
drains after everything else:

```lua
require("override").on_load(function()
  require("conform").formatters_by_ft.python = { "black" }
  vim.lsp.config.gopls.settings = { gopls = { analyses = { ST1000 = false } } }
end)
```

Plain options (`vim.o.tabstop = 4`) need no deferral. Note that exrc walks
upward from cwd to `$HOME`, so a nested `.nvim.lua` is sourced *before* its
parent — both run, in that order.

## AI next-edit suggestions

Minuet Duet previews next-edit suggestions as a diff through your
OpenAI-compatible gateway. Other Minuet completion modes are disabled:

```sh
export AIS_API_KEY=...
```

Endpoint and model are at the top of `lua/plugins/completion.lua`.

Predictions are requested automatically 1500ms after edits settle:

| Key | Does |
|---|---|
| `<A-y>` | request a prediction now |
| `<Tab>` / `<A-a>` | apply the visible prediction |
| `<A-e>` | dismiss the prediction |

`:MinuetDuetAutoToggle` toggles the debounced automatic duet prediction.

## Adding a language

1. Search for a dedicated Neovim language plugin and check its maintenance,
   compatibility, and usability (see `AGENTS.md`). Prefer a usable, maintained plugin.
2. If none exists or available plugins are unmaintained or unusable, install
   the server and add its lspconfig name to `servers` in `lua/plugins/lsp.lua`.
   Do not also enable servers owned by a language plugin.
3. `:TSInstall <lang>` (or add it to `lua/plugins/treesitter.lua`).
4. Formatter in `lua/plugins/format.lua`, linter in `lua/plugins/lint.lua`.

Servers with no binary on `PATH` are skipped silently — list things
speculatively. `:LspSkipped` shows what's missing. Per-server tweaks go in
`after/lsp/<name>.lua`; `after/` wins over lspconfig's own `lsp/`.

### PowerShell

`.ps1`, `.psm1`, and `.psd1` files load
[powershell.nvim](https://github.com/TheLeoP/powershell.nvim), which owns the
language server, extension terminal, evaluation, and PowerShell debug adapter.
The `powershell` parser supplies highlighting, folds, and indentation.

Install PowerShell (`pwsh` on `PATH`), then extract
[PowerShellEditorServices.zip](https://github.com/PowerShell/PowerShellEditorServices/releases)
into `stdpath("data") .. "/powershell-editor-services"`. On a default macOS/Linux
install, the resulting script path is:

```text
~/.local/share/nvim/powershell-editor-services/PowerShellEditorServices/Start-EditorServices.ps1
```

For another location, change `bundle_path` in `lua/plugins/powershell.lua`.
Restart Neovim to install the plugin and parser, then open a PowerShell file.
`<leader>cf` formats through LSP; `<leader>dc` opens the plugin's debug choices.
`:lua require("powershell").toggle_term()` toggles the extension terminal;
`:lua require("powershell").eval()` evaluates the current line.
The plugin manages its own server, so it is not listed by `:LspSkipped`.

## Keymaps

Leader is `<Space>`; `mini.clue` shows the rest as you type.

| Key | Does |
|---|---|
| `<leader>ff` / `fg` / `fb` | files / grep / buffers |
| `<leader>e` | file explorer |
| `<leader>bn` / `bp` / `bd` | next / previous / delete buffer |
| `<leader>wh` / `wv` | split horizontally / vertically |
| `<leader>we` / `wc` | equalize / close windows |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | focus window left / down / up / right |
| `<leader>ww` | focus next window |
| `<leader>cf` / `cl` / `ch` | format / run code lens / inlay hints |
| `<leader>cw` | workspace diagnostics → quickfix |
| `<leader>sr` / `sw` | project find & replace |
| `<leader>db` / `dc` | breakpoint / continue |
| `<leader>Tr` / `Td` | run / debug nearest test |
| `<leader>gg` / `gc` / `gl` | Git status / commit / history (Neogit) |
| `<leader>gh` | GitHub actions (Octo) |
| `<C-Down>` / `<C-Up>` | add cursor below / above |
| `<leader>mn` / `mA` | cursor at next match / all matches |
| `s` / `S` | flash / flash treesitter |
| `<leader>u` / `<leader>R` | undo tree / restart Neovim |
| `grr` `gri` `grt` `gd` | LSP results → quickfix |
| `gra` | code action (fastaction, single keypress) |

`c`, `d`, `x` write to their own registers so a delete never clobbers your
yank. `<Esc>` clears multicursors first, then search highlight.

## What core 0.12 replaced

| Was | Now |
|---|---|
| `symbol-usage.nvim` | code lens as virtual **lines** |
| `nvim-ts-autotag` | LSP `linkedEditingRange` |
| `vim-illuminate` | LSP `documentHighlight` |
| `noice.nvim` | `ui2` (experimental) |
| `undotree`, part of `diffview` | `:Undotree`, `:Diff` |
| treesitter textobjects incremental select | `an` / `in` / `]n` / `[n` |
| `telescope` **and** `snacks_picker` (both!) | `mini.pick` |
| `indent-blankline` + `mini-indentscope` (both!) | `mini.indentscope` |
| `neo-tree` | `mini.files` |
| `lualine` + `bufferline` | `mini.statusline`, `laststatus=3` |
| `none-ls` lint extras | `nvim-lint` |
| `toggleterm` | `<leader>t` |
| `impatient` | `vim.loader` (zpack enables it) |
| project config plugins | `exrc` + `lua/override.lua` |

## Deliberate choices

- **blink.cmp is `lazy = false`.** It registers LSP capabilities, which must
  happen before any server is enabled. Deferring it to `InsertEnter` means
  servers attach without completion capabilities — the same class of silent
  breakage as the old config's `config` function on `nvim-lspconfig`.
- **`rustaceanvim` owns `rust_analyzer`**, so it's deliberately absent from the
  `servers` list. Two clients attaching is the classic bug here.
- **`mini.nvim` monorepo only.** Never the standalone `mini.*` repos alongside.
- **No mason.** System package manager, for servers, formatters, linters and
  DAP adapters alike. Everything is gated on the binary existing.
- **Format-on-save off.** Explicit `<leader>cf`; override per project.
- **`ui2` and `vim.pack` are experimental.** `ui2` is one guarded block in
  `lua/experimental.lua`; zpack keeps `vim.pack` semantics underneath.
- **blink pinned to `1.*`.** Bump to `2.*` when you want to read the changelog.
