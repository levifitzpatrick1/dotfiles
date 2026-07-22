-- LSP configuration

local cmp_nvim_lsp = require("cmp_nvim_lsp")

-- Disable and stop cspell (spell checker LSP)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "cspell" then
      vim.lsp.stop_client(client.id)
    end
  end,
})

local keymap = vim.keymap

-- Enable keybinds and autocompletion for LSP
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Enable semantic tokens if supported (provides better type coloring)
  if client.server_capabilities.semanticTokensProvider then
    -- Start semantic tokens immediately
    vim.lsp.semantic_tokens.start(bufnr, client.id)

    -- Force a refresh after a short delay to ensure colors appear
    vim.defer_fn(function()
      vim.lsp.semantic_tokens.force_refresh(bufnr)
    end, 500)
  end

  -- LSP keymaps
  keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
  keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
  keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
  keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Show references" }))
  keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show hover documentation" }))
  keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code actions" }))
  keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
  keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show line diagnostics" }))
  keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Go to previous diagnostic" }))
  keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Go to next diagnostic" }))
end

-- Enhanced capabilities for autocompletion and semantic tokens
local capabilities = cmp_nvim_lsp.default_capabilities()
capabilities.textDocument.semanticTokens = vim.NIL  -- Let LSP server decide

-- Configure diagnostic display
vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  },
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- LSP servers are auto-configured by mason-lspconfig handlers
-- The handlers in mason.lua will automatically setup all installed servers
-- with on_attach and capabilities from this file

-- If you need custom server-specific settings, use mason-lspconfig handlers like:
-- handlers = {
--   ["omnisharp"] = function()
--     require("lspconfig").omnisharp.setup({
--       on_attach = on_attach,
--       capabilities = capabilities,
--       enable_roslyn_analyzers = true,
--     })
--   end,
-- }

-- Export config for mason-lspconfig handlers
return {
  get_config = function()
    return {
      on_attach = on_attach,
      capabilities = capabilities,
    }
  end,
}
