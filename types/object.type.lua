---https://github.com/sumneko/lua-language-server/wiki

---@alias ObjectRef ObjectRefAbstract|ObjectRefLuaEntityRef

---Moving things in the game are generally these.
---This is basically a reference to a C++ `ServerActiveObject`.
---@class ObjectRefAbstract
---@field get_pos fun(): Vector Position of player
---@field get_inventory fun(): InvRef|nil Returns an `InvRef` for players, otherwise returns `nil`
---@field get_wield_index fun(): integer Returns the index of the wielded item
---@field get_wielded_item fun(): ItemStack Returns an `ItemStack`
---@field set_acceleration fun(self: ObjectRef, acc: Vector): nil
---@field set_yaw fun(self: ObjectRef, yaw: integer|number): nil Sets the yaw in radians (heading).
---@field get_player_name fun(self: ObjectRef): string Returns `""` if is not a player.
---@field set_fov fun(self: ObjectRef, fov: number|integer, is_multiplier: boolean, transition_time: number|integer): nil Sets player's FOV. `fov`: FOV value. `is_multiplier`: Set to `true` if the FOV value is a multiplier. Defaults to `false`. `transition_time`: If defined, enables smooth FOV transition. Interpreted as the time (in seconds) to reach target FOV. If set to 0, FOV change is instantaneous. Defaults to 0. Set `fov` to 0 to clear FOV override.
---@field get_hp fun(self: ObjectRef): number|integer Returns number of health points
---@field is_player fun(self: ObjectRef): boolean returns true for players, false otherwise
---@field get_luaentity fun(self: ObjectRef): table
---@field get_armor_groups fun(self: ObjectRef): ObjectRefArmorGroups returns a table with the armor group ratings
---@field punch fun(self: ObjectRef, puncher: ObjectRef, time_from_last_punch: integer|number, tool_capabilities: ToolCapabilitiesDef, direction: Vector|nil): nil
---@field add_velocity fun(self: ObjectRef, vel: Vector): nil `vel` is a vector, e.g. `{x=0.0, y=2.3, z=1.0}`. In comparison to using get_velocity, adding the velocity and then using set_velocity, add_velocity is supposed to avoid synchronization problems. Additionally, players also do not support set_velocity. If a player: Does not apply during free_move. Note that since the player speed is normalized at each move step, increasing e.g. Y velocity beyond what would usually be achieved (see: physics overrides) will cause existing X/Z velocity to be reduced. Example: `add_velocity({x=0, y=6.5, z=0})` is equivalent to pressing the jump key (assuming default settings)
---@field get_properties fun(self: ObjectRef): table Returns object property table
---@field get_children fun(self: ObjectRef): ObjectRef[] Returns a list of ObjectRefs that are attached to the object.

---Moving things in the game are generally these.
---This is basically a reference to a C++ `ServerActiveObject`.
---@class ObjectRefLuaEntityRef
---@field set_velocity fun(self: ObjectRef, vel: Vector): nil `vel` is a vector, e.g. `{x=0.0, y=2.3, z=1.0}`
---@field remove fun(): nil remove object, The object is removed after returning from Lua. However the `ObjectRef` itself instantly becomes unusable with all further method calls having no effect and returning `nil`.

---`ObjectRef` armor groups
---@class ObjectRefArmorGroups
---@field immortal number|integer Skips all damage and breath handling for an object. This group will also hide the integrated HUD status bars for players. It is automatically set to all players when damage is disabled on the server and cannot be reset (subject to change).
---@field fall_damage_add_percent number|integer Modifies the fall damage suffered by players when they hit the ground. It is analog to the node group with the same name. See the node group above for the exact calculation.
---@field punch_operable number|integer For entities; disables the regular damage mechanism for players punching it by hand or a non-tool item, so that it can do something else than take damage.
