---Base class XBows
---@class XBows
---@field pvp boolean
---@field creative boolean
---@field mesecons string|nil
---@field playerphysics string|nil
---@field player_monoids string|nil
---@field registered_bows table<string, ItemDef|BowItemDefCustom>
---@field registered_arrows table<string, ItemDef|ArrowItemDefCustom>
---@field registered_quivers table<string, ItemDef|QuiverItemDefCustom>
---@field registered_particle_spawners table<string, ParticlespawnerDef|ParticlespawnerDefCustom>
---@field player_bow_sneak table<string, table<string, boolean>>
---@field settings table
---@field quiver table Quiver class
---@field charge_sound_after_job table<string, JobTable>
---@field is_allowed_ammunition fun(self: XBows, weapon_name: string, ammo_name: string): boolean ---Check if ammunition is allowed to charge this weapon
---@field is_creative fun(self: XBows, name: string): boolean Check if creative is enabled or if player has creative priv
---@field register_particle_effect fun(self: XBows, name: string, def: ParticlespawnerDef|ParticlespawnerDefCustom): nil
---@field get_particle_effect_for_arrow fun(self: XBows, name: string, pos: Vector): number
---@field register_entity fun(self: EntityDef|XBows, name: string, def: XBowsEntityDef): nil Register new projectile entity


---XBowsQuiver class extended from XBows
---@alias XBowsQuiver XBowsQuiverBase|XBows
---@class XBowsQuiverBase
---@field hud_item_ids table
---@field after_job table<string, JobTable>
---@field udate_or_create_hud fun(self: XBowsQuiver, player: ObjectRef, inv_list: ItemStack[], idx?: number): nil Update or create HUD
---@field get_or_create_detached_inv fun(self: XBowsQuiver, quiver_id: string, player_name: string, quiver_items?: string): InvRef Get existing detached inventory or create new one
---@field save fun(self: XBowsQuiver, inv: InvRef, player: ObjectRef, quiver_is_closed?: boolean): nil Save quiver inventory to itemstack meta


---Custom field in ParticlespawnerDef
---@class ParticlespawnerDefCustom
---@field custom ParticlespawnerDefCustomAttr

---Custom field attributes in ParticlespawnerDef
---@class ParticlespawnerDefCustomAttr
---@field minpos Vector
---@field maxpos Vector

---Custom field in ItemDef
---@class BowItemDefCustom
---@field custom BowItemDefCustomAttr

---Custom field attributes in ItemDef
---@class BowItemDefCustomAttr
---@field crit_chance number `crit_chance` 10% chance, 5 is 20% chance, (1 / crit_chance) * 100 = % chance
---@field inventory_image_charged string
---@field recipe table
---@field fuel_burntime number
---@field name_charged string
---@field name string
---@field mod_name string
---@field uses number
---@field strength number How strong is the bow. Defines how far the arrow will fly.
---@field strength_min number|nil How strong is the bow. Defines how far the arrow will fly.
---@field strength_max number|nil How strong is the bow. Defines how far the arrow will fly.
---@field allowed_ammunition string[]|nil
---@field wield_image_charged string|nil
---@field acc_x_min number|nil
---@field acc_y_min number|nil
---@field acc_z_min number|nil
---@field acc_x_max number|nil
---@field acc_y_max number|nil
---@field acc_z_max number|nil
---@field sound_load string
---@field sound_hit string
---@field sound_shoot string
---@field sound_shoot_crit string
---@field gravity number

---Custom field in ItemDef
---@class ArrowItemDefCustom
---@field custom ArrowItemDefCustomAttr

---Custom field attributes in ItemDef
---@class ArrowItemDefCustomAttr
---@field tool_capabilities ToolCapabilitiesDef
---@field craft_count number
---@field recipe table
---@field fuel_burntime number
---@field name string
---@field mod_name string
---@field particle_effect string|nil
---@field particle_effect_crit string|nil
---@field particle_effect_fast string|nil
---@field projectile_textures table|nil
---@field projectile_visual_size table
---@field projectile_entity string
---@field on_hit_node fun(self: table, pointed_thing_ref: table)
---@field on_hit_entity fun(self: table, pointed_thing_ref: table)
---@field on_hit_player fun(self: table, pointed_thing_ref: table)
---@field on_after_activate fun(self: table)


---Custom field in ItemDef
---@class QuiverItemDefCustom
---@field custom QuiverItemDefCustomAttr

---Custom field attributes in ItemDef
---@class QuiverItemDefCustomAttr
---@field recipe table
---@field recipe_count number
---@field faster_arrows number
---@field add_damage number
---@field fuel_burntime number
---@field inventory_image_open string
---@field wield_image_open string
---@field name string


---Custom field in EntityDef
---@alias XBowsEntityDef EntityDef|EntityDefCustom|XBows
---@class EntityDefCustom
---@field on_death fun(self: XBowsEntityDef, selfObj: table, killer: ObjectRef|nil): nil Function receive a "luaentity" table as `self`. Called when the object dies.
---@field on_punch fun(self: XBowsEntityDef, selfObj: table, puncher: ObjectRef|nil, time_from_last_punch: number|integer|nil, tool_capabilities: ToolCapabilitiesDef|nil, dir: Vector, damage: number|integer): boolean|nil Function receive a "luaentity" table as `self`. Called when somebody punches the object. Note that you probably want to handle most punches using the automatic armor group system. Can return `true` to prevent the default damage mechanism.
---@field _custom EntityDefCustomAttr

---@alias EntityDefCustomAttr EntityDefCustomAttrDef|EntityDef
---@class EntityDefCustomAttrDef
---@field name string
---@field mod_name string
