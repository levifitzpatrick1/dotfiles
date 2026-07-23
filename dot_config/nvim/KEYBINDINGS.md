# Neovim Cheatsheet

**Leader Key:** `<Space>`

---

## Getting Started (if you've never used vim/nvim)

Neovim is a **modal** editor: the same keys do different things depending on
what mode you're in.

- **Normal mode** — the default. Keys are commands, not text (`x` deletes a
  character, `dd` deletes a line). You land here on startup and after
  pressing `Esc`.
- **Insert mode** — actually typing text, like a normal editor. Enter it with
  `i` (insert before cursor) or `a` (after cursor). Leave it with `Esc` (or
  `jk`, mapped below).
- **Visual mode** — for selecting text. Enter with `v` (character-wise) or
  `V` (line-wise).
- **Command mode** — type `:` then a command, e.g. `:w` (save), `:q` (quit),
  `:wq` (save and quit).

Day-one workflow: open a file, `i` to type, `Esc` when done typing, `:w` to
save. Everything else below builds on that.

Every custom shortcut in this config starts with the **leader key**
(`<Space>`). Press it and wait a second — a popup (which-key) shows every
key you can press next, grouped and labeled. You don't need to memorize this
file; when in doubt, press `<Space>` and read the menu.

---

## General

| Key | Mode | Description |
|-----|------|-------------|
| `jk` | Insert | Exit insert mode |
| `<leader>nh` | Normal | Clear search highlights |
| `<leader>+` | Normal | Increment number |
| `<leader>-` | Normal | Decrement number |

---

## Window Management

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>sv` | Normal | Split window vertically |
| `<leader>sh` | Normal | Split window horizontally |
| `<leader>se` | Normal | Make splits equal size |
| `<leader>sx` | Normal | Close current split |
| `<C-h>` | Normal | Move to left split |
| `<C-j>` | Normal | Move to bottom split |
| `<C-k>` | Normal | Move to top split |
| `<C-l>` | Normal | Move to right split |

---

## Tab Management

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>to` | Normal | Open new tab |
| `<leader>tx` | Normal | Close current tab |
| `<leader>tn` | Normal | Go to next tab |
| `<leader>tp` | Normal | Go to previous tab |
| `<leader>tf` | Normal | Open current buffer in new tab |

---

## Buffer Management

| Key | Mode | Description |
|-----|------|-------------|
| `<Tab>` | Normal | Next buffer |
| `<S-Tab>` | Normal | Previous buffer |
| `<leader>x` | Normal | Close buffer |
| `<leader>fb` | Normal | Find/switch buffer (Telescope) |
| `<leader>bh` | Normal | Go to home screen (dashboard) |

---

## File Explorer (NvimTree)

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>e` | Normal | Toggle file explorer |
| `<leader>ef` | Normal | Find current file in explorer |

---

## Telescope (Fuzzy Finder)

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>ff` | Normal | Fuzzy find files in cwd |
| `<leader>fr` | Normal | Fuzzy find recent files |
| `<leader>fs` | Normal | Find string in cwd (live grep) |
| `<leader>fc` | Normal | Find string under cursor in cwd |
| `<leader>fb` | Normal | Find open buffers |

---

## LSP (Language Server Protocol)

Language servers give you go-to-definition, autocomplete, diagnostics, etc.
Mason installs them automatically the first time you open a matching
filetype — no setup needed per language.

| Key | Mode | Description |
|-----|------|-------------|
| `gd` | Normal | Go to definition |
| `gD` | Normal | Go to declaration |
| `gi` | Normal | Go to implementation |
| `gr` | Normal | Show references |
| `K` | Normal | Show hover documentation |
| `<leader>ca` | Normal | Code actions |
| `<leader>rn` | Normal | Rename symbol |
| `<leader>d` | Normal | Show line diagnostics |
| `[d` | Normal | Go to previous diagnostic |
| `]d` | Normal | Go to next diagnostic |

---

## Autocompletion (nvim-cmp)

| Key | Mode | Description |
|-----|------|-------------|
| `<C-k>` | Insert | Select previous item |
| `<C-j>` | Insert | Select next item |
| `<C-b>` | Insert | Scroll docs up |
| `<C-f>` | Insert | Scroll docs down |
| `<C-Space>` | Insert | Show completion menu |
| `<C-e>` | Insert | Close completion menu |
| `<CR>` | Insert | Confirm completion |

---

## Git (Gitsigns)

| Key | Mode | Description |
|-----|------|-------------|
| `]c` | Normal | Next git hunk |
| `[c` | Normal | Previous git hunk |
| `<leader>hs` | Normal/Visual | Stage hunk |
| `<leader>hr` | Normal/Visual | Reset hunk |
| `<leader>hS` | Normal | Stage buffer |
| `<leader>hu` | Normal | Undo stage hunk |
| `<leader>hR` | Normal | Reset buffer |
| `<leader>hp` | Normal | Preview hunk |
| `<leader>hb` | Normal | Blame line |
| `<leader>hd` | Normal | Diff this |
| `<leader>hD` | Normal | Diff this ~ |
| `<leader>tb` | Normal | Toggle line blame |
| `<leader>td` | Normal | Toggle deleted |

---

## Comments

| Key | Mode | Description |
|-----|------|-------------|
| `gc` | Normal/Visual | Comment toggle linewise |
| `gb` | Normal/Visual | Comment toggle blockwise |

**Examples:**
- `gcc` - Toggle comment on current line
- `gc5j` - Comment 5 lines down
- `gcip` - Comment inside paragraph

---

## Commands

| Command | Description |
|---------|-------------|
| `:Mason` | Open Mason (LSP installer) |
| `:Lazy` | Open Lazy plugin manager |
| `:checkhealth` | Check Neovim health |
| `:Telescope` | Open Telescope picker |
| `:TSInstall <lang>` | Install a treesitter parser for a language not in the default set |

---

## Tips

1. **Which-key popup:** Press `<Space>` and wait a second to see available keybindings.
2. **Leader key groups:**
   - `<leader>f` - Find (Telescope)
   - `<leader>e` - Explorer
   - `<leader>h` - Git Hunk
   - `<leader>t` - Tab
   - `<leader>b` - Buffer
   - `<leader>c` - Code (LSP)
   - `<leader>r` - Rename
   - `<leader>s` - Split
   - `<leader>x` - Diagnostics/Close
