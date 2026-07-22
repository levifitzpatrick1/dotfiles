-- Indent-blankline configuration

require("ibl").setup({
  indent = {
    char = "│",
    tab_char = "│",
  },
  scope = {
    enabled = true,
    show_start = true,
    show_end = false,
  },
  exclude = {
    filetypes = {
      "help",
      "alpha",
      "dashboard",
      "NvimTree",
      "Trouble",
      "lazy",
      "mason",
      "notify",
      "toggleterm",
    },
  },
})
