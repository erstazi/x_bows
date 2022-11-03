unused_args = false
allow_defined_top = true
max_line_length = false

exclude_files = {
    './scripts',
    './bin',
    './logs',
    './node_modules',
    './sounds',
    './textures',
    './models',
    './docs',
    './locale',
    './types',
}

globals = {
    'XBows',
    'XBowsQuiver',
    'XBowsEntityDefBase',
    'XBowsEntityDefCustom'
}

read_globals = {
    "DIR_DELIM", "INIT",

    "minetest", "core",
    "dump", "dump2",

    "Raycast",
    "Settings",
    "PseudoRandom",
    "PerlinNoise",
    "VoxelManip",
    "SecureRandom",
    "VoxelArea",
    "PerlinNoiseMap",
    "PcgRandom",
    "ItemStack",
    "AreaStore",
    "unpack",

    "vector",

    table = {
        fields = {
            "copy",
            "indexof",
            "insert_all",
            "key_value_swap",
            "shuffle",
        }
    },

    string = {
        fields = {
            "split",
            "trim",
        }
    },

    math = {
        fields = {
            "hypot",
            "sign",
            "factorial",
            "round",
        }
    },

    "player_monoids",
    "playerphysics",
    "hb",
    "mesecon",
    "armor",
    "default",
    "i3",
    "unified_inventory",
    "player_api",
    "u_skins",
    "wardrobe",
    "3d_armor",
    "skinsdb",
    "skins"
}
