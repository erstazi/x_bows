---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---A raycast on the map. It works with selection boxes. The map is loaded as the ray advances. If the map is modified after the `Raycast` is created, the changes may or may not have an effect on the object.
---@class Raycast
---@field next fun(): PointedThingDef Returns a `pointed_thing` with exact pointing location. Returns the next thing pointed by the ray or nil.
