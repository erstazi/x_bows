minetest.register_node('x_bows:arrow_node', {
    drawtype = 'mesh',
    mesh = 'x_bows_arrow.obj',
    tiles = {'x_bows_arrow_mesh.png'},
    groups = {not_in_creative_inventory=1},
    sunlight_propagates = true,
    paramtype = 'light',
    collision_box = {0, 0, 0, 0, 0, 0},
    selection_box = {0, 0, 0, 0, 0, 0}
})

minetest.register_node('x_bows:target', {
    description = 'Straw',
    tiles = {'x_bows_target.png'},
    is_ground_content = false,
    groups = {snappy=3, flammable=4, fall_damage_add_percent=-30},
    sounds = default.node_sound_leaves_defaults(),
    mesecons = {receptor = {state = 'off'}},
    on_timer = function (pos, elapsed)
        mesecon.receptor_off(pos)
        return false
    end,
})

minetest.register_craft({
    type = 'fuel',
    recipe = 'x_bows:target',
    burntime = 3,
})

minetest.register_craft({
    output = 'x_bows:target',
    recipe = {
        {'', 'default:mese_crystal', ''},
        {'default:mese_crystal', 'farming:straw', 'default:mese_crystal'},
        {'', 'default:mese_crystal', ''},
    }
})
