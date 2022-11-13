---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---Minetest game farming mod
---@class MtgFarming
---@field hoe_on_use fun(itemstack: ItemStack, user: ObjectRef, pointed_thing: PointedThingDef, uses: number): ItemStack | nil
---@field place_seed fun(itemstack: ItemStack, placer: ObjectRef, pointed_thing: PointedThingDef, plantname: string): ItemStack Seed placement
---@field grow_plant fun(pos: Vector, elapsed: number): nil
---@field register_plant fun(name: string, def: table): nil

----Node definition. Used by `minetest.register_node`.
---@class NodeDefMtgFarming
---@field fertility string[]|nil Used in default farming mod, defines biome name list where plants can grow
---@field steps number How many steps the plant has to grow, until it can be harvested
---@field minlight number Minimum light to grow
---@field maxlight number Maximum light to grow
---@field on_timer fun(pos: Vector, elapsed: number): boolean default: nil, called by NodeTimers, see minetest.get_node_timer and NodeTimerRef. elapsed is the total time passed since the timer was started. return true to run the timer for another cycle with the same timeout value.
