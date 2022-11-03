---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---Specifies a sound name, gain (=volume) and pitch. This is either a string or a table. In string form, you just specify the sound name or the empty string for no sound.
---@class SimpleSoundSpec
---@field name string  Sound name.
---@field gain number|integer Volume (`1.0` = 100%). Optional and default to `1.0`.
---@field pitch number|integer Pitch (`1.0` = 100%). Optional and default to `1.0`.

--- Definition of node sounds to be played at various events.
---@class NodeSoundDef
---@field name string  Sound name.
---@field footstep SimpleSoundSpec  If walkable, played when object walks on it. If node is climbable or a liquid, played when object moves through it
---@field dig SimpleSoundSpec|'__group' While digging node. If `"__group"`, then the sound will be `default_dig_<groupname>`, where `<groupname>` is the name of the item's digging group with the fastest digging time. In case of a tie, one of the sounds will be played (but we cannot predict which one) Default value: `"__group"`
---@field dug SimpleSoundSpec Node was dug
---@field place SimpleSoundSpec Node was placed. Also played after falling
---@field place_failed SimpleSoundSpec When node placement failed. Note: This happens if the _built-in_ node placement failed. This sound will still be played if the node is placed in the `on_place` callback manually.
---@field fall SimpleSoundSpec  When node starts to fall or is detached

---Definition of item sounds to be played at various events.  All fields in this table are optional.
---@class ItemSoundDef
---@field breaks SimpleSoundSpec|string When tool breaks due to wear. Ignored for non-tools
---@field eat SimpleSoundSpec|string When item is eaten with `minetest.do_item_eat`
---@field punch_use SimpleSoundSpec|string  When item is used with the 'punch/mine' key pointing at a node or entity
---@field punch_use_air SimpleSoundSpec|string When item is used with the 'punch/mine' key pointing at nothing (air)

---Dig params definition.
---@class DigParamsDef
