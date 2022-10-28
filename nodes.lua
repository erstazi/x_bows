local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_node('x_bows:target', {
    description = S('Target'),
    short_description = S('Target'),
    tiles = {'x_bows_target.png'},
    is_ground_content = false,
    groups = {snappy=3, flammable=4, fall_damage_add_percent = -30},
    sounds = minetest.global_exists('default') and default.node_sound_leaves_defaults() or {},
    mesecons = {receptor = {state = 'off'}},
    ---@param pos Vector
    ---@param elapsed number
    ---@return boolean
    on_timer = function (pos, elapsed)
        if XBows.mesecons then
            mesecon.receptor_off(pos)
        end

        return false
    end
})

minetest.register_craft({
    type = 'fuel',
    recipe = 'x_bows:target',
    burntime = 3
})

minetest.register_craft({
    output = 'x_bows:target',
    recipe = {
        {'', 'default:mese_crystal', ''},
        {'default:mese_crystal', 'farming:straw', 'default:mese_crystal'},
        {'', 'default:mese_crystal', ''},
    }
})
