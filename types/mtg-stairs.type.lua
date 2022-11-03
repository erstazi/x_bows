---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---Minetest game stairs mod
---@class MtgStairs
---@field register_stair_and_slab fun(subname: string, recipeitem?: string, groups: GroupCapsDef, images: NodeTilesDef, desc_stair: string, desc_slab: string, sounds: NodeSoundDef, worldaligntex?: boolean, desc_stair_inner?: string, desc_stair_outer?: string): nil `subname`: Basically the material name (e.g. cobble) used for the stair name. Nodename pattern: "stairs:stair_subname", `recipeitem`: Item used in the craft recipe, e.g. "default:cobble", may be `nil`, `groups`: damage and digging time defining groups, `worldaligntex`: A bool to set all textures world-aligned. Default false.
