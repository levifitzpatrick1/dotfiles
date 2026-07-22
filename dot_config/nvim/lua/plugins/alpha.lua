-- Alpha dashboard configuration with Bongo Cat

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

-- Bongo Cat ASCII Art
dashboard.section.header.val = {
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⠏⠀⠙⢤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⡀⠀⣠⠔⠊⠉⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠲⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠋⠀⠈⢻⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠢⠔⠚⠙⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠈⠉⠁⠒⠢⠤⠄⣀⣀⠀⠀⢸⠀⠀⠀⠈⠀⠀⠀⠾⠆⢀⣀⡀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⣸⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⢚⣶⣤⠤⣀⣀⠀⠀⠀⠀⠈⠉⠙⠂⠀⠀⢰⡦⡼⠁⠈⢳⡀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠋⠀⠈⣩⠗⠒⠻⢭⣖⣒⡤⠤⣀⣀⡀⠀⠈⠀⡇⠀⠀⠀⠁⠀⠀⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣉⡀⠀⠀⡴⠃⠀⠀⣠⠋⠀⠀⢈⡟⠙⠒⠫⢭⢗⣒⡳⠤⣄⣀⡀⠀⠀⠈⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⢠⠛⠒⠤⠤⣉⣉⠓⠒⠤⠼⣁⣀⠀⣠⠋⠀⠀⠀⡴⠃⠀⠀⣨⠋⠑⠒⢪⡍⠓⠒⠣⠤⢄⣀⡀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠸⠦⣀⣀⠀⠀⠀⠈⠉⠓⠒⠢⠤⢌⣉⡒⠒⠤⠾⢄⣀⡀⡰⠃⠀⠀⢠⢎⡗⠀⠀⠀⠀⠀⠀⠈⠉⠑⠒⠢⠤⢄⣀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠒⠒⠤⠤⣀⣀⠀⠀⠀⠈⠉⠉⠒⠒⠤⠬⣍⣑⡒⡲⢃⠞⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠒⠒⠤⠄⣀⣀⠀⠀⠀⠀⢸⣳⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
[[                                                  ]],
[[                                                  ]],
[[                   Bongo Boi                      ]]

}

-- Set header highlight
dashboard.section.header.opts.hl = "DashboardHeader"

-- Menu buttons
dashboard.section.buttons.val = {
    dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
    dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
    dashboard.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
    dashboard.button("t", "  Find text", ":Telescope live_grep <CR>"),
    dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
    dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
}

-- Footer
local function footer()
    -- Count plugins using lazy.nvim API
    local ok, lazy = pcall(require, "lazy")
    local total_plugins = 0
    if ok then
        local plugins = lazy.plugins()
        total_plugins = #plugins
    end

    local datetime = os.date("  %d-%m-%Y   %H:%M:%S")
    local version = vim.version()
    local nvim_version_info = "   v" .. version.major .. "." .. version.minor .. "." .. version.patch

    return datetime .. "   " .. total_plugins .. " plugins" .. nvim_version_info
end

dashboard.section.footer.val = footer()
dashboard.section.footer.opts.hl = "DashboardFooter"

-- Layout
dashboard.config.layout = {
    { type = "padding", val = 2 },
    dashboard.section.header,
    { type = "padding", val = 2 },
    dashboard.section.buttons,
    { type = "padding", val = 1 },
    dashboard.section.footer,
}

-- Disable folding on alpha buffer
vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])

-- Custom highlights using Catppuccin colors
vim.cmd([[
    highlight DashboardHeader guifg=#c6a0f6
    highlight DashboardFooter guifg=#8bd5ca
]])

-- Setup alpha
alpha.setup(dashboard.config)
