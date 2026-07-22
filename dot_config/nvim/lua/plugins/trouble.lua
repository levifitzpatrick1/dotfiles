-- Trouble.nvim configuration

require("trouble").setup({
  position = "bottom",
  height = 10,
  width = 50,
  icons = true,
  mode = "workspace_diagnostics",
  severity = nil,
  fold_open = "",
  fold_closed = "",
  group = true,
  padding = true,
  cycle_results = true,
  action_keys = {
    close = "q",
    cancel = "<esc>",
    refresh = "r",
    jump = { "<cr>", "<tab>", "<2-leftmouse>" },
    open_split = { "<c-x>" },
    open_vsplit = { "<c-v>" },
    open_tab = { "<c-t>" },
    jump_close = { "o" },
    toggle_mode = "m",
    switch_severity = "s",
    toggle_preview = "P",
    hover = "K",
    preview = "p",
    open_code_href = "c",
    close_folds = { "zM", "zm" },
    open_folds = { "zR", "zr" },
    toggle_fold = { "zA", "za" },
    previous = "k",
    next = "j",
    help = "?",
  },
  multiline = true,
  indent_lines = true,
  win_config = { border = "rounded" },
  auto_open = false,
  auto_close = false,
  auto_preview = true,
  auto_fold = false,
  auto_jump = { "lsp_definitions" },
  use_diagnostic_signs = true,
})

-- Keymaps
vim.keymap.set("n", "<leader>xx", ":Trouble diagnostics toggle<CR>", { desc = "Toggle diagnostics" })
vim.keymap.set("n", "<leader>xw", ":Trouble diagnostics toggle<CR>", { desc = "Workspace diagnostics" })
vim.keymap.set("n", "<leader>xd", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>xl", ":Trouble loclist toggle<CR>", { desc = "Location list" })
vim.keymap.set("n", "<leader>xq", ":Trouble qflist toggle<CR>", { desc = "Quickfix list" })
