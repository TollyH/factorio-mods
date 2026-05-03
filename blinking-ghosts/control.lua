local function is_entity_renderers_visible()
    return storage.ghost_indicators_visible and
        -- If no players have the indicators visible, don't render them.
        -- Fixes an issue where toggling indicators doesn't work if all
        -- players have them disabled.
        table_size(storage.entity_blinking_enabled_players) > 0
end

local function is_tile_renderers_visible()
    return storage.ghost_indicators_visible and
        -- If no players have the indicators visible, don't render them.
        -- Fixes an issue where toggling indicators doesn't work if all
        -- players have them disabled.
        table_size(storage.tile_blinking_enabled_players) > 0
end

local function add_renderer(entity, is_tile)
    -- Make sure an event is fired when this entity stops existing so that the
    -- renderer can be removed. The registration number returned by this
    -- function is used as the identifier for the renderer.
    local id_number = script.register_on_object_destroyed(entity)

    local scale = settings.global["blinking-ghosts-blink-scale"].value

    local ghost_indicator_renderers
    local blinking_enabled_players
    local sprite
    local visible
    if is_tile then
        ghost_indicator_renderers = storage.tile_ghost_indicator_renderers
        blinking_enabled_players = storage.tile_blinking_enabled_players
        sprite = "blinking-ghosts-tile-indicator"
        visible = is_tile_renderers_visible()
    else
        ghost_indicator_renderers = storage.entity_ghost_indicator_renderers
        blinking_enabled_players = storage.entity_blinking_enabled_players
        sprite = "blinking-ghosts-entity-indicator"
        visible = is_entity_renderers_visible()
    end

    ghost_indicator_renderers[id_number] = rendering.draw_sprite{
        sprite=sprite,
        target=entity,
        surface=entity.surface,
        players=blinking_enabled_players,
        visible=visible,
        x_scale=scale,
        y_scale=scale,
        render_layer="entity-info-icon"
    }
end

local function remove_renderer(id_number)
    -- on_object_destroyed does not give direct access to the type of entity
    -- that was destroyed, so attempt to remove from both entity and tile
    -- tables.
    local renderer = storage.entity_ghost_indicator_renderers[id_number]
    if renderer ~= nil then
        renderer.destroy()
        storage.entity_ghost_indicator_renderers[id_number] = nil
    end

    renderer = storage.tile_ghost_indicator_renderers[id_number]
    if renderer ~= nil then
        renderer.destroy()
        storage.tile_ghost_indicator_renderers[id_number] = nil
    end
end

local function refresh_all_renderers()
    -- Remove any existing renderers
    storage.tile_ghost_indicator_renderers = {}
    storage.entity_ghost_indicator_renderers = {}
    rendering.clear("blinking-ghosts")

    for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered{name="entity-ghost"}
        for _, entity in pairs(entities) do
            add_renderer(entity, false)
        end

        local tiles = surface.find_entities_filtered{name="tile-ghost"}
        for _, tile in pairs(tiles) do
            add_renderer(tile, true)
        end
    end
end

local function update_entity_renderer_visible_to_players()
    local visible = is_entity_renderers_visible()
    for _, renderer in pairs(storage.entity_ghost_indicator_renderers) do
        if renderer.valid then
            renderer.players = storage.entity_blinking_enabled_players
            renderer.visible = visible
        end
    end
end

local function update_tile_renderer_visible_to_players()
    local visible = is_tile_renderers_visible()
    for _, renderer in pairs(storage.tile_ghost_indicator_renderers) do
        if renderer.valid then
            renderer.players = storage.tile_blinking_enabled_players
            renderer.visible = visible
        end
    end
end

local function update_shortcut_toggled(player)
    -- Sync the state of the shortcut bar button to the player's mod setting
    local player_settings = settings.get_player_settings(player)
    player.set_shortcut_toggled(
        "blinking-ghosts-toggle-shortcut-entity",
        player_settings["blinking-ghosts-blink-enabled-entity"].value
    )
    player.set_shortcut_toggled(
        "blinking-ghosts-toggle-shortcut-tile",
        player_settings["blinking-ghosts-blink-enabled-tile"].value
    )
end

local function update_player_blink_visibility_table(player, plr_table, enabled)
    if enabled then
        table.insert(plr_table, player)
    else
        -- Remove the player from the list of players that should be able
        -- to see ghost indicators.
        for i, p in ipairs(plr_table) do
            if p == player then
                table.remove(plr_table, i)
                break
            end
        end
    end
end

local function update_player_blink_visibility(player, tile)
    -- Either add or remove a player from the enabled player list depending
    -- on their current setting. Should only be called when this setting has
    -- changed, or the player may become duplicated in the list.
    update_shortcut_toggled(player)
    local player_settings =
        settings.get_player_settings(player)
    if tile then
        update_player_blink_visibility_table(
            player,
            storage.tile_blinking_enabled_players,
            player_settings["blinking-ghosts-blink-enabled-tile"].value
        )
        update_tile_renderer_visible_to_players()
    else
        update_player_blink_visibility_table(
            player,
            storage.entity_blinking_enabled_players,
            player_settings["blinking-ghosts-blink-enabled-entity"].value
        )
        update_entity_renderer_visible_to_players()
    end
end

local function refresh_player_list()
    -- Update the list of players that should be able to see the ghost icons.
    storage.entity_blinking_enabled_players = {}
    storage.tile_blinking_enabled_players = {}

    for _, player in pairs(game.connected_players) do
        update_shortcut_toggled(player)
        local player_settings = settings.get_player_settings(player)
        if player_settings["blinking-ghosts-blink-enabled-entity"].value then
            table.insert(storage.entity_blinking_enabled_players, player)
        end
        if player_settings["blinking-ghosts-blink-enabled-tile"].value then
            table.insert(storage.tile_blinking_enabled_players, player)
        end
    end

    refresh_all_renderers()
end

local function blink_ghost_renderers()
    storage.ghost_indicators_visible =
        settings.global["blinking-ghosts-blink-disable-flash"].value or
        not storage.ghost_indicators_visible

    local visible = is_entity_renderers_visible()
    -- Only update renderer visibility if it has actually changed, this saves
    -- UPS with large numbers of indicators when flashing is disabled or when
    -- all players have the indicators disabled.
    if visible ~= storage.are_entity_indicators_rendered then
        storage.are_entity_indicators_rendered = visible
        for _, renderer in pairs(storage.entity_ghost_indicator_renderers) do
            if renderer.valid then
                renderer.visible = visible
            end
        end
    end

    visible = is_tile_renderers_visible()
    if visible ~= storage.are_tile_indicators_rendered then
        storage.are_tile_indicators_rendered = visible
        for _, renderer in pairs(storage.tile_ghost_indicator_renderers) do
            if renderer.valid then
                renderer.visible = visible
            end
        end
    end
end

local function register_blink_event()
    -- Remove any existing handlers
    script.on_nth_tick(nil)
    script.on_nth_tick(
        settings.global["blinking-ghosts-blink-rate"].value * 60,  -- 60 UPS
        function(event)
            blink_ghost_renderers()
        end
    )
end

script.on_init(function()
    storage.ghost_indicators_visible = true
    storage.are_entity_indicators_rendered = true
    storage.are_tile_indicators_rendered = true
    register_blink_event()
    refresh_player_list()
end)

script.on_event(defines.events.on_built_entity, function(event)
    if event.entity.name == "entity-ghost" then
        add_renderer(event.entity, false)
    elseif event.entity.name == "tile-ghost" then
        add_renderer(event.entity, true)
    end
end, {{filter="ghost"}})

script.on_event(defines.events.on_object_destroyed, function(event)
    remove_renderer(event.registration_number)
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "blinking-ghosts-blink-rate" then
        -- The player has changed the rate that the ghosts blink,
        -- reset the blink timing.
        register_blink_event()
    elseif event.setting == "blinking-ghosts-blink-scale" then
        -- The player has changed the scale of the indicator,
        -- recreate the renderers.
        refresh_all_renderers()
    elseif event.setting == "blinking-ghosts-blink-enabled-entity" then
        -- A player has changed whether the blinking icon is visible to them.
        local player = game.players[event.player_index]
        update_player_blink_visibility(player, false)
    elseif event.setting == "blinking-ghosts-blink-enabled-tile" then
        -- A player has changed whether the blinking icon is visible to them.
        local player = game.players[event.player_index]
        update_player_blink_visibility(player, true)
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    -- If event starts with blinking-ghosts-toggle-shortcut.
    local shortcut = event.prototype_name
    if string.find(shortcut, "^blinking%-ghosts%-toggle%-shortcut") then
        local player = game.players[event.player_index]
        local enabled =
            player.is_shortcut_toggled(shortcut)
        local player_settings =
            settings.get_player_settings(player)
        -- Get '-tile' or '-entity' part from event name.
        local toggle_type = string.sub(shortcut, 32)
        player_settings["blinking-ghosts-blink-enabled" .. toggle_type] =
            {value = not enabled}
    end
end)

script.on_event(
    {
        defines.events.on_player_joined_game,
        defines.events.on_player_left_game
    },
    function(event)
        refresh_player_list()
    end
)

register_blink_event()
