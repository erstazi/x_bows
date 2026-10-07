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
    if core.get_modpath('bones') and core.global_exists('bones') and type(bones.player_inventory_lists) == 'table' then
        if table.indexof(bones.player_inventory_lists, 'x_bows:arrow_inv') == -1 then
            table.insert(bones.player_inventory_lists, 'x_bows:arrow_inv')
        end
        if table.indexof(bones.player_inventory_lists, 'x_bows:quiver_inv') == -1 then
            table.insert(bones.player_inventory_lists, 'x_bows:quiver_inv')
        end

        core.register_on_dieplayer(function(player)
            -- try to make sure this is called last in the `on_dieplayer` callback stack
            local player_name = player and player:is_valid() and player:get_player_name()
            if not player_name then
                return
            end
            core.after(0, function(name)
                local v_player = core.get_player_by_name(name)
                if not v_player or not v_player:is_valid() then
                    return
                end
                -- when quiver is being removed from inventory we need to reset the inv page
                if XBows.i3 and core.global_exists('i3') then
                    i3.set_fs(v_player)
                elseif XBows.unified_inventory and core.global_exists('unified_inventory') then
                    unified_inventory.set_inventory_formspec(v_player, 'x_bows:quiver_page')
                elseif core.global_exists('sfinv') then
                    sfinv.set_player_inventory_formspec(v_player)
                end
            end, player_name)
        end)
    end
end)
