---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---Minetest game dungeon loot mod API
---@class MtgDungeonLoot
---@field register fun(loot_definition: MtgDungeonLootDef): nil Registers one or more loot items, `def` Can be a single loot_definition or a list of them.
---@field registered_loot table Table of all registered loot, not to be modified manually

---Loot definition
---@class MtgDungeonLootDef
---@field name string
---@field chance number chance value from 0.0 to 1.0 that the item will appear in the chest when chosen, Due to an extra step in the selection process, 0.5 does not(!) mean that on average every second chest will have this item
---@field count number[]|nil table with minimum and maximum amounts of this item, optional, defaults to always single item
---@field y number[]|nil table with minimum and maximum heights this item can be found at, optional, defaults to no height restrictions
---@field types string[]|nil table with types of dungeons this item can be found in supported types: "normal" (the cobble/mossycobble one), "sandstone", "desert" and "ice", optional, defaults to no type restrictions
