unused_args = false
allow_defined_top = true
max_line_length = false

globals = {
	'x_bows'
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
			"factorial"
		}
	},

	"player_monoids",
	"playerphysics",
	"hb",
	"mesecon",
	"armor",
	"default"
}
