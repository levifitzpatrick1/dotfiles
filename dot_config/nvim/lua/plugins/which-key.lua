-- Which-key configuration

require("which-key").setup({
  preset = "modern",
  plugins = {
    marks = true,
    registers = true,
    spelling = {
      enabled = false,
    },
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  },
  icons = {
    breadcrumb = "»",
    separator = "",
    group = "+",
    keys = {
      Up = " ",
      Down = " ",
      Left = " ",
      Right = " ",
      C = "󰘴 ",
      M = "󰘵 ",
      D = "󰘳 ",
      S = "󰘶 ",
      CR = "󰌑 ",
      Esc = "󱊷 ",
      ScrollWheelDown = "󱕐 ",
      ScrollWheelUp = "󱕑 ",
      NL = "󰌑 ",
      BS = "󰁮",
      Space = "󱁐 ",
      Tab = "󰌒 ",
      F1 = "󱊫",
      F2 = "󱊬",
      F3 = "󱊭",
      F4 = "󱊮",
      F5 = "󱊯",
      F6 = "󱊰",
      F7 = "󱊱",
      F8 = "󱊲",
      F9 = "󱊳",
      F10 = "󱊴",
      F11 = "󱊵",
      F12 = "󱊶",
    },
  },
  win = {
    border = "rounded",
    padding = { 1, 2 },
    wo = {
      winblend = 0,
    },
  },
  layout = {
    width = { min = 20, max = 50 },
    spacing = 3,
    align = "left",
  },
  show_help = false,
  triggers = {},  -- Disable all triggers
})

-- Register key groups
require("which-key").add({
  { "<leader>f", group = "Find" },
  { "<leader>h", group = "Git Hunk" },
  { "<leader>t", group = "Toggle/Terminal" },
  { "<leader>b", group = "Buffer" },
  { "<leader>e", group = "Explorer" },
  { "<leader>c", group = "Code" },
  { "<leader>r", group = "Rename" },
  { "<leader>x", group = "Diagnostics" },
  { "<leader>a", group = "Add to Harpoon" },
  { "<leader>d", group = "Debug" },
})
