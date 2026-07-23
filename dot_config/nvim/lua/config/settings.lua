-- General Neovim settings

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 4  -- Width of number column (increase for more space)

-- Tabs & indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- Line wrapping
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor line
opt.cursorline = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes:2"  -- Always show sign column with width of 2

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Consider - as part of keyword
opt.iskeyword:append("-")

-- Disable swapfile
opt.swapfile = false

-- Disable spell checking completely
opt.spell = false
opt.spelllang = ""

-- Disable spell checking in all filetypes
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*",
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Enhanced line number highlighting
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Current line number (bright and bold)
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#c6a0f6", bold = true })
    -- Relative line numbers (dimmed but readable)
    vim.api.nvim_set_hl(0, "LineNr", { fg = "#6e738d" })
    -- Sign column background matches editor
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
  end,
})

-- Apply highlights immediately
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#c6a0f6", bold = true })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#6e738d" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
