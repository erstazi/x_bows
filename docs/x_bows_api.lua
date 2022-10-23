----
-- Base XBows class
-- @author SaKeL
-- @license LGPL-2.1-or-later
-- @classmod XBows
XBows = {
    --- `enable_pvp` setting, default `false`
    pvp = false,
    --- `creative_mode` setting, default `false`
    creative = false,
    --- `mesecons` check if MOD enabled or exists
    mesecons = false,
    --- `playerphysics` check if MOD enabled or exists
    playerphysics = false,
    --- `player_monoids` check if MOD enabled or exists
    player_monoids = false,
    --- table with key/value pairs, `key` is the item name (e.g. `x_bows:bow_wood`), `value` is the definition passed to XBows register method
    registered_bows = {},
    --- table with key/value pairs, `key` is the item name (e.g. `x_bows:arrow_wood`), `value` is the definition passed to XBows register method
    registered_arrows = {},
    --- table with key/value pairs, `key` is the item name (e.g. `x_bows:quiver`), `value` is the definition passed to XBows register method
    registered_quivers = {},
    --- registered particle spawners for internal use
    registered_particle_spawners = {},
    --- sneaking players when bow is charged
    player_bow_sneak = {},
    --- `Settings` from minetest
    settings = {
        --- `x_bows_attach_arrows_to_entities` setting, default: `false`
        x_bows_attach_arrows_to_entities = false
    },
    --- table of `after` jobs
    charge_sound_after_job = {}
}

---Check if creative is enabled or if player has creative priv
-- @param self XBows
-- @param name string
-- @return boolean
function XBows.is_creative(self, name) end

---Updates `allowed_ammunition` definition on already registered item, so MODs can add new ammunitions to this list.
-- @param self XBows
-- @param name string
-- @param allowed_ammunition string[]
-- @return nil
function XBows.update_bow_allowed_ammunition(self, name, allowed_ammunition) end

---Reset charged bow to uncharged bow, this will return the arrow item to the inventory also
-- @param self XBows
-- @param player ObjectRef Player Ref
-- @param includeWielded? boolean Will include reset for wielded bow also. default: `false`
-- @return nil
function XBows.reset_charged_bow(self, player, includeWielded) end

---Register bows
-- @param self XBows
-- @param name string
-- @param def ItemDef | BowItemDefCustom
-- @param override? boolean MOD everride
-- @return boolean|nil
function XBows.register_bow(self, name, def, override) end

---Register arrows
-- @param self XBows
-- @param name string
-- @param def ItemDef | ArrowItemDefCustom
-- @return boolean|nil
function XBows.register_arrow(self, name, def) end

---Register quivers
-- @param self XBows
-- @param name string
-- @param def ItemDef | QuiverItemDefCustom
-- @return boolean|nil
function XBows.register_quiver(self, name, def) end

---Load bow
-- @param self XBows
-- @param itemstack ItemStack
-- @param user ObjectRef
-- @param pointed_thing PointedThingDef
-- @return ItemStack
function XBows.load(self, itemstack, user, pointed_thing) end

---Shoot bow
-- @param self XBows
-- @param itemstack ItemStack
-- @param user ObjectRef
-- @param pointed_thing? PointedThingDef
-- @return ItemStack
function XBows.shoot(self, itemstack, user, pointed_thing) end

---Add new particle to XBow registration
-- @param self XBows
-- @param name string
-- @param def ParticlespawnerDef|ParticlespawnerDefCustom
-- @return nil
function XBows.register_particle_effect(self, name, def) end

---Get particle effect from registered spawners table
-- @param self XBows
-- @param name string
-- @param pos Vector
-- @return number|boolean
function XBows.get_particle_effect_for_arrow(self, name, pos) end

---Check if ammunition is allowed to charge this weapon
-- @param self XBows
-- @param weapon_name string
-- @param ammo_name string
-- @return boolean
function XBows.is_allowed_ammunition(self, weapon_name, ammo_name) end

---Register new projectile entity
-- @param self XBows
-- @param name string
-- @param def XBowsEntityDef
function XBows.register_entity(self, name, def) end

---Open quiver
-- @param self XBows
-- @param itemstack ItemStack
-- @param user ObjectRef
-- @return ItemStack
function XBows.open_quiver(self, itemstack, user) end
