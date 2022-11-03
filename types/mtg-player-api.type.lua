---@diagnostic disable: codestyle-check
---The player API can register player models and update the player's appearance.
---@class MtgPlayerApi
---@field globalstep fun(dtime: number, ...): nil The function called by the globalstep that controls player animations. You can override this to replace the globalstep with your own implementation. Receives all args that minetest.register_globalstep() passes
---@field register_model fun(name: string, def: MtgPlayerApiModelDef): nil Register a new model to be used by players, `name`: model filename such as "character.x", "foo.b3d", etc., `def`: see [#Model definition] Saved to player_api.registered_models
---@field registered_models string[]  Get a model's definition, `name`: model filename See [#Model definition]
---@field set_model fun(player: ObjectRef, model_name: string): nil  Change a player's model, `player`: PlayerRef, `model_name`: model registered with `player_api.register_model`
---@field set_animation fun(player: ObjectRef, anim_name: string, speed: number): nil Applies an animation to a player if speed or anim_name differ from the currently playing animation, `player`: PlayerRef, `anim_name`: name of the animation, `speed`: keyframes per second. If nil, the default from the model def is used
---@field set_textures fun(player: ObjectRef, textures: string[]): nil Sets player textures `player`: PlayerRef, `textures`: array of textures. If nil, the default from the model def is used
---@field set_texture fun(player: ObjectRef, index: number, texture: string): nil Sets one of the player textures, `player`: PlayerRef, `index`: Index into array of all textures, `texture`: the texture string
---@field get_textures fun(player: ObjectRef): string[] Returns player textures table
---@field get_animation fun(player: ObjectRef): {["model"]: string | nil, ["textures"]: string[] | nil, ["animation"]: table | nil}  Returns a table containing fields `model`, `textures` and `animation`. Any of the fields of the returned table may be nil, `player`: PlayerRef
---@field player_attached table<string, boolean>  A table that maps a player name to a boolean. If the value for a given player is set to true, the default player animations (walking, digging, ...) will no longer be updated, and knockback from damage is prevented for that player. Example of usage: A mod sets a player's value to true when attached to a vehicle.


---Model Definition
---@class MtgPlayerApiModelDef
---@field animation_speed number Default: 30, animation speed, in keyframes per second
---@field textures string[] Default `{"character.png"}`, array of textures
---@field animations table<string, MtgPlayerApiAnimationDef>
---@field visual_size {["x"]: number, ["y"]: number}
---@field collisionbox number[]
---@field stepheight number
---@field eye_height number


---Model Animation definition
---@class MtgPlayerApiAnimationDef
---@field x number start frame
---@field y number end frame
---@field collisionbox number[] | nil
---@field eye_height number | nil model eye height
---@field override_local boolean | nil suspend client side animations while this one is active (optional)
