--[[
    X Bows. Native integration for x_player_api dual-format character models and animations.
    Copyright (C) 2026 SaKeL

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.
--]]

if not XBows.x_player_api or not x_player_api then
    return
end

-- Register x_bows items with x_player_api item actions
x_player_api.register_item_action('x_bows:.*', {
    is_bow = true,
    action = 'bow_aim',
    shoot_action = 'bow_shoot',
})

-- Refresh quiver entity observers when players join or leave so cohort updates propagate
core.register_on_joinplayer(function(_player)
    core.after(0.3, function()
        local modern = x_player_api.get_modern_observers()
        local legacy = x_player_api.get_legacy_observers()
        for _, quivers in pairs(XBowsQuiver.active_quivers) do
            if type(quivers) == 'table' then
                if quivers.glb and quivers.glb:is_valid() then
                    quivers.glb:set_observers(modern)
                end
                if quivers.b3d and quivers.b3d:is_valid() then
                    quivers.b3d:set_observers(legacy)
                end
            end
        end
    end)
end)
