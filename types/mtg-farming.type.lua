---https://github.com/sumneko/lua-language-server/wiki

---Minetest game farming mod

----Node definition. Used by `minetest.register_node`.
---@class NodeDefMtgFarming
---@field fertility string[]|nil Used in default farming mod, defines biome name list where plants can grow
---@field steps number How many steps the plant has to grow, until it can be harvested
---@field minlight number Minimum light to grow
---@field maxlight number Maximum light to grow
