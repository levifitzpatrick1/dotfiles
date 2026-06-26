hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = -0.6,
        accel_profile = "flat",

        touchpad = {
            natural_scroll = false,
        },
    },

    cursor = {
        enable_hyprcursor = false,
    },
})

hl.device({
    name = "logitech-gaming-mouse-g600",
    sensitivity = -0.25,
    accel_profile = "flat",
})
