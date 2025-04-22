data:extend({
    {
        type = "color-setting",
        name = "blinking-ghosts-ghost-tint",
        setting_type = "startup",
        default_value = {118, 135, 209, 77}
    },
    {
        type = "color-setting",
        name = "blinking-ghosts-ghost-delivery-tint",
        setting_type = "startup",
        default_value = {168, 214, 196, 77}
    },
    {
        type = "color-setting",
        name = "blinking-ghosts-tile-ghost-tint",
        setting_type = "startup",
        default_value = {37, 123, 194, 255}
    },
    {
        type = "color-setting",
        name = "blinking-ghosts-tile-ghost-delivery-tint",
        setting_type = "startup",
        default_value = {174, 221, 242, 255}
    },
    {
        type = "bool-setting",
        name = "blinking-ghosts-blink-enabled",
        setting_type = "runtime-per-user",
        default_value = true
    },
    {
        type = "double-setting",
        name = "blinking-ghosts-blink-rate",
        setting_type = "runtime-global",
        minimum_value = 0.0,
        maximum_value = 5.0,
        default_value = 0.5
    }
})
