-- Catppuccin Blur Espresso colorscheme configuration
-- Based on: https://github.com/jenslys/zed-catppuccin-blur

require("catppuccin").setup({
  flavour = "mocha",
  background = {
    light = "latte",
    dark = "mocha",
  },
  transparent_background = false,
  show_end_of_buffer = false,
  term_colors = true,
  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
  },
  color_overrides = {
    mocha = {
      -- Base colors (much darker/black)
      base = "#000000",
      mantle = "#000000",
      crust = "#000000",

      -- Surface colors (darker)
      surface0 = "#1a1a1a",
      surface1 = "#1a1a1a",
      surface2 = "#1a1a1a",

      -- Text colors
      text = "#cad3f5",
      subtext0 = "#cad3f5",
      subtext1 = "#cad3f5",

      -- Overlay colors
      overlay0 = "#6e738d",
      overlay1 = "#8087a2",
      overlay2 = "#939ab7",

      -- Accent colors (matching Zed espresso theme)
      blue = "#8aadf4",
      lavender = "#c6a0f6",
      sapphire = "#7dc4e4",
      sky = "#8bd5ca",
      teal = "#8bd5ca",
      green = "#a6da95",
      yellow = "#eed49f",
      peach = "#f5a97f",
      maroon = "#ed8796",
      red = "#ed8796",
      mauve = "#c6a0f6",
      pink = "#f5bde6",
      flamingo = "#f0c6c6",
      rosewater = "#f4dbd6",
    },
  },
  custom_highlights = function(colors)
    return {
      -- Editor
      Normal = { bg = colors.base, fg = colors.text },
      NormalFloat = { bg = colors.mantle },
      FloatBorder = { fg = colors.lavender },

      -- Syntax (basic)
      Keyword = { fg = colors.lavender, style = { "bold" } },
      Function = { fg = colors.blue },
      String = { fg = colors.green },
      Type = { fg = colors.yellow },
      Constant = { fg = colors.peach },
      Comment = { fg = colors.sky, style = { "italic" } },
      Identifier = { fg = colors.text },
      Operator = { fg = colors.sky },

      -- Treesitter semantic highlighting
      ["@variable"] = { fg = colors.text },
      ["@variable.builtin"] = { fg = colors.red },
      ["@variable.parameter"] = { fg = colors.maroon },
      ["@variable.member"] = { fg = colors.text },

      -- Functions and methods
      ["@function"] = { fg = colors.blue },
      ["@function.builtin"] = { fg = colors.peach },
      ["@function.call"] = { fg = colors.blue },
      ["@function.method"] = { fg = colors.blue },
      ["@function.method.call"] = { fg = colors.blue },

      -- Types and classes (differentiated colors)
      ["@type"] = { fg = colors.sapphire },
      ["@type.builtin"] = { fg = colors.yellow },  -- Built-in types
      ["@type.definition"] = { fg = colors.sapphire },
      ["@class"] = { fg = colors.sapphire },
      ["@constructor"] = { fg = colors.sapphire },  -- Constructor calls

      -- Properties and fields
      ["@property"] = { fg = colors.teal },
      ["@field"] = { fg = colors.teal },

      -- Keywords
      ["@keyword"] = { fg = colors.lavender, style = { "bold" } },
      ["@keyword.function"] = { fg = colors.mauve },
      ["@keyword.operator"] = { fg = colors.lavender },
      ["@keyword.return"] = { fg = colors.mauve },
      ["@keyword.repeat"] = { fg = colors.mauve },
      ["@keyword.conditional"] = { fg = colors.mauve },

      -- Strings and constants
      ["@string"] = { fg = colors.green },
      ["@string.escape"] = { fg = colors.pink },
      ["@number"] = { fg = colors.peach },
      ["@boolean"] = { fg = colors.peach },
      ["@constant"] = { fg = colors.peach },
      ["@constant.builtin"] = { fg = colors.peach },

      -- Operators and punctuation
      ["@operator"] = { fg = colors.sky },
      ["@punctuation.bracket"] = { fg = colors.overlay2 },
      ["@punctuation.delimiter"] = { fg = colors.overlay2 },

      -- Comments
      ["@comment"] = { fg = colors.sky, style = { "italic" } },

      -- Namespaces and modules
      ["@namespace"] = { fg = colors.yellow },
      ["@module"] = { fg = colors.yellow },

      -- Diagnostics
      DiagnosticError = { fg = colors.red },
      DiagnosticWarn = { fg = colors.yellow },
      DiagnosticInfo = { fg = colors.sky },
      DiagnosticHint = { fg = colors.teal },

      -- LSP semantic tokens (server-provided, more precise than treesitter)
      ["@lsp.type.class"] = { fg = colors.blue },
      ["@lsp.type.struct"] = { fg = colors.blue },
      ["@lsp.type.interface"] = { fg = colors.sapphire },
      ["@lsp.type.enum"] = { fg = colors.yellow },
      ["@lsp.type.typeParameter"] = { fg = colors.blue },
      ["@lsp.type.delegateName"] = { fg = colors.blue },

      -- Modules
      ["@lsp.type.moduleName"] = { fg = colors.green },
      ["@lsp.type.namespace"] = { fg = colors.green },

      -- Static types/classes
      ["@lsp.type.class.static"] = { fg = colors.green },
      ["@lsp.type.staticSymbol"] = { fg = colors.green },

      -- Properties
      ["@lsp.type.property"] = { fg = colors.lavender },
      ["@lsp.type.fieldName"] = { fg = colors.lavender },
      ["@lsp.type.property.static"] = { fg = colors.lavender },

      -- Variables
      ["@lsp.type.variable"] = { fg = colors.text },
      ["@lsp.type.variable.static"] = { fg = colors.peach },
      ["@lsp.type.fieldName.static"] = { fg = colors.peach },
      ["@lsp.type.parameter"] = { fg = colors.text },
      ["@lsp.type.constantName"] = { fg = colors.peach },
      ["@lsp.type.enumMember"] = { fg = colors.peach },

      -- Methods and functions
      ["@lsp.type.method"] = { fg = colors.blue },
      ["@lsp.type.extensionMethodName"] = { fg = colors.blue },
      ["@lsp.type.function"] = { fg = colors.blue },

      -- Keywords
      ["@lsp.type.keyword"] = { fg = colors.lavender },
      ["@lsp.type.controlKeyword"] = { fg = colors.mauve },

      -- Other
      ["@lsp.type.event"] = { fg = colors.pink },
      ["@lsp.type.operator"] = { fg = colors.sky },
      ["@lsp.type.macro"] = { fg = colors.pink },

      -- LSP
      LspReferenceText = { bg = colors.surface0 },
      LspReferenceRead = { bg = colors.surface0 },
      LspReferenceWrite = { bg = colors.surface0 },
    }
  end,
  integrations = {
    alpha = true,
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    treesitter = true,
    telescope = {
      enabled = true,
    },
    mason = true,
    native_lsp = {
      enabled = true,
      virtual_text = {
        errors = { "italic" },
        hints = { "italic" },
        warnings = { "italic" },
        information = { "italic" },
      },
      underlines = {
        errors = { "underline" },
        hints = { "underline" },
        warnings = { "underline" },
        information = { "underline" },
      },
    },
    which_key = true,
    indent_blankline = {
      enabled = true,
      colored_indent_levels = false,
    },
  },
})

-- Apply the colorscheme
vim.cmd.colorscheme("catppuccin")
