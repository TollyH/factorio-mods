local function add_renderer(entity, sprite)
    -- Make sure an event is fired when this entity stops existing so that the
    -- renderer can be removed. The registration number returned by this
    -- function is used as the identifier for the renderer.
    local id_number = script.register_on_object_destroyed(entity)

    storage.ghost_indicator_renderers[id_number] = rendering.draw_sprite{
        sprite=sprite,
        target=entity,
        surface=entity.surface,
        players=storage.blinking_enabled_players,
        visible=storage.ghost_indicators_visible,
        x_scale = 0.5,
        y_scale = 0.5,
        render_layer="entity-info-icon"
    }
end

local function remove_renderer(id_number)
    if storage.ghost_indicator_renderers[id_number] == nil then
        return
    end

    storage.ghost_indicator_renderers[id_number].destroy()
    storage.ghost_indicator_renderers[id_number] = nil
end

local function refresh_all_renderers()
    -- Remove any existing renderers
    storage.ghost_indicator_renderers = {}
    rendering.clear("blinking-ghosts")

    for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered{name="entity-ghost"}
        for _, entity in pairs(entities) do
            add_renderer(entity, "blinking-ghosts-entity-indicator")
        end

        local tiles = surface.find_entities_filtered{name="tile-ghost"}
        for _, tile in pairs(tiles) do
            add_renderer(entity, "blinking-ghosts-tile-indicator")
        end
    end
end

local function update_renderer_visible_to_players()
    for _, renderer in pairs(storage.ghost_indicator_renderers) do
        renderer.players = storage.blinking_enabled_players
    end
end

local function update_shortcut_toggled(player)
    -- Sync the state of the shortcut bar button to the player's mod setting
    local player_settings = settings.get_player_settings(player)
    player.set_shortcut_toggled(
        "blinking-ghosts-toggle-shortcut",
        player_settings["blinking-ghosts-blink-enabled"].value
    )
end

local function update_player_blink_visibility(player)
    -- Either add or remove a player from the enabled player list depending
    -- on their current setting. Should only be called when this setting has
    -- changed, or the player may become duplicated in the list.
    update_shortcut_toggled(player)
    local player_settings =
        settings.get_player_settings(player)
    if player_settings["blinking-ghosts-blink-enabled"].value then
        table.insert(storage.blinking_enabled_players, player)
    else
        -- Remove the player from the list of players that should be able
        -- to see ghost indicators.
        for i, p in ipairs(storage.blinking_enabled_players) do
            if p == player then
                table.remove(storage.blinking_enabled_players, i)
                break
            end
        end
    end

    update_renderer_visible_to_players()
end

local function refresh_player_list()
    -- Update the list of players that should be able to see the ghost icons.
    storage.blinking_enabled_players = {}

    for _, player in pairs(game.players) do
        update_shortcut_toggled(player)
        local player_settings = settings.get_player_settings(player)
        if player_settings["blinking-ghosts-blink-enabled"].value then
            table.insert(storage.blinking_enabled_players, player)
        end
    end

    refresh_all_renderers()
end

local function blink_ghost_renderers()
    storage.ghost_indicators_visible = not storage.ghost_indicators_visible
    
    for id_number, renderer in pairs(storage.ghost_indicator_renderers) do
        renderer.visible = storage.ghost_indicators_visible
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
    register_blink_event()
    refresh_player_list()
end)

script.on_load(function()
    register_blink_event()
    refresh_player_list()
end)

script.on_event(defines.events.on_built_entity, function(event)
    if event.entity.name == "entity-ghost" then
        add_renderer(event.entity, "blinking-ghosts-entity-indicator")
    elseif event.entity.name == "tile-ghost" then
        add_renderer(event.entity, "blinking-ghosts-tile-indicator")
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
    elseif event.setting == "blinking-ghosts-blink-enabled" then
        -- A player has changed whether the blinking icon is visible to them.
        local player = game.players[event.player_index]
        update_player_blink_visibility(player)
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "blinking-ghosts-toggle-shortcut" then
        local player = game.players[event.player_index]
        local enabled =
            player.is_shortcut_toggled("blinking-ghosts-toggle-shortcut")
        local player_settings =
            settings.get_player_settings(player)
        player_settings["blinking-ghosts-blink-enabled"] =
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
