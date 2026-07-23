-- Mason configuration (LSP installer)

require("mason").setup({
  ui = {
    icons = {
      package_installed = "",
      package_pending = "",
      package_uninstalled = "",
    },
    border = "rounded",
  },
})

require("mason-lspconfig").setup({
  -- LSP servers to always have installed. Add more as you pick up languages,
  -- e.g. "pyright", "ts_ls", "rust_analyzer".
  ensure_installed = {
    "lua_ls", -- used for editing this config
  },

  -- Install a server automatically the first time you open a matching filetype
  automatic_installation = true,

  handlers = {
    -- Default handler: configure every installed server the same way
    function(server_name)
      local lsp = require("plugins.lsp")
      require("lspconfig")[server_name].setup({
        on_attach = lsp.on_attach,
        capabilities = lsp.capabilities,
      })
    end,
  },
})
