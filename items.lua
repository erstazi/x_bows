local S = minetest.get_translator(minetest.get_current_modname())

XBows:register_bow('bow_wood', {
    description = S('Wooden Bow'),
    short_description = S('Wooden Bow'),
    custom = {
        uses = 385,
        crit_chance = 10,
        recipe = {
            { '', 'default:stick', 'farming:string' },
            { 'default:stick', '', 'farming:string' },
            { '', 'default:stick', 'farming:string' }
        },
        fuel_burntime = 3,
        allowed_ammunition = {
            'x_bows:arrow_wood',
            'x_bows:arrow_stone',
            'x_bows:arrow_bronze',
            'x_bows:arrow_steel',
            'x_bows:arrow_mese',
            'x_bows:arrow_diamond'
        }
    }
})

XBows:register_arrow('arrow_wood', {
    description = S('Arrow Wood'),
    short_description = S('Arrow Wood'),
    inventory_image = 'x_bows_arrow_wood.png',
    custom = {
        recipe = {
            { 'default:flint' },
            { 'group:stick' },
            { 'group:wool' }
        },
        tool_capabilities = {
            full_punch_interval = 1,
            max_drop_level = 0,
            damage_groups = { fleshy = 2 }
        },
        fuel_burntime = 1
    }
})

XBows:register_arrow('arrow_stone', {
    description = S('Arrow Stone'),
    short_description = S('Arrow Stone'),
    inventory_image = 'x_bows_arrow_stone.png',
    custom = {
        recipe = {
            { 'default:flint' },
            { 'group:stone' },
            { 'group:wool' }
        },
        tool_capabilities = {
            full_punch_interval = 1.2,
            max_drop_level = 0,
            damage_groups = { fleshy = 4 }
        }
    }
})

XBows:register_arrow('arrow_bronze', {
    description = S('Arrow Bronze'),
    short_description = S('Arrow Bronze'),
    inventory_image = 'x_bows_arrow_bronze.png',
    custom = {
        recipe = {
            { 'default:flint' },
            { 'default:bronze_ingot' },
            { 'group:wool' }
        },
        tool_capabilities = {
            full_punch_interval = 0.8,
            max_drop_level = 1,
            damage_groups = { fleshy = 6 }
        }
    }
})

XBows:register_arrow('arrow_steel', {
    description = S('Arrow Steel'),
    short_description = S('Arrow Steel'),
    inventory_image = 'x_bows_arrow_steel.png',
    custom = {
        recipe = {
            { 'default:flint' },
            { 'default:steel_ingot' },
            { 'group:wool' }
        },
        tool_capabilities = {
            full_punch_interval = 0.7,
            max_drop_level = 1,
            damage_groups = { fleshy = 6 }
        }
    }
})

XBows:register_arrow('arrow_mese', {
    description = S('Arrow Mese'),
    short_description = S('Arrow Mese'),
    inventory_image = 'x_bows_arrow_mese.png',
    custom = {
        recipe = {
            { 'default:flint' },
            { 'default:mese_crystal' },
            { 'group:wool' }
        },
        tool_capabilities = {
            full_punch_interval = 0.7,
            max_drop_level = 1,
            damage_groups = { fleshy = 7 }
        }
    }
})

XBows:register_arrow('arrow_diamond', {
    description = S('Arrow Diamond'),
    short_description = S('Arrow Diamond'),
    inventory_image = 'x_bows_arrow_diamond.png',
    custom = {
        recipe = {
            { 'default:flint' },
            { 'default:diamond' },
            { 'group:wool' }
        },
        tool_capabilities = {
            full_punch_interval = 0.7,
            max_drop_level = 1,
            damage_groups = { fleshy = 8 }
        }
    }
})

XBows:register_quiver('quiver', {
    description = S('Quiver') .. '\n\n' .. S('Empty') .. '\n',
    short_description = S('Quiver'),
    custom = {
        description = S('Quiver') .. '\n\n' .. S('Empty') .. '\n',
        short_description = S('Quiver'),
        recipe = {
            { 'group:arrow', 'group:arrow', 'group:arrow' },
            { 'group:arrow', 'wool:brown', 'group:arrow' },
            { 'group:arrow', 'group:arrow', 'group:arrow' }
        },
        recipe_count = 1,
        faster_arrows = 5,
        add_damage = 2,
        fuel_burntime = 3
    }
})
