XBows:register_particle_effect('arrow', {
    amount = 1,
    time = 0.1,
    minexptime = 0.5,
    maxexptime = 0.5,
    minsize = 2,
    maxsize = 2,
    texture = 'x_bows_arrow_particle.png',
    animation = {
        type = 'vertical_frames',
        aspect_w = 8,
        aspect_h = 8,
        length = 1,
    },
    glow = 1,
    minvel = { x = 0, y = -0.1, z = 0 },
    maxvel = { x = 0, y = -0.1, z = 0 },
    minacc = { x = 0, y = -0.1, z = 0 },
    maxacc = { x = 0, y = -0.1, z = 0 }
})

XBows:register_particle_effect('arrow_crit', {
    amount = 1,
    time = 0.1,
    minexptime = 0.5,
    maxexptime = 0.5,
    minsize = 2,
    maxsize = 2,
    texture = 'x_bows_arrow_particle.png^[colorize:#B22222:127',
    animation = {
        type = 'vertical_frames',
        aspect_w = 8,
        aspect_h = 8,
        length = 1,
    },
    glow = 1,
    minvel = { x = 0, y = -0.1, z = 0 },
    maxvel = { x = 0, y = -0.1, z = 0 },
    minacc = { x = 0, y = -0.1, z = 0 },
    maxacc = { x = 0, y = -0.1, z = 0 }
})

XBows:register_particle_effect('arrow_fast', {
    amount = 1,
    time = 0.1,
    minexptime = 0.5,
    maxexptime = 0.5,
    minsize = 2,
    maxsize = 2,
    texture = 'x_bows_arrow_particle.png^[colorize:#0000FF:64',
    animation = {
        type = 'vertical_frames',
        aspect_w = 8,
        aspect_h = 8,
        length = 1,
    },
    glow = 1,
    minvel = { x = 0, y = -0.1, z = 0 },
    maxvel = { x = 0, y = -0.1, z = 0 },
    minacc = { x = 0, y = -0.1, z = 0 },
    maxacc = { x = 0, y = -0.1, z = 0 }
})

XBows:register_particle_effect('bubble', {
    amount = 1,
    time = 1,
    minvel = { x = 1, y = 1, z = 0 },
    maxvel = { x = 1, y = 1, z = 0 },
    minacc = { x = 1, y = 1, z = 1 },
    maxacc = { x = 1, y = 1, z = 1 },
    minexptime = 0.2,
    maxexptime = 0.5,
    minsize = 0.5,
    maxsize = 1,
    texture = 'x_bows_bubble.png'
})
