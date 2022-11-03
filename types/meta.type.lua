---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---@alias ItemStackMetaRef MetaDataRef|ItemStackMetaRefAbstract
---@alias NodeMetaRef MetaDataRef|NodeMetaRefAbstract
---@alias PlayerMetaRef MetaDataRef|PlayerMetaRefAbstract
---@alias StorageRef MetaDataRef|StorageRefAbstract

---Base class used by [`StorageRef`], [`NodeMetaRef`], [`ItemStackMetaRef`], and [`PlayerMetaRef`].
---@class MetaDataRef
---@field contains fun(self: MetaDataRef, key: string): boolean|nil Returns true if key present, otherwise false. Returns `nil` when the MetaData is inexistent.
---@field get fun(self: MetaDataRef, key: string): string|nil Returns `nil` if key not present, else the stored string.
---@field set_string fun(self: MetaDataRef, key: string, value: string): string Value of `""` will delete the key.
---@field get_string fun(self: MetaDataRef, key: string): string Returns `""` if key not present.
---@field set_int fun(self: MetaDataRef, key: string, value: integer): nil
---@field get_int fun(self: MetaDataRef, key: string): integer|number Returns `0` if key not present.
---@field set_float fun(self: MetaDataRef, key: string, value: number): nil
---@field get_float fun(self: MetaDataRef, key): integer|number Returns `0` if key not present.
---@field to_table fun(): nil Returns `nil` or a table with keys: `fields`: key-value storage `inventory`: `{list1 = {}, ...}}` (NodeMetaRef only)
---@field from_table fun(self: MetaDataRef, t: nil|table): boolean Any non-table value will clear the metadata. Returns `true` on success
---@field equals fun(self: MetaDataRef, other: any): boolean Returns `true` if this metadata has the same key-value pairs as `other`

---ItemStack metadata: reference extra data and functionality stored in a stack. Can be obtained via `item:get_meta()`.
---@class ItemStackMetaRefAbstract
---@field set_tool_capabilities fun(self: ItemStackMetaRef, tool_capabilities?: table): nil Overrides the item's tool capabilities. A nil value will clear the override data and restore the original behavior.

---Node metadata: reference extra data and functionality stored in a node. Can be obtained via `minetest.get_meta(pos)`.
---@class NodeMetaRefAbstract
---@field get_inventory fun(self: NodeMetaRef): InvRef
---@field mark_as_private fun(self: NodeMetaRef, name: string | table<string[]>) Mark specific vars as private This will prevent them from being sent to the client. Note that the "private" status will only be remembered if an associated key-value pair exists, meaning it's best to call this when initializing all other meta (e.g. `on_construct`).

---Player metadata. Uses the same method of storage as the deprecated player attribute API, so data there will also be in player meta. Can be obtained using `player:get_meta()`.
---@class PlayerMetaRefAbstract

---Mod metadata: per mod metadata, saved automatically. Can be obtained via `minetest.get_mod_storage()` during load time. WARNING: This storage backend is incapable of saving raw binary data due to restrictions of JSON.
---@class StorageRefAbstract
