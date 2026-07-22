# Neovim Keybindings Cheatsheet

**Leader Key:** `<Space>`

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
| `<leader>bp` | Normal | Pick buffer |

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

---

## Harpoon (Quick File Navigation)

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>a` | Normal | Add file to harpoon |
| `<C-e>` | Normal | Toggle harpoon menu |
| `<C-h>` | Normal | Jump to harpoon file 1 |
| `<C-j>` | Normal | Jump to harpoon file 2 |
| `<C-k>` | Normal | Jump to harpoon file 3 |
| `<C-l>` | Normal | Jump to harpoon file 4 |

**Note:** Harpoon uses `<C-h/j/k/l>` which conflicts with window navigation. Use after adding files to harpoon.

---

## LSP (Language Server Protocol)

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

## Terminal (ToggleTerm)

| Key | Mode | Description |
|-----|------|-------------|
| `<C-\>` | Normal/Terminal | Toggle terminal |
| `<leader>tt` | Normal | Toggle floating terminal |
| `<leader>th` | Normal | Toggle horizontal terminal |
| `<leader>tv` | Normal | Toggle vertical terminal |

---

## Debugging (DAP)

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>db` | Normal | Toggle breakpoint |
| `<leader>dc` | Normal | Continue/Start debugging |
| `<leader>di` | Normal | Step into |
| `<leader>do` | Normal | Step over |
| `<leader>dO` | Normal | Step out |
| `<leader>dt` | Normal | Terminate debugging |
| `<leader>du` | Normal | Toggle DAP UI |

---

## Flash (Quick Navigation)

Flash allows you to jump to any location on screen by typing a few characters.

| Key | Mode | Description |
|-----|------|-------------|
| `s` | Normal | Flash forward search |
| `S` | Normal | Flash backward search |

---

## Commands

| Command | Description |
|---------|-------------|
| `:Mason` | Open Mason (LSP/DAP installer) |
| `:Lazy` | Open Lazy plugin manager |
| `:checkhealth` | Check Neovim health |
| `:Telescope` | Open Telescope picker |
| `:Git` or `:G` | Open vim-fugitive Git interface |

---

## Tips

1. **Which-key popup:** Press `<Space>` and wait 1 second to see available keybindings
2. **Window conflict:** Harpoon `<C-h/j/k/l>` conflicts with window navigation - use window keys when not using harpoon
3. **Leader key groups:**
   - `<leader>f` - Find (Telescope)
   - `<leader>e` - Explorer
   - `<leader>h` - Git Hunk
   - `<leader>t` - Toggle/Terminal
   - `<leader>b` - Buffer
   - `<leader>d` - Debug
   - `<leader>c` - Code (LSP)
   - `<leader>r` - Rename
   - `<leader>s` - Split
   - `<leader>x` - Diagnostics/Close

---

Generated for Neovim configuration at: `C:\Users\lfitzpatrick\AppData\Local\nvim`
