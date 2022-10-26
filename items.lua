XBows:register_bow('bow_wood', {
    description = 'Wooden Bow',
    short_description = 'Wooden Bow',
    custom = {
        uses = 385,
        crit_chance = 10,
        recipe = {
            {'', 'default:stick', 'farming:string'},
            {'default:stick', '', 'farming:string'},
            {'', 'default:stick', 'farming:string'}
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
    description = 'Arrow Wood',
    short_description = 'Arrow Wood',
    inventory_image = 'x_bows_arrow_wood.png',
    custom = {
        recipe = {
            {'default:flint'},
            {'group:stick'},
            {'group:wool'}
        },
        tool_capabilities = {
            full_punch_interval = 1,
            max_drop_level = 0,
            damage_groups = {fleshy=2}
        },
        fuel_burntime = 1
    }
})

XBows:register_arrow('arrow_stone', {
    description = 'Arrow Stone',
    short_description = 'Arrow Stone',
    inventory_image = 'x_bows_arrow_stone.png',
    custom = {
        recipe = {
            {'default:flint'},
            {'group:stone'},
            {'group:wool'}
        },
        tool_capabilities = {
            full_punch_interval = 1.2,
            max_drop_level = 0,
            damage_groups = {fleshy=4}
        }
    }
})

XBows:register_arrow('arrow_bronze', {
    description = 'Arrow Bronze',
    short_description = 'Arrow Bronze',
    inventory_image = 'x_bows_arrow_bronze.png',
    custom = {
        recipe = {
            {'default:flint'},
            {'default:bronze_ingot'},
            {'group:wool'}
        },
        tool_capabilities = {
            full_punch_interval = 0.8,
            max_drop_level = 1,
            damage_groups = {fleshy=6}
        }
    }
})

XBows:register_arrow('arrow_steel', {
    description = 'Arrow Steel',
    short_description = 'Arrow Steel',
    inventory_image = 'x_bows_arrow_steel.png',
    custom = {
        recipe = {
            {'default:flint'},
            {'default:steel_ingot'},
            {'group:wool'}
        },
        tool_capabilities = {
            full_punch_interval = 0.7,
            max_drop_level = 1,
            damage_groups = {fleshy=6}
        }
    }
})

XBows:register_arrow('arrow_mese', {
    description = 'Arrow Mese',
    short_description = 'Arrow Mese',
    inventory_image = 'x_bows_arrow_mese.png',
    custom = {
        recipe = {
            {'default:flint'},
            {'default:mese_crystal'},
            {'group:wool'}
        },
        tool_capabilities = {
            full_punch_interval = 0.7,
            max_drop_level = 1,
            damage_groups = {fleshy=7}
        }
    }
})

XBows:register_arrow('arrow_diamond', {
    description = 'Arrow Diamond',
    short_description = 'Arrow Diamond',
    inventory_image = 'x_bows_arrow_diamond.png',
    custom = {
        recipe = {
            {'default:flint'},
            {'default:diamond'},
            {'group:wool'}
        },
        tool_capabilities = {
            full_punch_interval = 0.7,
            max_drop_level = 1,
            damage_groups = {fleshy=8}
        }
    }
})

XBows:register_quiver('quiver', {
    description = 'Quiver \n\n Empty\n',
    short_description = 'Quiver',
    custom = {
        description = 'Quiver \n\n Empty\n',
        short_description = 'Quiver',
        recipe = {
            {'group:arrow', 'group:arrow', 'group:arrow'},
            {'group:arrow', 'wool:brown', 'group:arrow'},
            {'group:arrow', 'group:arrow', 'group:arrow'}
        },
        recipe_count = 1,
        faster_arrows = 5,
        add_damage = 2,
        fuel_burntime = 3
    }
})
