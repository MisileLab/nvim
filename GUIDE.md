# Getting started

A day-one guide for this config. Assumes you know Neovim already — this covers
what's *different*, not what `dd` does.

---

## 1. First run

```sh
mv ~/.config/nvim ~/.config/nvim.bak    # keep the old one until you're sure
cp -r nvim ~/.config/nvim
nvim
```

What happens, in order:

1. `vim.pack` clones zpack, then zpack clones everything in `lua/plugins/`.
   You'll get a confirm prompt — accept it.
2. Lots of errors scroll past. **This is expected on the first launch** —
   plugins are being installed while the config tries to use them.
3. Quit and reopen. Should be clean now.
4. `:TSUpdate` — compiles treesitter parsers. Takes a minute or two.
5. `:checkhealth` — read it top to bottom once. It's the fastest way to find
   a missing external tool.

If step 4 fails, you're missing `tree-sitter-cli`. See below.

---

## 2. Install the external tools

Nothing here uses mason, so binaries come from your package manager.

**Required:**

```
neovim (>= 0.12)  tree-sitter-cli (>= 0.26.1)  ripgrep  fd  git  gcc  curl  tar
```

`tree-sitter-cli` must come from your package manager, **not npm** — the npm
build isn't what nvim-treesitter expects.

**Language servers** — install only what you use. The config lists ~24 and
silently skips any whose binary is absent:

```
lua-language-server  bash-language-server  gopls  clangd  zls
rust-analyzer  ruff  ty  typescript>=7  tombi  marksman
```

Run `:LspSkipped` any time to see which configured servers have no binary.

**Formatters and linters** (only what you need):

```
stylua  oxfmt  oxlint  shfmt  shellcheck  hadolint  markdownlint-cli2
```

**Debug adapters** (only if you debug that language):

```
codelldb   # C, C++, Zig, Rust
delve      # Go
debugpy    # Python  (pip install debugpy)
```

**AI next-edit suggestions:**

```sh
export AIS_API_KEY=...   # in your shell rc, whatever your gateway key is
```

Without it, Minuet Duet fails quietly and you still get normal LSP completion.

---

## 3. Coming from LazyVim

This is where your muscle memory will fight you. The big shift is that
**Neovim 0.12 moved the LSP keymaps into core**, so they're `gr`-prefixed now
rather than the `<leader>c` group LazyVim used.

| LazyVim habit | Here | Note |
|---|---|---|
| `<leader>ca` code action | `gra` | core default; single-keypress menu via fastaction |
| `<leader>cr` rename | `grn` | core default |
| `gr` references | `grr` | goes to quickfix, not a picker |
| `gd` definition | `gd` | goes to quickfix, jumps directly if one result |
| `gI` implementation | `gri` | core default |
| `<leader>sg` live grep | `<leader>fg` | everything searchy is under `f` |
| `<leader>,` buffers | `<leader>fb` | |
| `<leader>e` neo-tree sidebar | `<leader>e` mini.files | **not a sidebar** — see below |
| `<leader>l` `:Lazy` | `:Z` | `:Z update`, `:Z sync`, `:Z clean` |
| `<leader>gg` lazygit | `<leader>gg` | Neogit status; `<leader>gd` remains `:Diff` |
| `<leader>xx` trouble | `<leader>fd` / `<leader>cw` | diagnostics picker / workspace → quickfix |
| `<leader>uf` toggle autoformat | — | format-on-save is off; `<leader>cf` is explicit |

**mini.files is not neo-tree.** It's a transient floating explorer, and it
works like a *buffer*: navigate with `h`/`l`, and to create/rename/delete
files you literally edit the text and press `=` to apply. `q` closes it.
It opens at your current file rather than the project root.

**Two things will annoy you on day one:**

- **hardtime** blocks repeated `j`/`k`/`h`/`l` and nags. That's the point, but
  if you're mid-task and just want to move: `:Hardtime toggle`.
- **`ui2`** makes the cmdline behave differently and sets `cmdheight=0`. If it
  feels wrong, delete the top block of `lua/experimental.lua` — it's isolated
  there on purpose.

---

## 4. The daily loop

**Finding things** — `<leader>` then `f`, and `mini.clue` will show you the
rest. Inside a picker: `<C-n>`/`<C-p>` to move, `<CR>` to open, `<C-s>`/`<C-v>`
for splits, `<Esc>` to bail.

**Moving in a file** — `s` + two characters puts labels on every match; hit a
label to jump. Works after an operator too, so `ds<label>` deletes from here
to there. `S` labels treesitter nodes instead.

**Multiple cursors** — `<C-Down>` stacks a cursor on the line below.
`<leader>mn` adds one at the next occurrence of the word under the cursor
(`<leader>ms` skips one), `<leader>mA` grabs every occurrence at once. Then
just edit normally. `<Esc>` clears them.

**Selecting code structurally** — in visual mode, `an` expands the selection
to the enclosing treesitter node, `in` shrinks it back. No plugin; this is
core 0.12. Great for grabbing a whole function or a nested block.

**Formatting** — `<leader>cf`. It never runs on save.

**Git** — `mini.diff` shows hunks in the gutter. `<leader>gd` opens `:Diff`.
Hunk textobjects come from mini.diff; `]h`/`[h` via mini.bracketed. Neogit is
the interactive repository UI: `<leader>gg` opens status, `<leader>gc` opens
the commit popup, and `<leader>gl` opens history.

---

## 5. Picking up a new language

First search for a dedicated Neovim language plugin, then check maintenance,
compatibility, and usability as described in `AGENTS.md`. Prefer a maintained,
usable plugin and let it own its server. If none qualifies, use the direct LSP
setup below, with Gleam as an example:

```sh
# 1. install the server however your distro provides it
paru -S gleam
```

```lua
-- 2. lua/plugins/lsp.lua -- add to the servers list
local servers = {
  ...
  "gleam",
}
```

```
:TSInstall gleam        -- 3. parser for highlighting
:restart                -- 4. reload
```

That's it. If the server needs settings, make `after/lsp/gleam.lua`:

```lua
return {
  settings = { ... },
}
```

`after/` beats nvim-lspconfig's own `lsp/` directory on the runtimepath, so
your file merges on top of theirs rather than replacing it.

Add a formatter in `lua/plugins/format.lua`, a linter in `lua/plugins/lint.lua`.

---

## 6. Per-project settings

```sh
cp ~/.config/nvim/templates/.nvim.lua ~/code/myproject/.nvim.lua
```

Open the project — Neovim asks you to `:trust` the file once. Then:

```lua
-- plain options work immediately
vim.o.tabstop = 4

-- anything touching a plugin must be deferred, because this file runs
-- BEFORE plugins load
require("override").on_load(function()
  require("conform").formatters_by_ft.python = { "black" }
  vim.keymap.set("n", "<leader>pr", "<cmd>!make run<CR>", { desc = "Run" })
end)
```

Commit it. Anyone else using this config gets the same project setup.

---

## 7. Debugging and tests

**Debug:** `<leader>db` on a line to set a breakpoint, `<leader>dc` to start.
The UI opens by itself and closes when the session ends. `<leader>do` steps
over, `<leader>di` into, `<leader>de` evaluates the expression under the
cursor. `<leader>dt` terminates.

For Rust, use `<leader>dR` instead — rustaceanvim builds the debug target for
you rather than making you point at a binary.

**Test:** `<leader>Tr` runs the test under the cursor, `<leader>Td` runs it
under the debugger, `<leader>Ts` opens the summary tree. Results show as
virtual text next to each test.

---

## 8. Updating

```
:Z update      # confirm buffer: K for details, gra to skip one, :w to apply
:Z restore     # everything back to the lockfile
:Z clean       # drop plugins no longer in a spec
```

Commit `nvim-pack-lock.json` after an update you're happy with. On another
machine: pull, `:restart`, then `:Z restore` to match revisions exactly.

---

## 9. When something breaks

| Symptom | Check |
|---|---|
| No completion / no `gr*` keymaps | `:lsp` — is a client attached? then `:LspSkipped` |
| Server won't start | `:checkhealth vim.lsp`, then `:lsp` for status |
| No highlighting | `:TSUpdate`, then `:checkhealth vim.treesitter` |
| No AI ghost text | is `AIS_API_KEY` exported? `:Minuet change_model` to test |
| Ghost text flickers | something else is writing virtual text — check for a second AI source |
| A plugin didn't load | `:Z load <name>`, or `:Z` to inspect |
| Everything is broken | `:Z restore`, `:restart` |

`:messages` for anything that scrolled past, and `:checkhealth` is worth
re-reading whenever you add a language.

---

## 10. Making it yours

- **A keymap** → `lua/keymaps.lua`, unless it belongs to a plugin, in which
  case the `keys` table of that plugin's spec.
- **An option** → `lua/options.lua`.
- **A new plugin** → a new file in `lua/plugins/` returning a spec. zpack takes
  lazy.nvim's format, so you can usually paste the README snippet verbatim.
- **Remove something** → delete its file in `lua/plugins/`, then `:Z clean`.

Two things worth not touching without reading the comment first: `blink.cmp`
is `lazy = false` because it registers LSP capabilities before servers enable,
and `rust_analyzer` is deliberately missing from the `servers` list because
rustaceanvim owns it.
