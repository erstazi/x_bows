XBows:register_entity('arrow_entity', {
    initial_properties = {
        visual = 'mesh',
        mesh = 'x_bows_arrow.b3d',
        textures = {'x_bows_arrow_mesh.png'},
    },
    _custom = {
        animations = {
            idle = {{x = 41, y = 42}, 0, 0, false},
            on_hit_node = {{x = 1, y = 40}, 40, 0, false}
        }
    }
})
