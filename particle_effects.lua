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

XBows:register_particle_effect('arrow', {
    amount = 26,
    time = 0,
    -- Modern Luanti particle definition (v5.6+ / v5.8+)
    pos = {
        min = { x = -0.03, y = -0.03, z = -0.45 },
        max = { x = 0.03, y = 0.03, z = -0.35 }
    },
    vel = {
        min = { x = -0.04, y = -0.04, z = -0.6 },
        max = { x = 0.04, y = 0.04, z = -0.2 }
    },
    acc = {
        min = { x = 0, y = -0.1, z = 0 },
        max = { x = 0, y = -0.05, z = 0 }
    },
    exptime = { min = 0.25, max = 0.40 },
    size = { min = 0.8, max = 1.3 },
    glow = 1,
    drag = { x = 2.0, y = 1.0, z = 2.0 },
    texture = {
        name = 'x_bows_arrow_particle.png',
        alpha_tween = { 0.85, 0.0 }, -- Fades out smoothly along the tail
        scale_tween = { { x = 1.1, y = 1.1 }, { x = 0.3, y = 0.3 } }, -- Tapers cleanly behind arrow
        blend = 'alpha'
    },
    animation = {
        type = 'vertical_frames',
        aspect_w = 8,
        aspect_h = 8,
        length = 0.35,
    },

    -- Graceful fallback fields for legacy / older clients (< v5.6)
    minpos = { x = -0.03, y = -0.03, z = -0.45 },
    maxpos = { x = 0.03, y = 0.03, z = -0.35 },
    minvel = { x = -0.04, y = -0.04, z = -0.6 },
    maxvel = { x = 0.04, y = 0.04, z = -0.2 },
    minacc = { x = 0, y = -0.1, z = 0 },
    maxacc = { x = 0, y = -0.05, z = 0 },
    minexptime = 0.25,
    maxexptime = 0.40,
    minsize = 0.8,
    maxsize = 1.3,
})

XBows:register_particle_effect('arrow_crit', {
    amount = 30,
    time = 0,
    -- Modern Luanti particle definition (v5.6+ / v5.8+)
    pos = {
        min = { x = -0.03, y = -0.03, z = -0.45 },
        max = { x = 0.03, y = 0.03, z = -0.35 }
    },
    vel = {
        min = { x = -0.04, y = -0.04, z = -0.7 },
        max = { x = 0.04, y = 0.04, z = -0.2 }
    },
    acc = {
        min = { x = 0, y = -0.1, z = 0 },
        max = { x = 0, y = -0.05, z = 0 }
    },
    exptime = { min = 0.28, max = 0.45 },
    size = { min = 0.9, max = 1.4 },
    glow = 3,
    drag = { x = 2.0, y = 1.0, z = 2.0 },
    texture = {
        name = 'x_bows_arrow_particle.png^[colorize:#B22222:127',
        alpha_tween = { 0.9, 0.0 },
        scale_tween = { { x = 1.2, y = 1.2 }, { x = 0.3, y = 0.3 } },
        blend = 'alpha'
    },
    animation = {
        type = 'vertical_frames',
        aspect_w = 8,
        aspect_h = 8,
        length = 0.35,
    },

    -- Graceful fallback fields for legacy / older clients (< v5.6)
    minpos = { x = -0.03, y = -0.03, z = -0.45 },
    maxpos = { x = 0.03, y = 0.03, z = -0.35 },
    minvel = { x = -0.04, y = -0.04, z = -0.7 },
    maxvel = { x = 0.04, y = 0.04, z = -0.2 },
    minacc = { x = 0, y = -0.1, z = 0 },
    maxacc = { x = 0, y = -0.05, z = 0 },
    minexptime = 0.28,
    maxexptime = 0.45,
    minsize = 0.9,
    maxsize = 1.4,
})

XBows:register_particle_effect('arrow_fast', {
    amount = 30,
    time = 0,
    -- Modern Luanti particle definition (v5.6+ / v5.8+)
    pos = {
        min = { x = -0.03, y = -0.03, z = -0.45 },
        max = { x = 0.03, y = 0.03, z = -0.35 }
    },
    vel = {
        min = { x = -0.04, y = -0.04, z = -0.7 },
        max = { x = 0.04, y = 0.04, z = -0.2 }
    },
    acc = {
        min = { x = 0, y = -0.1, z = 0 },
        max = { x = 0, y = -0.05, z = 0 }
    },
    exptime = { min = 0.28, max = 0.45 },
    size = { min = 0.9, max = 1.4 },
    glow = 2,
    drag = { x = 2.0, y = 1.0, z = 2.0 },
    texture = {
        name = 'x_bows_arrow_particle.png^[colorize:#0000FF:32',
        alpha_tween = { 0.9, 0.0 },
        scale_tween = { { x = 1.2, y = 1.2 }, { x = 0.3, y = 0.3 } },
        blend = 'alpha'
    },
    animation = {
        type = 'vertical_frames',
        aspect_w = 8,
        aspect_h = 8,
        length = 0.35,
    },

    -- Graceful fallback fields for legacy / older clients (< v5.6)
    minpos = { x = -0.03, y = -0.03, z = -0.45 },
    maxpos = { x = 0.03, y = 0.03, z = -0.35 },
    minvel = { x = -0.04, y = -0.04, z = -0.7 },
    maxvel = { x = 0.04, y = 0.04, z = -0.2 },
    minacc = { x = 0, y = -0.1, z = 0 },
    maxacc = { x = 0, y = -0.05, z = 0 },
    minexptime = 0.28,
    maxexptime = 0.45,
    minsize = 0.9,
    maxsize = 1.4,
})

XBows:register_particle_effect('bubble', {
    amount = 4,
    time = 0,
    -- Modern Luanti particle definition (v5.6+ / v5.8+)
    pos = {
        min = { x = -0.05, y = -0.05, z = -0.05 },
        max = { x = 0.05, y = 0.05, z = 0.05 }
    },
    vel = {
        min = { x = -0.05, y = 0.2, z = -0.05 },
        max = { x = 0.05, y = 0.5, z = 0.05 }
    },
    acc = {
        min = { x = 0, y = 0.2, z = 0 },
        max = { x = 0, y = 0.5, z = 0 }
    },
    exptime = { min = 0.3, max = 0.7 },
    size = { min = 0.5, max = 1.2 },
    jitter = {
        min = { x = -0.05, y = 0, z = -0.05 },
        max = { x = 0.05, y = 0, z = 0.05 }
    },
    drag = { x = 1.0, y = 0.0, z = 1.0 },
    texture = {
        name = 'x_bows_bubble.png',
        alpha_tween = { 0.9, 0.0 }, -- Fades out smoothly as bubble reaches end of life
        scale_tween = { { x = 0.6, y = 0.6 }, { x = 1.2, y = 1.2 } }, -- Naturally expands as water pressure drops
        blend = 'alpha'
    },

    -- Graceful fallback fields for legacy / older clients (< v5.6)
    minpos = { x = -0.05, y = -0.05, z = -0.05 },
    maxpos = { x = 0.05, y = 0.05, z = 0.05 },
    minvel = { x = -0.05, y = 0.2, z = -0.05 },
    maxvel = { x = 0.05, y = 0.5, z = 0.05 },
    minacc = { x = 0, y = 0.2, z = 0 },
    maxacc = { x = 0, y = 0.5, z = 0 },
    minexptime = 0.3,
    maxexptime = 0.7,
    minsize = 0.5,
    maxsize = 1.2,
})
