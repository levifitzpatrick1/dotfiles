-- Mason configuration (LSP installer)

require("mason").setup({
  ui = {
    icons = {
      package_installed = "",
      package_pending = "",
      package_uninstalled = ""
    },
    border = "rounded",
  }
})

require("mason-lspconfig").setup({
  -- Auto-install these LSP servers (you can add more here)
  ensure_installed = {
    "omnisharp",    -- C# / VB.NET
    "jdtls",        -- Java
    -- "lua_ls",       -- Lua
    -- "pyright",      -- Python
    -- "ts_ls",        -- TypeScript
  },

  -- Automatically install LSP servers when you open matching files
  automatic_installation = {
    exclude = { "cspell", "cspell_ls" } -- Exclude spell checker
  },

  -- Setup handlers - this automatically configures servers
  handlers = {
    -- Default handler: automatically setup all servers
    function(server_name)
      -- Skip cspell completely
      if server_name == "cspell" or server_name == "cspell_ls" then
        return
      end

      -- Get the lsp module from lsp.lua for on_attach and capabilities
      local has_lsp, lsp_module = pcall(require, "plugins.lsp")
      if has_lsp and lsp_module.get_config then
        local config = lsp_module.get_config()
        require("lspconfig")[server_name].setup({
          on_attach = config.on_attach,
          capabilities = config.capabilities,
        })
      end
    end,

    -- Custom handler for OmniSharp (VB.NET/C#)
    ["omnisharp"] = function()
      local has_lsp, lsp_module = pcall(require, "plugins.lsp")
      if has_lsp and lsp_module.get_config then
        local config = lsp_module.get_config()

        -- Function to find solution file
        local function find_solution_file(path)
          local function search_upward(start_path)
            local current = start_path
            while current ~= "/" and current ~= "." and current ~= "" do
              local handle = vim.loop.fs_scandir(current)
              if handle then
                while true do
                  local name, type = vim.loop.fs_scandir_next(handle)
                  if not name then break end
                  if type == "file" and name:match("%.sln$") then
                    return vim.fn.fnamemodify(current .. "/" .. name, ":p")
                  end
                end
              end
              current = vim.fn.fnamemodify(current, ":h")
              if current == vim.fn.fnamemodify(current, ":h") then break end
            end
            return nil
          end

          return search_upward(path)
        end

        require("lspconfig").omnisharp.setup({
          on_attach = config.on_attach,
          capabilities = config.capabilities,
          filetypes = { "cs" },  -- C# only (OmniSharp doesn't support VB.NET)

          -- Root directory detection - find .sln file
          root_dir = function(fname)
            local root = require("lspconfig.util").root_pattern("*.sln")(fname)
            if not root then
              root = require("lspconfig.util").root_pattern("*.csproj", "*.vbproj")(fname)
            end
            return root
          end,

          cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },

          -- Initialize with solution file if found
          on_new_config = function(new_config, new_root_dir)
            if new_root_dir then
              local sln = find_solution_file(new_root_dir)
              if sln then
                print(string.format("OmniSharp: Using solution file: %s", sln))
                new_config.cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()), "-s", sln }
              end
            end
          end,

          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
          analyze_open_documents_only = false,
          enable_editorconfig_support = true,
          enable_ms_build_load_projects_on_demand = false,
          enable_decompilation_support = true,
        })
      end
    end,
  },
})
