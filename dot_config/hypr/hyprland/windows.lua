hl.window_rule({
    name = "steam-empty-helper",
    match = { class = "^(steam_app_0)$", title = "^$" },
    workspace = "special:silent",
})

hl.window_rule({
    name = "spotify-workspace",
    match = { class = "^[Ss]potify$" },
    workspace = "special:spotify",
})

hl.window_rule({
    name = "spotify-float",
    match = { class = "^[Ss]potify$" },
    float = true,
    size = "1200 800",
    center = true,
})

hl.window_rule({
    name = "floating-editors",
    match = { class = "^(code|codium|zed|mousepad|gedit|org.gnome.TextEditor|notepad|notepadqq)$" },
    float = true,
    size = "1200 800",
    center = true,
})

hl.window_rule({
    name = "notepad-title",
    match = { title = "^.*[Nn]otepad.*$" },
    float = true,
    size = "1200 800",
    center = true,
})

hl.window_rule({
    name = "floating-dialogs",
    match = { title = "^(Open File|Save File|Volume Control)$" },
    float = true,
})

hl.layer_rule({
    name = "shell-blur",
    match = { namespace = "^(quickshell)$" },
    blur = true,
    ignore_alpha = 0.5,
})
