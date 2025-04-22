local ghost_shader_tint =
    data.raw["utility-constants"]["default"].ghost_shader_tint
local ghost_shaderless_tint =
    data.raw["utility-constants"]["default"].ghost_shaderless_tint

ghost_shader_tint.ghost_tint =
    settings.startup["blinking-ghosts-ghost-tint"].value
ghost_shader_tint.ghost_delivery_tint =
    settings.startup["blinking-ghosts-ghost-delivery-tint"].value
ghost_shader_tint.tile_ghost_tint =
    settings.startup["blinking-ghosts-tile-ghost-tint"].value
ghost_shader_tint.tile_ghost_delivery_tint =
    settings.startup["blinking-ghosts-tile-ghost-delivery-tint"].value

ghost_shaderless_tint.ghost_tint =
    settings.startup["blinking-ghosts-ghost-tint"].value
ghost_shaderless_tint.ghost_delivery_tint =
    settings.startup["blinking-ghosts-ghost-delivery-tint"].value
ghost_shaderless_tint.tile_ghost_tint =
    settings.startup["blinking-ghosts-tile-ghost-tint"].value
ghost_shaderless_tint.tile_ghost_delivery_tint =
    settings.startup["blinking-ghosts-tile-ghost-delivery-tint"].value

data:extend({
    -- Blinking sprites
    {
        type = "sprite",
        name = "blinking-ghosts-entity-indicator",
        filename = data.raw["entity-ghost"]["entity-ghost"].icon,
        width = 64,
        height = 64
    },
    {
        type = "sprite",
        name = "blinking-ghosts-tile-indicator",
        filename = data.raw["tile-ghost"]["tile-ghost"].icon,
        width = 64,
        height = 64
    },
    -- Shortcut button
    {
        type = "shortcut",
        name = "blinking-ghosts-toggle-shortcut",
        icon = data.raw["entity-ghost"]["entity-ghost"].icon,
        small_icon = data.raw["entity-ghost"]["entity-ghost"].icon,
        toggleable = true,
        action = "lua"
    }
})
