-- Mason DAP configuration (Debug Adapter installer)

require("mason-nvim-dap").setup({
  -- Automatically install debug adapters
  ensure_installed = {
    "netcoredbg",  -- C# / VB.NET
    "java-debug-adapter",  -- Java
    -- Add more debug adapters as needed:
    -- "python",      -- Python
    -- "js",          -- JavaScript/TypeScript (node)
    -- "codelldb",    -- C/C++/Rust
  },

  -- Automatically install debug adapters when you start debugging
  automatic_installation = true,

  -- Automatic setup of debug adapters
  handlers = {
    function(config)
      -- Default handler: setup all debug adapters
      require("mason-nvim-dap").default_setup(config)
    end,

    -- Custom handler for .NET Core debugger (C#/VB.NET)
    netcoredbg = function(config)
      config.adapters = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
        args = { "--interpreter=vscode" },
      }
      require("mason-nvim-dap").default_setup(config)
    end,
  },
})

-- Additional manual DAP configurations (if automatic setup doesn't work)
local dap = require("dap")

-- C# / VB.NET configuration
dap.configurations.cs = {
  {
    type = "netcoredbg",
    name = "Launch - netcoredbg",
    request = "launch",
    program = function()
      return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
    end,
  },
}

-- VB.NET uses the same adapter as C#
dap.configurations.vb = dap.configurations.cs

-- Java configuration
dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Debug (Attach) - Remote",
    hostName = "127.0.0.1",
    port = 5005,
  },
  {
    type = "java",
    request = "launch",
    name = "Debug (Launch) - Current File",
    mainClass = "${file}",
  },
}
