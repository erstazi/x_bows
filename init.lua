-- X Bows
-- by SaKeL

minetest = minetest--[[@as Minetest]]
ItemStack = ItemStack--[[@as ItemStack]]
vector = vector--[[@as Vector]]
default = default--[[@as MtgDefault]]

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
