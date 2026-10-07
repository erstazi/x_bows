--[[
    X Bows. Adds bow and arrows with API.
    Copyright (C) 2026 SaKeL

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, see <https://www.gnu.org/licenses/>.
--]]

core.register_on_mods_loaded(function()
    if not core.get_modpath('deathstats') then
        return
    end

    -- Post-tick catch-up: transfers any arrows that attached via core.after(0)
    -- (e.g. fatal killing blow arrow) to the spawned corpse entity
    core.register_on_dieplayer(function(player)
        local player_name = player and player:is_valid() and player:get_player_name()
        if not player_name or player_name == '' then
            return
        end

        core.after(0, function(name)
            local v_player = core.get_player_by_name(name)
            if not v_player or not v_player:is_valid() then
                return
            end
            local ds = rawget(_G, 'deathstats')
            if not ds then
                return
            end

            local corpse = nil
            if ds.get_corpse then
                corpse = ds.get_corpse(name)
            elseif ds.player_camera_data and ds.player_camera_data[name] then
                corpse = ds.player_camera_data[name].corpse
            end

            if corpse and corpse:is_valid() then
                XBows.transfer_arrows_to_corpse(v_player, corpse)
            end
        end, player_name)
    end)
end)
