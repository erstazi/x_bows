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

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9))--[[@as number]] )

local path = core.get_modpath('x_bows')
local mod_start_time = core.get_us_time()
local bow_charged_timer = 0

dofile(path .. '/api.lua')
dofile(path .. '/particle_effects.lua')
dofile(path .. '/nodes.lua')
dofile(path .. '/arrow.lua')
dofile(path .. '/items.lua')
dofile(path .. '/privileges.lua')
dofile(path .. '/mod_support_bones.lua')
dofile(path .. '/mod_support_deathstats.lua')
if XBows.x_player_api then
    dofile(path .. '/mod_support_x_player_api.lua')
end

if XBows.i3 then
    XBowsQuiver:i3_register_page()
elseif XBows.unified_inventory then
    XBowsQuiver:ui_register_page()
else
    XBowsQuiver:sfinv_register_page()
end

core.register_on_joinplayer(function(player)
    local inv_quiver = player:get_inventory() --[[@as InvRef]]
    local inv_arrow = player:get_inventory() --[[@as InvRef]]
    local player_meta = player:get_meta()
    local x_bows_show_hud_overlay = player_meta:get_string('x_bows_show_hud_overlay')
    local x_bows_show_damage_numbers = player_meta:get_string('x_bows_show_damage_numbers')

    -- set default values
    if x_bows_show_hud_overlay == '' then
        player_meta:set_string('x_bows_show_hud_overlay', 'true')
    end

    if x_bows_show_damage_numbers == '' then
        player_meta:set_string('x_bows_show_damage_numbers', 'false')
    end

    inv_quiver:set_size('x_bows:quiver_inv', 1 * 1)
    inv_arrow:set_size('x_bows:arrow_inv', 1 * 1)

    local quiver_stack = player:get_inventory():get_stack('x_bows:quiver_inv', 1)

    if quiver_stack and not quiver_stack:is_empty() then
        XBowsQuiver:init_quiver_in_slot(player, player:get_inventory(), 'x_bows:quiver_inv', 1)
        core.after(0.5, function(name)
            local p = core.get_player_by_name(name)
            if p and p:is_valid() then
                local stack = p:get_inventory():get_stack('x_bows:quiver_inv', 1)
                if stack and not stack:is_empty() then
                    XBowsQuiver:init_quiver_in_slot(p, p:get_inventory(), 'x_bows:quiver_inv', 1)
                end
            end
        end, player:get_player_name())
    else
        ---set model textures
        XBowsQuiver:hide_3d_quiver(player)
    end

    XBows:reset_charged_bow(player, true)
    XBowsQuiver:close_quiver(player)
end)

core.register_on_leaveplayer(XBows.on_leaveplayer)
core.register_on_dieplayer(XBows.on_dieplayer)
core.register_on_respawnplayer(XBows.on_respawnplayer)

---formspec callbacks
core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    ---arrow inventory
    if action == 'move' and inventory_info.to_list == 'x_bows:arrow_inv' then
        local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
        if core.get_item_group(stack:get_name(), 'arrow') ~= 0 then
            return inventory_info.count
        else
            return 0
        end
    elseif action == 'move' and inventory_info.from_list == 'x_bows:arrow_inv' then
        return inventory_info.count
    elseif action == 'put' and inventory_info.listname == 'x_bows:arrow_inv' then
        if core.get_item_group(inventory_info.stack:get_name(), 'arrow') ~= 0 then
            return inventory_info.stack:get_count()
        else
            return 0
        end
    elseif action == 'take' and inventory_info.listname == 'x_bows:arrow_inv' then
        return inventory_info.stack:get_count()
    end

    ---quiver inventory
    if action == 'move' and inventory_info.to_list == 'x_bows:quiver_inv' then
        local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
        if core.get_item_group(stack:get_name(), 'quiver') ~= 0 then
            return inventory_info.count
        else
            return 0
        end
    elseif action == 'move' and inventory_info.from_list == 'x_bows:quiver_inv' then
        return inventory_info.count
    elseif action == 'put' and inventory_info.listname == 'x_bows:quiver_inv' then
        if core.get_item_group(inventory_info.stack:get_name(), 'quiver') ~= 0 then
            return inventory_info.stack:get_count()
        else
            return 0
        end
    elseif action == 'take' and inventory_info.listname == 'x_bows:quiver_inv' then
        return inventory_info.stack:get_count()
    end

    return nil
end)

core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    ---arrow
    if action == 'move' and inventory_info.to_list == 'x_bows:arrow_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    elseif action == 'move' and inventory_info.from_list == 'x_bows:arrow_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    elseif action == 'put' and inventory_info.listname == 'x_bows:arrow_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    elseif action == 'take' and inventory_info.listname == 'x_bows:arrow_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    end

    ---quiver
    if (action == 'move' and inventory_info.to_list == 'x_bows:quiver_inv')
        or (action == 'put' and inventory_info.listname == 'x_bows:quiver_inv')
    then
        local to_idx = (action == 'move') and inventory_info.to_index or 1
        XBowsQuiver:init_quiver_in_slot(player, inventory, 'x_bows:quiver_inv', to_idx)

        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    elseif (action == 'move' and inventory_info.from_list == 'x_bows:quiver_inv')
        or (action == 'take' and inventory_info.listname == 'x_bows:quiver_inv')
    then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end

        ---set player visual
        if inventory:is_empty('x_bows:quiver_inv') then
            XBowsQuiver:hide_3d_quiver(player)
        end
    end
end)

core.register_on_player_receive_fields(function(player, formname, fields)
    if player then
        if fields.quit then
            XBowsQuiver:close_quiver(player, formname)
        elseif fields.x_bows_settings_btn then
            -- show settings page
            XBowsQuiver:show_settings_page(player)
        elseif formname == 'xbows_settings_page' and fields.x_bows_show_damage_numbers then
            local player_meta = player:get_meta()

            player_meta:set_string('x_bows_show_damage_numbers', fields.x_bows_show_damage_numbers)
        elseif formname == 'xbows_settings_page' and fields.x_bows_show_hud_overlay then
            local player_meta = player:get_meta()

            player_meta:set_string('x_bows_show_hud_overlay', fields.x_bows_show_hud_overlay)
        end
    end
end)

---backwards compatibility
core.register_alias('x_bows:arrow_diamond_tipped_poison', 'x_bows:arrow_diamond')

-- sneak, fov adjustments when bow is charged
core.register_globalstep(function(dtime)
    bow_charged_timer = bow_charged_timer + dtime

    if bow_charged_timer > 0.5 then
        for _, player in ipairs(core.get_connected_players()) do
            if player and player:is_valid() then
                local player_name = player:get_player_name()
                local wielded_stack = player:get_wielded_item()
                local wielded_stack_name = wielded_stack and wielded_stack:get_name() or ''

                if not XBows.player_bow_sneak[player_name] then
                    XBows.player_bow_sneak[player_name] = {}
                end

                if core.get_item_group(wielded_stack_name, 'bow_charged') ~= 0
                    and not XBows.player_bow_sneak[player_name].sneak
                then
                    --charged weapon
                    if XBows.playerphysics then
                        playerphysics.add_physics_factor(player, 'speed', 'x_bows:bow_charged_speed', 0.25)
                    elseif XBows.player_monoids then
                        player_monoids.speed:add_change(player, 0.25, 'x_bows:bow_charged_speed')
                    elseif XBows.pova then
                        pova.add_override(player_name, 'x_bows:bow_charged_speed', {speed = -0.75})
                        pova.do_override(player)
                    end

                    XBows.player_bow_sneak[player_name].sneak = true
                    player:set_fov(0.9, true, 0.4)
                elseif core.get_item_group(wielded_stack_name, 'bow_charged') == 0
                    and XBows.player_bow_sneak[player_name].sneak
                then
                    if XBows.playerphysics then
                        playerphysics.remove_physics_factor(player, 'speed', 'x_bows:bow_charged_speed')
                    elseif XBows.player_monoids then
                        player_monoids.speed:del_change(player, 'x_bows:bow_charged_speed')
                    elseif XBows.pova then
                        pova.del_override(player_name, 'x_bows:bow_charged_speed')
                        pova.do_override(player)
                    end

                    XBows.player_bow_sneak[player_name].sneak = false
                    player:set_fov(0, true, 0.4)
                end

                XBows:reset_charged_bow(player)
            end
        end

        bow_charged_timer = 0
    end
end)

local mod_end_time = (core.get_us_time() - mod_start_time) / 1000000

core.log('action', '[x_bows] loaded in ' .. mod_end_time .. 's')
