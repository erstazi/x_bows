-- X Bows
-- by SaKeL

minetest = minetest--[[@as Minetest]]
ItemStack = ItemStack--[[@as ItemStack]]
vector = vector--[[@as Vector]]
default = default--[[@as MtgDefault]]
sfinv = sfinv--[[@as Sfinv]]

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9))--[[@as number]])

local path = minetest.get_modpath('x_bows')
local mod_start_time = minetest.get_us_time()
local bow_charged_timer = 0

dofile(path .. '/api.lua')
dofile(path .. '/particle_effects.lua')
dofile(path .. '/nodes.lua')
dofile(path .. '/arrow.lua')
dofile(path .. '/items.lua')
dofile(path .. '/quiver.lua')


if XBows.i3 then
    XBowsQuiver:i3_register_page()
elseif XBows.unified_inventory then
    XBowsQuiver:ui_register_page()
else
    XBowsQuiver:sfinv_register_page()
end

minetest.register_on_joinplayer(function(player)
    local inv_quiver = player:get_inventory()--[[@as InvRef]]
    local inv_arrow = player:get_inventory()--[[@as InvRef]]

    inv_quiver:set_size('x_bows:quiver_inv', 1 * 1)
    inv_arrow:set_size('x_bows:arrow_inv', 1 * 1)

    local quiver = player:get_inventory():get_stack('x_bows:quiver_inv', 1)

    if quiver and not quiver:is_empty() then
        local st_meta = quiver:get_meta()
        local quiver_id = st_meta:get_string('quiver_id')

        XBowsQuiver:get_or_create_detached_inv(
            quiver_id,
            player:get_player_name(),
            st_meta:get_string('quiver_items')
        )
    end
end)

---formspec callbacks
minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    ---arrow inventory
    if action == 'move' and inventory_info.to_list == 'x_bows:arrow_inv' then
        local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)

        if minetest.get_item_group(stack:get_name(), 'arrow') ~= 0 then
            return inventory_info.count
        else
            return 0
        end
    elseif action == 'move' and inventory_info.from_list == 'x_bows:arrow_inv' then
        local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)

        if minetest.get_item_group(stack:get_name(), 'arrow') ~= 0 then
            return inventory_info.count
        else
            return 0
        end
    elseif action == 'put' and inventory_info.listname == 'x_bows:arrow_inv' then
        if minetest.get_item_group(inventory_info.stack:get_name(), 'arrow') ~= 0 then
            return inventory_info.stack:get_count()
        else
            return 0
        end
    elseif action == 'take' and inventory_info.listname == 'x_bows:arrow_inv' then
        if minetest.get_item_group(inventory_info.stack:get_name(), 'arrow') ~= 0 then
            return inventory_info.stack:get_count()
        else
            return 0
        end
    end

    ---quiver inventory
    if action == 'move' and inventory_info.to_list == 'x_bows:quiver_inv' then
        local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
        if minetest.get_item_group(stack:get_name(), 'quiver') ~= 0 then
            return inventory_info.count
        else
            return 0
        end
    elseif action == 'move' and inventory_info.from_list == 'x_bows:quiver_inv' then
        local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
        if minetest.get_item_group(stack:get_name(), 'quiver') ~= 0 then
            return inventory_info.count
        else
            return 0
        end
    elseif action == 'put' and inventory_info.listname == 'x_bows:quiver_inv' then
        if minetest.get_item_group(inventory_info.stack:get_name(), 'quiver') ~= 0 then
            return inventory_info.stack:get_count()
        else
            return 0
        end
    elseif action == 'take' and inventory_info.listname == 'x_bows:quiver_inv' then
        if minetest.get_item_group(inventory_info.stack:get_name(), 'quiver') ~= 0 then
            return inventory_info.stack:get_count()
        else
            return 0
        end
    end

    return inventory_info.count or inventory_info.stack:get_count()
end)

minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
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
    if action == 'move' and inventory_info.to_list == 'x_bows:quiver_inv' then
        local stack = inventory:get_stack(inventory_info.to_list, inventory_info.to_index)

        ---init detached inventory if not already
        local st_meta = stack:get_meta()
        local quiver_id = st_meta:get_string('quiver_id')

        if quiver_id == '' then
            quiver_id = stack:get_name()..'_'..XBows.uuid()
            st_meta:set_string('quiver_id', quiver_id)
            inventory:set_stack(inventory_info.to_list, inventory_info.to_index, stack)
        end

        XBowsQuiver:get_or_create_detached_inv(
            quiver_id,
            player:get_player_name(),
            st_meta:get_string('quiver_items')
        )

        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end

    elseif action == 'move' and inventory_info.from_list == 'x_bows:quiver_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    elseif action == 'put' and inventory_info.listname == 'x_bows:quiver_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    elseif action == 'take' and inventory_info.listname == 'x_bows:quiver_inv' then
        if XBows.i3 then
            i3.set_fs(player)
        elseif XBows.unified_inventory then
            unified_inventory.set_inventory_formspec(player, 'x_bows:quiver_page')
        else
            sfinv.set_player_inventory_formspec(player)
        end
    end
end)

---backwards compatibility
minetest.register_alias('x_bows:arrow_diamond_tipped_poison', 'x_bows:arrow_diamond')

minetest.register_on_joinplayer(function(player)
    XBows:reset_charged_bow(player, true)
    XBowsQuiver:close_quiver(player)
end)

-- sneak, fov adjustments when bow is charged
minetest.register_globalstep(function(dtime)
    bow_charged_timer = bow_charged_timer + dtime

    if bow_charged_timer > 0.5 then
        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()
            local wielded_stack = player:get_wielded_item()
            local wielded_stack_name = wielded_stack:get_name()

            if not wielded_stack_name then
                return
            end

            if not XBows.player_bow_sneak[player_name] then
                XBows.player_bow_sneak[player_name] = {}
            end

            if minetest.get_item_group(wielded_stack_name, 'bow_charged') ~= 0 and not XBows.player_bow_sneak[player_name].sneak then
                --charged weapon
                if XBows.playerphysics then
                    playerphysics.add_physics_factor(player, 'speed', 'x_bows:bow_charged_speed', 0.25)
                elseif XBows.player_monoids then
                    player_monoids.speed:add_change(player, 0.25, 'x_bows:bow_charged_speed')
                end

                XBows.player_bow_sneak[player_name].sneak = true
                player:set_fov(0.9, true, 0.4)
            elseif minetest.get_item_group(wielded_stack_name, 'bow_charged') == 0 and XBows.player_bow_sneak[player_name].sneak then
                if XBows.playerphysics then
                    playerphysics.remove_physics_factor(player, 'speed', 'x_bows:bow_charged_speed')
                elseif XBows.player_monoids then
                    player_monoids.speed:del_change(player, 'x_bows:bow_charged_speed')
                end

                XBows.player_bow_sneak[player_name].sneak = false
                player:set_fov(0, true, 0.4)
            end

            XBows:reset_charged_bow(player)
        end

        bow_charged_timer = 0
    end
end)

local mod_end_time = (minetest.get_us_time() - mod_start_time) / 1000000

print('[Mod] x_bows loaded.. ['.. mod_end_time ..'s]')
