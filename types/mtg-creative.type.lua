---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---Minetest game creative mod
---@class MtgCreative
---@field is_enabled_for fun(name: string): boolean Returning `true` means that Creative Mode is enabled for player `name`. `name` will be `""` for non-players or if the player is unknown. By default, this function returns `true` if the setting `creative_mode` is `true` and `false` otherwise.
