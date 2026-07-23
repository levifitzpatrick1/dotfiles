-- Treesitter configuration (nvim-treesitter's new install/highlight API)

-- Parsers to have on hand right away. For anything else, run `:TSInstall <lang>`.
local ensure_installed = { "lua", "vim", "vimdoc", "bash", "markdown", "markdown_inline" }

require("nvim-treesitter").install(ensure_installed)

-- Turn on highlighting (and treesitter-based indent) for any filetype that
-- has a parser installed.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match) or args.match
    if not vim.treesitter.language.add(lang) then
      return
    end
    vim.treesitter.start(args.buf, lang)
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
