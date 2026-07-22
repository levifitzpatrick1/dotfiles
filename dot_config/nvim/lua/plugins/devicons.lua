-- Nvim-web-devicons configuration (Catppuccin Perfect Icons style)

require("nvim-web-devicons").setup({
  override = {
    -- Programming languages
    lua = { icon = "", color = "#8aadf4", name = "Lua" },
    py = { icon = "", color = "#eed49f", name = "Py" },
    java = { icon = "", color = "#ed8796", name = "Java" },
    js = { icon = "", color = "#eed49f", name = "Js" },
    ts = { icon = "", color = "#8aadf4", name = "Ts" },
    jsx = { icon = "", color = "#8bd5ca", name = "Jsx" },
    tsx = { icon = "", color = "#8bd5ca", name = "Tsx" },
    rs = { icon = "", color = "#f5a97f", name = "Rs" },
    go = { icon = "", color = "#8bd5ca", name = "Go" },
    c = { icon = "", color = "#8aadf4", name = "C" },
    cpp = { icon = "", color = "#c6a0f6", name = "Cpp" },
    cs = { icon = "", color = "#a6da95", name = "Cs" },
    rb = { icon = "", color = "#ed8796", name = "Rb" },
    php = { icon = "", color = "#c6a0f6", name = "Php" },

    -- Web
    html = { icon = "", color = "#ed8796", name = "Html" },
    css = { icon = "", color = "#8aadf4", name = "Css" },
    scss = { icon = "", color = "#f5bde6", name = "Scss" },
    sass = { icon = "", color = "#f5bde6", name = "Sass" },
    json = { icon = "", color = "#eed49f", name = "Json" },
    xml = { icon = "", color = "#f5a97f", name = "Xml" },
    yaml = { icon = "", color = "#a6da95", name = "Yaml" },
    yml = { icon = "", color = "#a6da95", name = "Yml" },
    toml = { icon = "", color = "#a6da95", name = "Toml" },

    -- Markdown & docs
    md = { icon = "", color = "#8bd5ca", name = "Md" },
    txt = { icon = "", color = "#cad3f5", name = "Txt" },
    pdf = { icon = "", color = "#ed8796", name = "Pdf" },

    -- Config files
    vim = { icon = "", color = "#a6da95", name = "Vim" },
    gitignore = { icon = "", color = "#f5a97f", name = "GitIgnore" },
    [".gitattributes"] = { icon = "", color = "#f5a97f", name = "GitAttributes" },
    [".gitmodules"] = { icon = "", color = "#f5a97f", name = "GitModules" },
    Dockerfile = { icon = "", color = "#8aadf4", name = "Dockerfile" },
    ["docker-compose.yml"] = { icon = "", color = "#8aadf4", name = "DockerCompose" },

    -- Build & package managers
    ["package.json"] = { icon = "", color = "#a6da95", name = "PackageJson" },
    ["package-lock.json"] = { icon = "", color = "#ed8796", name = "PackageLockJson" },
    ["Cargo.toml"] = { icon = "", color = "#f5a97f", name = "Cargo" },
    ["pom.xml"] = { icon = "", color = "#ed8796", name = "Maven" },
    ["build.gradle"] = { icon = "", color = "#8bd5ca", name = "Gradle" },

    -- Images
    png = { icon = "", color = "#c6a0f6", name = "Png" },
    jpg = { icon = "", color = "#c6a0f6", name = "Jpg" },
    jpeg = { icon = "", color = "#c6a0f6", name = "Jpeg" },
    gif = { icon = "", color = "#c6a0f6", name = "Gif" },
    svg = { icon = "", color = "#eed49f", name = "Svg" },

    -- Folders
    [".git"] = { icon = "", color = "#f5a97f", name = "Git" },
    ["node_modules"] = { icon = "", color = "#ed8796", name = "NodeModules" },

    -- Other
    sh = { icon = "", color = "#a6da95", name = "Sh" },
    zsh = { icon = "", color = "#a6da95", name = "Zsh" },
    fish = { icon = "", color = "#a6da95", name = "Fish" },
    license = { icon = "", color = "#eed49f", name = "License" },
    LICENSE = { icon = "", color = "#eed49f", name = "License" },
  },

  -- Default icon
  default = true,

  -- Color icons by default
  color_icons = true,

  -- Strict mode (only use icons that match the exact filename)
  strict = true,

  -- Override by filename
  override_by_filename = {
    [".gitignore"] = { icon = "", color = "#f5a97f", name = "GitIgnore" },
    ["LICENSE"] = { icon = "", color = "#eed49f", name = "License" },
    ["README.md"] = { icon = "", color = "#8bd5ca", name = "Readme" },
    ["Makefile"] = { icon = "", color = "#a6da95", name = "Makefile" },
  },

  -- Override by extension
  override_by_extension = {
    ["log"] = { icon = "", color = "#cad3f5", name = "Log" },
    ["env"] = { icon = "", color = "#eed49f", name = "Env" },
  },
})
