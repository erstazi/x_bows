--[[
    X Bows. Adds bow and arrows with API.
    Copyright (C) 2026 SaKeL

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, see <https://www.gnu.org/licenses/>.
--]]

local S = core.get_translator(core.get_current_modname())

---Check if table contains value
---@param tbl table
---@param value string|number
---@return boolean
local function table_contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end

---Merge two tables with key/value pair
---@param t1 table
---@param t2 table
---@return table
local function mergeTables(t1, t2)
    for k, v in pairs(t2) do t1[k] = v end
    return t1
end

---@type XBows
XBows = {
    pvp = core.settings:get_bool('enable_pvp', true),
    creative = core.settings:get_bool('creative_mode', false),
    mesecons = core.get_modpath('mesecons'),
    playerphysics = core.get_modpath('playerphysics'),
    player_monoids = core.get_modpath('player_monoids'),
    pova = core.get_modpath('pova'),
    i3 = core.get_modpath('i3'),
    unified_inventory = core.get_modpath('unified_inventory'),
    u_skins = core.get_modpath('u_skins'),
    wardrobe = core.get_modpath('wardrobe'),
    _3d_armor = core.get_modpath('3d_armor'),
    skinsdb = core.get_modpath('skinsdb'),
    player_api = core.get_modpath('player_api'),
    x_player_api = core.get_modpath('x_player_api'),
    x_enchanting = core.get_modpath('x_enchanting'),
    registered_bows = {},
    registered_arrows = {},
    registered_quivers = {},
    registered_particle_spawners = {},
    registered_entities = {},
    player_bow_sneak = {},
    arrow_velocity = 58,
    arrow_gravity = -19.62,
    settings = {
        x_bows_attach_arrows_to_entities = core.settings:get_bool('x_bows_attach_arrows_to_entities', true),
        x_bows_show_damage_numbers = core.settings:get_bool('x_bows_show_damage_numbers', false),
        x_bows_show_3d_quiver = core.settings:get_bool('x_bows_show_3d_quiver', true),
        x_bows_enable_arrow_wood= core.settings:get_bool('x_bows_enable_arrow_wood', true),
        x_bows_enable_arrow_stone= core.settings:get_bool('x_bows_enable_arrow_stone', true),
        x_bows_enable_arrow_bronze= core.settings:get_bool('x_bows_enable_arrow_bronze', true),
        x_bows_enable_arrow_steel= core.settings:get_bool('x_bows_enable_arrow_steel', true),
        x_bows_enable_arrow_mese= core.settings:get_bool('x_bows_enable_arrow_mese', true),
        x_bows_enable_arrow_diamond= core.settings:get_bool('x_bows_enable_arrow_diamond', true)
    },
    charge_sound_after_job = {},
    fallback_quiver = not core.global_exists('sfinv')
        and not core.global_exists('unified_inventory')
        and not core.global_exists('i3')
}

XBows.__index = XBows

---@type XBowsQuiver
XBowsQuiver = {
    hud_item_ids = {},
    after_job = {},
    quiver_empty_state = {},
    active_quivers = {}
}
XBowsQuiver.__index = XBowsQuiver
setmetatable(XBowsQuiver, XBows)


---@type XBowsEntityDef
local XBowsEntityDef = {}
XBowsEntityDef.__index = XBowsEntityDef
setmetatable(XBowsEntityDef, XBows)

---create UUID
---@return string
function XBows.uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

    ---@diagnostic disable-next-line: redundant-return-value
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---Check if creative is enabled or if player has creative priv
---@param self XBows
---@param name string
---@return boolean
function XBows.is_creative(self, name)
    return self.creative or core.check_player_privs(name, { creative = true })
end

---Updates `allowed_ammunition` definition on already registered item, so MODs can add new ammunitions to this list.
---@param self XBows
---@param name string
---@param allowed_ammunition string[]
---@return nil
function XBows.update_bow_allowed_ammunition(self, name, allowed_ammunition)
    local _name = name:find(':') and name or ('x_bows:' .. name)
    local def = self.registered_bows[_name]

    if not def then
        return
    end

    local def_copy = table.copy(def)

    core.unregister_item(_name)
    core.unregister_item(_name .. '_semi_charged')
    core.unregister_item(_name .. '_charged')

    def_copy.custom.allowed_ammunition = def_copy.custom.allowed_ammunition or {}
    for _, v in ipairs(allowed_ammunition) do
        if not table_contains(def_copy.custom.allowed_ammunition, v) then
            table.insert(def_copy.custom.allowed_ammunition, v)
        end
    end

    local clean_name = name:find(':') and name:match(':(.+)$') or name
    self:register_bow(clean_name, def_copy, true)
end

---Reset charged bow to uncharged bow, this will return the arrow item to the inventory also
---@param self XBows
---@param player ObjectRef Player Ref
---@param includeWielded? boolean Will include reset for wielded bow also. default: `false`
---@return nil
function XBows.reset_charged_bow(self, player, includeWielded)
    local _includeWielded = includeWielded or false
    local inv = player:get_inventory()

    if not inv then
        return
    end

    if _includeWielded and self.charge_sound_after_job[player:get_player_name()] then
        for _, v in pairs(self.charge_sound_after_job[player:get_player_name()]) do
            v:cancel()
        end

        self.charge_sound_after_job[player:get_player_name()] = {}
    end

    local inv_list = inv:get_list('main')

    for i, st in ipairs(inv_list) do
        local st_name = st:get_name()
        local x_bows_registered_bow_def = self.registered_bows[st_name]
        local reset = _includeWielded or player:get_wield_index() ~= i

        if not st:is_empty()
            and x_bows_registered_bow_def
            and reset
            and core.get_item_group(st_name, 'bow_charged') ~= 0
        then
            local item_meta = st:get_meta()
            local arrow_data = core.deserialize(item_meta:get_string('arrow_itemstack_string'))
            local arrow_itemstack = arrow_data and ItemStack(arrow_data)
            local is_enchanted = item_meta:get_int('is_enchanted') == 1
            local is_infinity = false

            if is_enchanted then
                local enchantments = core.deserialize(item_meta:get_string('x_enchanting'))

                if enchantments and enchantments.infinity and enchantments.infinity.value > 0 then
                    is_infinity = true
                end
            end

            ---return arrow
            if arrow_itemstack and not arrow_itemstack:is_empty() and not self:is_creative(player:get_player_name()) and not is_infinity then
                local arrow_meta = arrow_itemstack:get_meta()
                local is_arrow_from_quiver = arrow_meta:get_int('is_arrow_from_quiver') ~= 0
                local quiver_id = arrow_meta:get_string('quiver_id')
                local returned = false

                if is_arrow_from_quiver and quiver_id ~= '' then
                    local detached_inv = XBowsQuiver:get_or_create_detached_inv(quiver_id, player:get_player_name())
                    if detached_inv and detached_inv:room_for_item('main', { name = arrow_itemstack:get_name() }) then
                        detached_inv:add_item('main', arrow_itemstack:get_name())
                        if XBowsQuiver:save(detached_inv, player, true) then
                            returned = true
                        else
                            -- Quiver not in player inventory; rollback detached inv so arrow returns to player
                            detached_inv:take_item('main', arrow_itemstack:get_name())
                            returned = false
                        end
                    end
                end

                if not returned then
                    if inv:room_for_item('x_bows:arrow_inv', { name = arrow_itemstack:get_name() }) then
                        -- Add arrow back to arrow inventory
                        inv:add_item('x_bows:arrow_inv', arrow_itemstack:get_name())
                    elseif inv:room_for_item('main', { name = arrow_itemstack:get_name() }) then
                        -- Add arrow back to main inventory
                        inv:add_item('main', arrow_itemstack:get_name())
                    else
                        -- Drop the arrow on the ground (no space in any inventory)
                        core.item_drop(
                            ItemStack({ name = arrow_itemstack:get_name(), count = 1 }),
                            player,
                            player:get_pos()
                        )
                    end
                end
            end

            --reset bow to uncharged bow
            local new_stack = ItemStack(st)
            new_stack:set_name(x_bows_registered_bow_def.custom.name)
            local new_meta = new_stack:get_meta()
            new_meta:set_string('arrow_itemstack_string', '')
            new_meta:set_string('time_load', '')

            XBows:set_wielditem_images(new_stack, new_stack:get_name())

            inv:set_stack('main', i, new_stack)
        end
    end
end

---Register bows
---@param self XBows
---@param name string
---@param def ItemDef | BowItemDefCustom
---@param override? boolean MOD everride
---@return boolean|nil
function XBows.register_bow(self, name, def, override)
    if name == nil or name == '' then
        return false
    end

    local mod_name = def.custom.mod_name or 'x_bows'
    def.custom.name = mod_name .. ':' .. name
    def.custom.name_semi_charged = mod_name .. ':' .. name .. '_semi_charged'
    def.custom.name_charged = mod_name .. ':' .. name .. '_charged'
    def.short_description = def.short_description
    def.description = override and def.short_description or (def.description or name)
    def.custom.uses = def.custom.uses or 150
    def.groups = mergeTables({ bow = 1, flammable = 1, enchantability = 1 }, def.groups or {})
    def.custom.groups_semi_charged = mergeTables(
        { bow_charged = 1, bow_semi_charged = 1, flammable = 1, not_in_creative_inventory = 1 },
        def.groups or {}
    )
    def.custom.groups_charged = mergeTables(
        { bow_charged = 1, flammable = 1, not_in_creative_inventory = 1 },
        def.groups or {}
    )
    def.custom.strength = def.custom.strength or self.arrow_velocity or 58
    def.custom.allowed_ammunition = def.custom.allowed_ammunition or nil
    def.custom.sound_load = def.custom.sound_load or 'x_bows_bow_load'
    def.custom.sound_hit = def.custom.sound_hit or 'x_bows_arrow_hit'
    def.custom.sound_shoot = def.custom.sound_shoot or 'x_bows_bow_shoot'
    def.custom.sound_shoot_crit = def.custom.sound_shoot_crit or 'x_bows_bow_shoot_crit'
    if def.custom.sound_loaded == nil then
        def.custom.sound_loaded = 'x_bows_bow_loaded'
    end
    def.custom.sound_semi_charged = def.custom.sound_semi_charged or nil
    def.custom.gravity = def.custom.gravity or self.arrow_gravity or -19.62
    def.custom.has_semi_charged = (def.custom.inventory_image_semi_charged ~= nil) or (name == 'bow_wood')

    if def.custom.crit_chance then
        def.description = def.description .. '\n' .. core.colorize('#00FF00', S('Critical Arrow Chance') .. ': '
            .. (1 / def.custom.crit_chance) * 100 .. '%')
    end

    def.description = def.description .. '\n' .. core.colorize('#00BFFF', S('Strength') .. ': '
        .. def.custom.strength)

    if def.custom.allowed_ammunition then
        local allowed_amm_desc = table.concat(def.custom.allowed_ammunition, '\n')

        if allowed_amm_desc ~= '' then
            def.description = def.description .. '\n' .. S('Allowed ammunition') .. ':\n' .. allowed_amm_desc
        else
            def.description = def.description .. '\n' .. S('Allowed ammunition') .. ': ' .. S('none')
        end
    end

    self.registered_bows[def.custom.name] = def
    self.registered_bows[def.custom.name_semi_charged] = def
    self.registered_bows[def.custom.name_charged] = def

    ---Tool capabilities with 0 fleshy damage for charged bows to prevent melee punches while aiming/shooting
    local charged_bow_tool_capabilities = {
        full_punch_interval = 2.0,
        max_drop_level = 0,
        groupcaps = {},
        damage_groups = { fleshy = 0 },
    }

    ---wield scales
    local base_wield_scale = def.wield_scale or def.custom.wield_scale or { x = 2, y = 2, z = 1.5 }
    local semi_charged_wield_scale = def.custom.wield_scale_semi_charged or base_wield_scale
    local charged_wield_scale = def.custom.wield_scale_charged or base_wield_scale

    ---not charged bow
    core.register_tool(override and ':' .. def.custom.name or def.custom.name, {
        description = def.description,
        inventory_image = def.inventory_image or 'x_bows_bow_wood.png',
        wield_image = def.wield_image or def.inventory_image,
        groups = def.groups,
        wield_scale = base_wield_scale,
        ---@param itemstack ItemStack
        ---@param placer ObjectRef|nil
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_place = function(itemstack, placer, pointed_thing)
            if placer then
                return self:load(itemstack, placer, pointed_thing)
            end
        end,
        ---@param itemstack ItemStack
        ---@param user ObjectRef|nil
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_secondary_use = function(itemstack, user, pointed_thing)
            if user then
                return self:load(itemstack, user, pointed_thing)
            end
        end
    })

    ---semi charged bow images (if semi-charged texture is not configured, fall back to charged texture)
    local default_semi_charged_image = (name == 'bow_wood') and 'x_bows_bow_wood_semi_charged.png'
        or (def.custom.inventory_image_charged or 'x_bows_bow_wood_charged.png')
    local semi_charged_inv_image = def.custom.inventory_image_semi_charged or default_semi_charged_image
    local semi_charged_wield_image = def.custom.wield_image_semi_charged
        or (def.custom.inventory_image_semi_charged and def.custom.inventory_image_semi_charged)
        or def.custom.wield_image_charged
        or def.wield_image
        or semi_charged_inv_image

    core.register_tool(override and ':' .. def.custom.name_semi_charged or def.custom.name_semi_charged, {
        description = def.description,
        inventory_image = semi_charged_inv_image,
        wield_image = semi_charged_wield_image,
        groups = def.custom.groups_semi_charged,
        wield_scale = semi_charged_wield_scale,
        range = 0,
        tool_capabilities = charged_bow_tool_capabilities,
        ---@param itemstack ItemStack
        ---@param user ObjectRef|nil
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_use = function(itemstack, user, pointed_thing)
            if user then
                return self:shoot(itemstack, user, pointed_thing)
            end
        end,
        ---@param itemstack ItemStack
        ---@param dropper ObjectRef|nil
        ---@param pos Vector
        ---@return ItemStack|nil
        on_drop = function(itemstack, dropper, pos)
            if dropper then
                local item_meta = itemstack:get_meta()
                local is_enchanted = item_meta:get_int('is_enchanted') == 1
                local is_infinity = false

                if is_enchanted then
                    local enchantments = core.deserialize(item_meta:get_string('x_enchanting'))

                    if enchantments and enchantments.infinity and enchantments.infinity.value > 0 then
                        is_infinity = true
                    end
                end

                if not is_infinity then
                    local arrow_data = core.deserialize(item_meta:get_string('arrow_itemstack_string'))
                    local arrow_itemstack = arrow_data and ItemStack(arrow_data)

                    ---return arrow
                    if arrow_itemstack and not arrow_itemstack:is_empty() and not self:is_creative(dropper:get_player_name()) then
                        core.item_drop(
                            ItemStack({ name = arrow_itemstack:get_name(), count = 1 }),
                            dropper,
                            { x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5 }
                        )
                    end
                end

                item_meta:set_string('arrow_itemstack_string', '')
                item_meta:set_string('time_load', '')
                itemstack:set_name(def.custom.name)

                XBows:set_wielditem_images(itemstack, def.custom.name)

                ---returns leftover itemstack
                return core.item_drop(itemstack, dropper, pos)
            end
        end
    })

    ---charged bow images
    local charged_inv_image = def.custom.inventory_image_charged or 'x_bows_bow_wood_charged.png'
    local charged_wield_image = def.custom.wield_image_charged or def.wield_image or charged_inv_image

    core.register_tool(override and ':' .. def.custom.name_charged or def.custom.name_charged, {
        description = def.description,
        inventory_image = charged_inv_image,
        wield_image = charged_wield_image,
        groups = def.custom.groups_charged,
        wield_scale = charged_wield_scale,
        range = 0,
        tool_capabilities = charged_bow_tool_capabilities,
        ---@param itemstack ItemStack
        ---@param user ObjectRef|nil
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_use = function(itemstack, user, pointed_thing)
            if user then
                return self:shoot(itemstack, user, pointed_thing)
            end
        end,
        ---@param itemstack ItemStack
        ---@param dropper ObjectRef|nil
        ---@param pos Vector
        ---@return ItemStack|nil
        on_drop = function(itemstack, dropper, pos)
            if dropper then
                local item_meta = itemstack:get_meta()
                local is_enchanted = item_meta:get_int('is_enchanted') == 1
                local is_infinity = false

                if is_enchanted then
                    local enchantments = core.deserialize(item_meta:get_string('x_enchanting'))

                    if enchantments and enchantments.infinity and enchantments.infinity.value > 0 then
                        is_infinity = true
                    end
                end

                if not is_infinity then
                    local arrow_data = core.deserialize(item_meta:get_string('arrow_itemstack_string'))
                    local arrow_itemstack = arrow_data and ItemStack(arrow_data)

                    ---return arrow
                    if arrow_itemstack and not arrow_itemstack:is_empty() and not self:is_creative(dropper:get_player_name()) then
                        core.item_drop(
                            ItemStack({ name = arrow_itemstack:get_name(), count = 1 }),
                            dropper,
                            { x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5 }
                        )
                    end
                end

                item_meta:set_string('arrow_itemstack_string', '')
                item_meta:set_string('time_load', '')
                itemstack:set_name(def.custom.name)

                XBows:set_wielditem_images(itemstack, def.custom.name)

                ---returns leftover itemstack
                return core.item_drop(itemstack, dropper, pos)
            end
        end
    })

    ---recipes
    if def.custom.recipe then
        core.register_craft({
            output = def.custom.name,
            recipe = def.custom.recipe
        })
    end

    ---fuel recipe
    if def.custom.fuel_burntime then
        core.register_craft({
            type = 'fuel',
            recipe = def.custom.name,
            burntime = def.custom.fuel_burntime,
        })
    end
end

---Register arrows
---@param self XBows
---@param name string
---@param def ItemDef | ArrowItemDefCustom
---@return boolean|nil
function XBows.register_arrow(self, name, def)
    if name == nil or name == '' then
        return false
    end

    local mod_name = def.custom.mod_name or 'x_bows'
    def.custom.name = mod_name .. ':' .. name
    def.description = def.description or name
    def.short_description = def.short_description or name
    def.custom.tool_capabilities = def.custom.tool_capabilities or {
        full_punch_interval = 1,
        max_drop_level = 0,
        damage_groups = { fleshy = 2 }
    }
    def.custom.description_abilities = core.colorize('#00FF00', S('Damage') .. ': '
        .. def.custom.tool_capabilities.damage_groups.fleshy) .. '\n' .. core.colorize('#00BFFF', S('Charge Time') .. ': '
        .. def.custom.tool_capabilities.full_punch_interval .. 's')
    def.groups = mergeTables({ arrow = 1, flammable = 1 }, def.groups or {})
    def.custom.particle_effect = def.custom.particle_effect or 'arrow'
    def.custom.particle_effect_crit = def.custom.particle_effect_crit or 'arrow_crit'
    def.custom.particle_effect_fast = def.custom.particle_effect_fast or 'arrow_fast'
    def.custom.projectile_entity = def.custom.projectile_entity or 'x_bows:arrow_entity'
    def.custom.on_hit_node = def.custom.on_hit_node or nil
    def.custom.on_hit_entity = def.custom.on_hit_entity or nil
    def.custom.on_hit_player = def.custom.on_hit_player or nil
    def.custom.on_after_activate = def.custom.on_after_activate or nil

    self.registered_arrows[def.custom.name] = def

    core.register_craftitem(def.custom.name, {
        description = def.description .. '\n' .. def.custom.description_abilities,
        short_description = def.short_description,
        inventory_image = def.inventory_image,
        groups = def.groups
    })

    ---recipes
    if def.custom.recipe then
        core.register_craft({
            output = def.custom.name .. ' ' .. (def.custom.craft_count or 4),
            recipe = def.custom.recipe
        })
    end

    ---fuel recipe
    if def.custom.fuel_burntime then
        core.register_craft({
            type = 'fuel',
            recipe = def.custom.name,
            burntime = def.custom.fuel_burntime,
        })
    end
end

---Register quivers
---@param self XBows
---@param name string
---@param def ItemDef | QuiverItemDefCustom
---@return boolean|nil
function XBows.register_quiver(self, name, def)
    if name == nil or name == '' then
        return false
    end

    def.custom.name = 'x_bows:' .. name
    def.custom.name_open = 'x_bows:' .. name .. '_open'
    def.description = def.description or name
    def.short_description = def.short_description or name
    def.groups = mergeTables({ quiver = 1, flammable = 1 }, def.groups or {})
    def.custom.groups_charged = mergeTables({
            quiver = 1, quiver_open = 1, flammable = 1, not_in_creative_inventory = 1
        },
        def.groups or {}
    )

    if def.custom.faster_arrows then
        def.description = def.description .. '\n' .. core.colorize('#00FF00', S('Faster Arrows') ..
            ': ' .. (1 / def.custom.faster_arrows) * 100 .. '%')
        def.short_description = def.short_description .. '\n' .. core.colorize('#00FF00', S('Faster Arrows') ..
            ': ' .. (1 / def.custom.faster_arrows) * 100 .. '%')
    end

    if def.custom.add_damage then
        def.description = def.description .. '\n' .. core.colorize('#FF8080', S('Arrow Damage') ..
            ': +' .. def.custom.add_damage)
        def.short_description = def.short_description .. '\n' .. core.colorize('#FF8080', S('Arrow Damage') ..
            ': +' .. def.custom.add_damage)
    end

    self.registered_quivers[def.custom.name] = def
    self.registered_quivers[def.custom.name_open] = def

    ---closed quiver
    core.register_tool(def.custom.name, {
        description = def.description,
        short_description = def.short_description,
        inventory_image = def.inventory_image or 'x_bows_quiver.png',
        wield_image = def.wield_image or 'x_bows_quiver.png',
        groups = def.groups,
        wield_scale = { x = 2, y = 2, z = 1 },
        ---@param itemstack ItemStack
        ---@param user ObjectRef|nil
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_secondary_use = function(itemstack, user, pointed_thing)
            if user then
                return self:open_quiver(itemstack, user)
            end
        end,
        ---@param itemstack ItemStack
        ---@param placer ObjectRef
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.under then
                local node = core.get_node(pointed_thing.under)
                local node_def = core.registered_nodes[node.name]

                if node_def and node_def.on_rightclick then
                    return node_def.on_rightclick(pointed_thing.under, node, placer, itemstack, pointed_thing)
                end
            end

            return self:open_quiver(itemstack, placer)
        end
    })

    ---open quiver
    core.register_tool(def.custom.name_open, {
        description = def.description,
        short_description = def.short_description,
        inventory_image = def.custom.inventory_image_open or 'x_bows_quiver_open.png',
        wield_image = def.custom.wield_image_open or 'x_bows_quiver_open.png',
        groups = def.custom.groups_charged,
        wield_scale = { x = 2, y = 2, z = 1 },
        ---@param itemstack ItemStack
        ---@param user ObjectRef|nil
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_secondary_use = function(itemstack, user, pointed_thing)
            if user then
                return self:open_quiver(itemstack, user)
            end
        end,
        ---@param itemstack ItemStack
        ---@param placer ObjectRef
        ---@param pointed_thing PointedThingDef
        ---@return ItemStack|nil
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.under then
                local node = core.get_node(pointed_thing.under)
                local node_def = core.registered_nodes[node.name]

                if node_def and node_def.on_rightclick then
                    return node_def.on_rightclick(pointed_thing.under, node, placer, itemstack, pointed_thing)
                end
            end

            return self:open_quiver(itemstack, placer)
        end,
        ---@param itemstack ItemStack
        ---@param dropper ObjectRef|nil
        ---@param pos Vector
        ---@return ItemStack
        on_drop = function(itemstack, dropper, pos)
            if not dropper then
                return itemstack
            end

            local replace_item = XBowsQuiver:get_replacement_item(itemstack, 'x_bows:quiver')
            return core.item_drop(replace_item, dropper, pos)
        end
    })

    ---recipes
    if def.custom.recipe then
        core.register_craft({
            output = def.custom.name,
            recipe = def.custom.recipe
        })
    end

    ---fuel recipe
    if def.custom.fuel_burntime then
        core.register_craft({
            type = 'fuel',
            recipe = def.custom.name,
            burntime = def.custom.fuel_burntime,
        })
    end
end

function XBows.set_wielditem_images(self, wielditem, bow_name)
    local wielded_item_meta = wielditem:get_meta()
    local is_enchanted = wielded_item_meta:get_int('is_enchanted') == 1

    if not is_enchanted or not XBows.x_enchanting or not core.global_exists('XEnchanting')
        or not XEnchanting.get_glint_texture_modifier
    then
        return
    end

    -- Inventory Image
    local inventory_image_charged = (core.registered_tools[bow_name] or {}).inventory_image
    local inventory_image_meta = wielded_item_meta:get_string('inventory_image')

    -- Only replace (fix) image when meta image was set
    if inventory_image_meta ~= ''
        and inventory_image_charged
        and inventory_image_charged ~= ''
    then
        wielded_item_meta:set_string('inventory_image', XEnchanting:get_glint_texture_modifier(inventory_image_charged))
    end

    -- Wield Image
    local wield_image_charged = (core.registered_tools[bow_name] or {}).wield_image
    local wield_image_meta = wielded_item_meta:get_string('wield_image')

    -- Only replace (fix) image when meta image was set
    if wield_image_meta ~= ''
        and wield_image_charged
        and wield_image_charged ~= ''
    then
        wielded_item_meta:set_string('wield_image', XEnchanting:get_glint_texture_modifier(wield_image_charged))
    end
end

---Load bow
---@param self XBows
---@param itemstack ItemStack
---@param user ObjectRef
---@param pointed_thing PointedThingDef
---@return ItemStack
function XBows.load(self, itemstack, user, pointed_thing)
    local player_name = user:get_player_name()
    local inv = user:get_inventory() --[[@as InvRef]]
    local bow_name = itemstack:get_name()
    local bow_def = self.registered_bows[bow_name]
    ---@alias ItemStackArrows {["stack"]: ItemStack, ["list"]: string, ["idx"]: number|integer}[]
    ---@type ItemStackArrows
    local itemstack_arrows = {}

    local bow_item_meta = itemstack:get_meta()
    local bow_enchantments = core.deserialize(bow_item_meta:get_string('x_enchanting'))
    local is_infinity = bow_enchantments and bow_enchantments.infinity and bow_enchantments.infinity.value > 0

    ---trigger right click event if pointed item has one
    if pointed_thing.under then
        local node = core.get_node(pointed_thing.under)
        local node_def = core.registered_nodes[node.name]

        if node_def and node_def.on_rightclick then
            return node_def.on_rightclick(pointed_thing.under, node, user, itemstack, pointed_thing)
        end
    end

    ---find itemstack arrow in quiver
    local quiver_result = XBowsQuiver:get_itemstack_arrow_from_quiver(user)
    local itemstack_arrow = quiver_result.found_arrow_stack

    if itemstack_arrow then
        ---we got arrow from quiver
        local itemstack_arrow_meta = itemstack_arrow:get_meta()

        itemstack_arrow_meta:set_int('is_arrow_from_quiver', 1)
        itemstack_arrow_meta:set_int('found_arrow_stack_idx', quiver_result.found_arrow_stack_idx)
        itemstack_arrow_meta:set_string('quiver_name', quiver_result.quiver_name)
        itemstack_arrow_meta:set_string('quiver_id', quiver_result.quiver_id)
    else
        if not inv:is_empty('x_bows:arrow_inv') then
            XBowsQuiver:udate_or_create_hud(user, inv:get_list('x_bows:arrow_inv'))
        else
            ---no ammo (fake stack)
            XBowsQuiver:udate_or_create_hud(user, {
                ItemStack({ name = 'x_bows:no_ammo' })
            })
        end

        ---find itemstack arrow in players inventory
        local arrow_stack = inv:get_stack('x_bows:arrow_inv', 1)
        local is_allowed_ammunition = self:is_allowed_ammunition(bow_name, arrow_stack:get_name())

        if self.registered_arrows[arrow_stack:get_name()] and is_allowed_ammunition then
            table.insert(itemstack_arrows, { stack = arrow_stack, list = 'x_bows:arrow_inv', idx = 1 })
        end

        ---if everything else fails
        if self.fallback_quiver then
            local inv_list = inv:get_list('main')

            for i, st in ipairs(inv_list) do
                local st_name = st:get_name()

                if not st:is_empty() and self.registered_arrows[st_name] then
                    local _is_allowed_ammunition = self:is_allowed_ammunition(bow_name, st_name)

                    if _is_allowed_ammunition then
                        table.insert(itemstack_arrows, { stack = st, list = 'main', idx = i })
                    end
                end
            end
        end

        -- take 1st found arrow in the list
        itemstack_arrow = #itemstack_arrows > 0 and itemstack_arrows[1].stack or nil
    end

    if itemstack_arrow and bow_def then
        local _tool_capabilities = self.registered_arrows[itemstack_arrow:get_name()].custom.tool_capabilities
        local charge_time = bow_def.custom.charge_time
            or (_tool_capabilities.full_punch_interval * (bow_def.custom.charge_multiplier or 1.0))

        ---stop previous charged sound after job
        if self.charge_sound_after_job[player_name] then
            for _, v in pairs(self.charge_sound_after_job[player_name]) do
                v:cancel()
            end

            self.charge_sound_after_job[player_name] = {}
        else
            self.charge_sound_after_job[player_name] = {}
        end

        ---@param v_player_name string
        ---@param v_bow_name string
        ---@param v_itemstack_arrow ItemStack
        ---@param v_inv InvRef
        ---@param v_itemstack_arrows ItemStackArrows
        core.after(0, function(v_player_name, v_bow_name, v_itemstack_arrow, v_inv, v_itemstack_arrows)
            local v_user = core.get_player_by_name(v_player_name)
            if not v_user or not v_user:is_valid() then
                return
            end

            local wielded_item = v_user:get_wielded_item()

            if wielded_item:get_name() == v_bow_name then
                local wielded_item_meta = wielded_item:get_meta()
                local v_itemstack_arrow_meta = v_itemstack_arrow:get_meta()
                local arrow_taken = false

                if self:is_creative(v_player_name) or is_infinity then
                    arrow_taken = true
                else
                    if v_itemstack_arrow_meta:get_int('is_arrow_from_quiver') == 1 then
                        local q_id = v_itemstack_arrow_meta:get_string('quiver_id')
                        local q_idx = v_itemstack_arrow_meta:get_int('found_arrow_stack_idx')
                        local detached_inv = XBowsQuiver:get_or_create_detached_inv(q_id, v_player_name)
                        if detached_inv then
                            local q_st = detached_inv:get_stack('main', q_idx)
                            if q_st:get_name() == v_itemstack_arrow:get_name() and not q_st:is_empty() then
                                q_st:take_item()
                                detached_inv:set_stack('main', q_idx, q_st)
                                if XBowsQuiver:save(detached_inv, v_user, true) then
                                    arrow_taken = true
                                else
                                    -- Rollback detached inv if quiver wasn't found in inventory
                                    q_st:set_count(q_st:get_count() + 1)
                                    detached_inv:set_stack('main', q_idx, q_st)
                                end
                            else
                                for k, st in ipairs(detached_inv:get_list('main')) do
                                    if st:get_name() == v_itemstack_arrow:get_name() and not st:is_empty() then
                                        st:take_item()
                                        detached_inv:set_stack('main', k, st)
                                        if XBowsQuiver:save(detached_inv, v_user, true) then
                                            arrow_taken = true
                                        else
                                            st:set_count(st:get_count() + 1)
                                            detached_inv:set_stack('main', k, st)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    elseif #v_itemstack_arrows > 0 then
                        local src_list = v_itemstack_arrows[1].list or 'x_bows:arrow_inv'
                        local src_idx = v_itemstack_arrows[1].idx or 1
                        local cur_st = v_inv:get_stack(src_list, src_idx)
                        if cur_st:get_name() == v_itemstack_arrow:get_name() and not cur_st:is_empty() then
                            cur_st:take_item()
                            v_inv:set_stack(src_list, src_idx, cur_st)
                            arrow_taken = true
                        else
                            for k, st in ipairs(v_inv:get_list(src_list)) do
                                if st:get_name() == v_itemstack_arrow:get_name() and not st:is_empty() then
                                    st:take_item()
                                    v_inv:set_stack(src_list, k, st)
                                    arrow_taken = true
                                    break
                                end
                            end
                        end
                    end
                end

                if not arrow_taken then
                    return
                end

                wielded_item_meta:set_string('arrow_itemstack_string', core.serialize(v_itemstack_arrow:to_table()))
                wielded_item_meta:set_string('time_load', tostring(core.get_us_time()))

                wielded_item:set_name(v_bow_name .. '_semi_charged')

                XBows:set_wielditem_images(wielded_item, v_bow_name .. '_semi_charged')

                v_user:set_wielded_item(wielded_item, true)

                if bow_def.custom.sound_semi_charged and bow_def.custom.sound_semi_charged ~= '' then
                    core.sound_play({
                        name = bow_def.custom.sound_semi_charged,
                        gain = 0.6
                    }, {
                        to_player = v_player_name,
                        pitch = math.random(7, 13) / 10,
                        object = v_user
                    }, true)
                end
            end
        end, player_name, bow_name, itemstack_arrow, inv, itemstack_arrows)

        ---transition from semi-charged to fully charged and play sound when charge reaches full punch interval
        table.insert(self.charge_sound_after_job[player_name], core.after(charge_time,
            function(v_player_name, v_bow_name)
                local v_user = core.get_player_by_name(v_player_name)
                if not v_user or not v_user:is_valid() then
                    return
                end

                local wielded_item = v_user:get_wielded_item()
                local wielded_item_name = wielded_item:get_name()

                if wielded_item_name == v_bow_name .. '_semi_charged' then
                    local new_stack = ItemStack(wielded_item)
                    new_stack:set_name(v_bow_name .. '_charged')

                    XBows:set_wielditem_images(new_stack, new_stack:get_name())

                    v_user:set_wielded_item(new_stack, true)

                    local sound_loaded = bow_def.custom.sound_loaded
                    if sound_loaded and sound_loaded ~= '' then
                        core.sound_play({
                            name = sound_loaded,
                            gain = 0.6
                        }, {
                            to_player = v_player_name,
                            pitch = math.random(7, 13) / 10,
                            object = v_user
                        }, true)
                    end
                end
            end, player_name, bow_name))

        core.sound_play({
            name = bow_def.custom.sound_load,
            gain = 0.6
        }, {
            to_player = player_name,
            pitch = math.random(7, 13) / 10,
        }, true)

        return itemstack
    end

    return itemstack
end

---Shoot bow
---@param self XBows
---@param itemstack ItemStack
---@param user ObjectRef
---@param pointed_thing? PointedThingDef
---@return ItemStack
function XBows.shoot(self, itemstack, user, pointed_thing)
    local meta = itemstack:get_meta()
    local arrow_raw = meta:get_string('arrow_itemstack_string')
    if not arrow_raw or arrow_raw == '' then
        return itemstack
    end

    local arrow_data = core.deserialize(arrow_raw)
    if not arrow_data then
        return itemstack
    end

    ---@type ItemStack
    local arrow_itemstack = ItemStack(arrow_data)

    if arrow_itemstack:is_empty() then
        return itemstack
    end

    local time_shoot = core.get_us_time()
    local time_load = tonumber(meta:get_string('time_load'))
    local tflp = time_load and ((time_shoot - time_load) / 1000000) or 1.0

    local arrow_itemstack_meta = arrow_itemstack:get_meta()
    local arrow_name = arrow_itemstack:get_name()
    local is_arrow_from_quiver = arrow_itemstack_meta:get_int('is_arrow_from_quiver')
    local quiver_name = arrow_itemstack_meta:get_string('quiver_name')
    local found_arrow_stack_idx = arrow_itemstack_meta:get_int('found_arrow_stack_idx')
    local quiver_id = arrow_itemstack_meta:get_string('quiver_id')

    ---Handle HUD and 3d Quiver
    if is_arrow_from_quiver == 1 and quiver_id ~= '' then
        local detached_inv = XBowsQuiver:get_or_create_detached_inv(
            quiver_id,
            user:get_player_name()
        )

        if detached_inv then
            XBowsQuiver:udate_or_create_hud(user, detached_inv:get_list('main'), found_arrow_stack_idx)

            if detached_inv:is_empty('main') then
                XBowsQuiver:show_3d_quiver(user, { is_empty = true })
            else
                XBowsQuiver:show_3d_quiver(user)
            end
        end
    else
        local inv = user:get_inventory() --[[@as InvRef]]
        if not inv:is_empty('x_bows:arrow_inv') then
            XBowsQuiver:udate_or_create_hud(user, inv:get_list('x_bows:arrow_inv'))
        else
            ---no ammo (fake stack just for the HUD)
            XBowsQuiver:udate_or_create_hud(user, {
                ItemStack({ name = 'x_bows:no_ammo' })
            })
        end
    end

    local x_bows_registered_arrow_def = self.registered_arrows[arrow_name]

    if not x_bows_registered_arrow_def then
        return itemstack
    end

    local bow_name_charged = itemstack:get_name()
    ---Bow
    local x_bows_registered_bow_charged_def = self.registered_bows[bow_name_charged]
    if not x_bows_registered_bow_charged_def or not x_bows_registered_bow_charged_def.custom then
        return itemstack
    end
    local bow_name = x_bows_registered_bow_charged_def.custom.name
    local uses = x_bows_registered_bow_charged_def.custom.uses
    local crit_chance = x_bows_registered_bow_charged_def.custom.crit_chance
    ---Arrow
    local projectile_entity = x_bows_registered_arrow_def.custom.projectile_entity
    ---Quiver
    local x_bows_registered_quiver_def = self.registered_quivers[quiver_name]

    local _tool_capabilities = x_bows_registered_arrow_def.custom.tool_capabilities
    local quiver_xbows_def = x_bows_registered_quiver_def

    local bow_charge_time = x_bows_registered_bow_charged_def.custom.charge_time
        or (_tool_capabilities.full_punch_interval * (x_bows_registered_bow_charged_def.custom.charge_multiplier or 1.0))

    local eff_tool_capabilities = _tool_capabilities
    if bow_charge_time ~= _tool_capabilities.full_punch_interval then
        eff_tool_capabilities = table.copy(_tool_capabilities)
        eff_tool_capabilities.full_punch_interval = bow_charge_time
    end

    ---X Enchanting
    local x_enchanting = core.deserialize(meta:get_string('x_enchanting')) or {}

    local is_creative_user = self:is_creative(user:get_player_name())

    ---@type EnityStaticDataAttrDef
    local staticdata = {
        _arrow_name = arrow_name,
        _bow_name = bow_name,
        _user_name = user:get_player_name(),
        _player_look_dir = user:get_look_dir(),
        _is_critical_hit = false,
        _is_creative = is_creative_user,
        _tool_capabilities = eff_tool_capabilities,
        _tflp = tflp,
        _add_damage = 0,
        _x_enchanting = x_enchanting
    }

    ---crits, only on full charge interval
    if crit_chance and crit_chance > 1 and tflp >= bow_charge_time then
        if math.random(1, crit_chance) == 1 then
            staticdata._is_critical_hit = true
        end
    end

    ---speed multiply
    if quiver_xbows_def and quiver_xbows_def.custom.faster_arrows and quiver_xbows_def.custom.faster_arrows > 1 then
        staticdata._faster_arrows_multiplier = quiver_xbows_def.custom.faster_arrows
    end

    ---add quiver damage
    if quiver_xbows_def and quiver_xbows_def.custom.add_damage and quiver_xbows_def.custom.add_damage > 0 then
        staticdata._add_damage = staticdata._add_damage + quiver_xbows_def.custom.add_damage
    end

    ---sound
    local sound_name = x_bows_registered_bow_charged_def.custom.sound_shoot
    if staticdata._is_critical_hit then
        sound_name = x_bows_registered_bow_charged_def.custom.sound_shoot_crit
    end

    if user and user:is_player() and XBows.x_player_api then
        x_player_api.play_action(user, 'bow_shoot', true)
    end

    -- remove arrow meta to prevent multiple shots while waiting for async `after`
    meta:set_string('arrow_itemstack_string', '')
    meta:set_string('time_load', '')

    ---stop previous charged sound/transition jobs
    local player_name = user:get_player_name()
    if self.charge_sound_after_job[player_name] then
        for _, v in pairs(self.charge_sound_after_job[player_name]) do
            v:cancel()
        end

        self.charge_sound_after_job[player_name] = {}
    end

    ---stop punching close objects/nodes when shooting
    local function revert_bow_after_shot(step)
        local player = core.get_player_by_name(player_name)
        if not player or not player:is_valid() then
            return
        end

        step = (step or 0) + 1
        local controls = player:get_player_control()

        -- If player is still holding LMB/dig, wait until they release it
        -- because charged bow has range=0 and cannot melee punch close objects/nodes.
        -- Once released (or after fallback max timeout), safely revert to uncharged bow.
        if controls and (controls.LMB or controls.dig) and step < 16 then
            core.after(0.05, revert_bow_after_shot, step)
            return
        end

        local wield_item = player:get_wielded_item()
        local current_name = wield_item:get_name()

        if wield_item:get_count() > 0
            and (current_name == bow_name .. '_charged' or current_name == bow_name .. '_semi_charged')
        then
            local new_stack = ItemStack(wield_item)
            new_stack:set_name(bow_name)

            XBows:set_wielditem_images(new_stack, bow_name)

            player:set_wielded_item(new_stack, true)
        end
    end

    core.after(0.15, revert_bow_after_shot)

    local player_pos = user:get_pos()
    local obj = core.add_entity(
        {
            x = player_pos.x,
            y = player_pos.y + 1.5,
            z = player_pos.z
        },
        projectile_entity,
        core.serialize(staticdata)
    )

    if not obj then
        return itemstack
    end

    core.sound_play({
        name = sound_name,
        gain = 0.3,
    }, {
        pos = user:get_pos(),
        max_hear_distance = 10,
        pitch = math.random(7, 13) / 10,
    }, true)

    if not self:is_creative(user:get_player_name()) then
        local final_uses = uses
        if x_enchanting and x_enchanting.unbreaking and x_enchanting.unbreaking.value > 0 then
            final_uses = uses + (uses * (x_enchanting.unbreaking.value / 100.0))
        end
        itemstack:add_wear(65535 / final_uses)
    end

    if itemstack:get_count() == 0 then
        core.sound_play('default_tool_breaks', {
            gain = 0.3,
            pos = user:get_pos(),
            max_hear_distance = 10
        })
    end

    return itemstack
end

---Add new particle to XBow registration
---@param self XBows
---@param name string
---@param def ParticlespawnerDef|ParticlespawnerDefCustom
---@return nil
function XBows.register_particle_effect(self, name, def)
    if self.registered_particle_spawners[name] then
        core.log('warning', 'Particle effect "' .. name .. '" already exists and will not be overwritten.')
        return
    end

    self.registered_particle_spawners[name] = def
end

---Get particle effect from registered spawners table
---@param self XBows
---@param name string
---@param pos Vector|nil
---@param attached ObjectRef|nil
---@return number|boolean
function XBows.get_particle_effect_for_arrow(self, name, pos, attached)
    local orig_def = self.registered_particle_spawners[name]

    if not orig_def then
        core.log('warning', 'Particle effect "' .. name .. '" is not registered.')
        return false
    end

    local def = table.copy(orig_def)
    def.custom = def.custom or {}

    if attached then
        def.attached = attached
        def.time = 0
        def.amount = orig_def.amount or 12
    else
        pos = pos or vector.new(0, 0, 0)
        def.minpos = def.custom.minpos and vector.add(pos, def.custom.minpos) or pos
        def.maxpos = def.custom.maxpos and vector.add(pos, def.custom.maxpos) or pos
        if def.pos and type(def.pos) == 'table' and def.pos.min and def.pos.max then
            def.pos = {
                min = vector.add(pos, def.pos.min),
                max = vector.add(pos, def.pos.max)
            }
        end
    end

    return core.add_particlespawner(def--[[@as ParticlespawnerDef]] )
end

---Check if ammunition is allowed to charge this weapon
---@param self XBows
---@param weapon_name string
---@param ammo_name string
---@return boolean
function XBows.is_allowed_ammunition(self, weapon_name, ammo_name)
    local x_bows_weapon_def = self.registered_bows[weapon_name]

    if not x_bows_weapon_def then
        return false
    end

    if not x_bows_weapon_def.custom.allowed_ammunition then
        return true
    end

    if #x_bows_weapon_def.custom.allowed_ammunition == 0 then
        return false
    end

    return table_contains(x_bows_weapon_def.custom.allowed_ammunition, ammo_name)
end

----
--- ENTITY API
----

---Limits number `x` between `min` and `max` values
---@param x integer
---@param min integer
---@param max integer
---@return integer
local function limit(x, min, max)
    return math.min(math.max(x, min), max)
end

---Calculates physical knockback velocity for arrow hits
---@param direction_or_self table Direction vector (or self if called with method syntax)
---@param is_critical_or_dir boolean|table Whether the hit is critical (or direction)
---@param punch_enchantment_or_crit number|boolean|nil Value of Punch enchantment (or is_critical)
---@param punch_enchantment number|nil Value of Punch enchantment
---@return table Vector velocity
function XBows.calculate_knockback_velocity(direction_or_self, is_critical_or_dir, punch_enchantment_or_crit, punch_enchantment)
    local dir, is_crit, punch_val
    if type(direction_or_self) == 'table' and direction_or_self.registered_bows then
        dir = is_critical_or_dir
        is_crit = punch_enchantment_or_crit
        punch_val = punch_enchantment
    else
        dir = direction_or_self
        is_crit = is_critical_or_dir
        punch_val = punch_enchantment_or_crit
    end

    local norm_dir = dir and vector.copy(dir) or vector.new(0, 0, 1)
    norm_dir.y = 0
    if vector.length(norm_dir) > 0.001 then
        norm_dir = vector.normalize(norm_dir)
    else
        norm_dir = vector.new(0, 0, 1)
    end

    local horizontal_force = is_crit and 9.5 or 7.0
    local vertical_lift = is_crit and 4.2 or 3.6

    if punch_val and punch_val > 0 then
        local punch_mult = 1.0 + (punch_val / 100.0)
        horizontal_force = horizontal_force * punch_mult
        vertical_lift = math.min(7.0, vertical_lift * math.sqrt(punch_mult))
    end

    return vector.new(
        norm_dir.x * horizontal_force,
        vertical_lift,
        norm_dir.z * horizontal_force
    )
end

---Helper to calculate Body bone local position and rotation with front/back penetration
---@param x number
---@param y number
---@param z number
---@param rx number
---@param ry number
---@param rz number
---@return Vector bone_pos
---@return table bone_rot
local function calculate_body_transform(x, y, z, rx, ry, rz)
    local pz = -z
    local penetration = 2.8
    if z > 1.0 then
        -- Front shot: arrow enters from front (z > 1.0).
        -- Torso front surface is at bone z = -1.25.
        -- Shift inward towards positive bone z, embedding into the chest.
        pz = math.min(0.2, pz + penetration)
    elseif z < -1.0 then
        -- Back shot: arrow enters from back (z < -1.0).
        -- Torso back surface is at bone z = +1.25.
        -- Shift inward towards negative bone z, embedding into the back.
        pz = math.max(-0.2, pz - penetration)
    end
    return vector.new(-x, y - 6.5, pz), {
        x = rx,
        y = (ry + 180) % 360,
        z = rz
    }
end

---Calculate the appropriate bone, local position, and local rotation for arrow impact on humanoid targets
---@param target ObjectRef
---@param position Vector Local position in target's root reference frame (model units, 1 node = 10 units)
---@param rotation table Euler angles in degrees { x, y, z }
---@return string bone_name Target bone name, or '' if attaching to root
---@return Vector bone_pos Local position in bone's reference frame
---@return table bone_rot Local rotation in bone's reference frame
function XBows.calculate_impact_bone(target, position, rotation)
    if not target or not target:is_valid() or not position or not rotation then
        return '', position or vector.new(0, 0, 0), rotation or { x = 0, y = 0, z = 0 }
    end

    local is_humanoid = false
    if target:is_player() then
        is_humanoid = true
    else
        local props = target:get_properties()
        local mesh = props and props.mesh
        if mesh and type(mesh) == 'string' then
            if mesh == 'character.b3d' or mesh:find('^character.*%.b3d$')
                or mesh:find('3d_armor.*%.b3d$') or mesh:find('skinsdb.*%.b3d$')
                or mesh:find('x_bows.*character.*%.b3d$') then
                is_humanoid = true
            end
        end
    end

    if not is_humanoid then
        return '', position, rotation
    end

    local x = position.x
    local y = position.y
    local z = position.z
    local rx = rotation.x or 0
    local ry = rotation.y or 0
    local rz = rotation.z or 0

    local bone_name
    local bone_pos
    local bone_rot

    if y >= 12.5 then
        bone_name = 'Head'
        bone_pos = vector.new(-x, y - 12.8, -z)
        bone_rot = {
            x = rx,
            y = (ry + 180) % 360,
            z = rz
        }
    elseif y < 6.5 then
        if x > 0 then
            bone_name = 'Leg_Right'
            bone_pos = vector.new(1.0 - x, 6.5 - y, z)
            bone_rot = {
                x = rx,
                y = ry,
                z = (rz + 180) % 360
            }
        else
            bone_name = 'Leg_Left'
            bone_pos = vector.new(-1.0 - x, 6.5 - y, z)
            bone_rot = {
                x = rx,
                y = ry,
                z = (rz + 180) % 360
            }
        end
    else
        -- Mid-torso and arm vertical span
        if x > 2.0 then
            bone_name = 'Arm_Right'
            bone_pos = vector.new(3.15 - x, 12.0 - y, z)
            bone_rot = {
                x = rx,
                y = ry,
                z = (rz + 180) % 360
            }
        elseif x < -2.0 then
            bone_name = 'Arm_Left'
            bone_pos = vector.new(-3.15 - x, 12.0 - y, z)
            bone_rot = {
                x = rx,
                y = ry,
                z = (rz + 180) % 360
            }
        else
            bone_name = 'Body'
            bone_pos, bone_rot = calculate_body_transform(x, y, z, rx, ry, rz)
        end
    end

    -- Verify target supports bone positioning/attachment for this bone if queryable
    if target.get_bone_position then
        local bpos = target:get_bone_position(bone_name)
        if not bpos then
            -- Target model lacks this bone, try Body fallback
            local body_bpos = target:get_bone_position('Body')
            if body_bpos then
                bone_name = 'Body'
                bone_pos, bone_rot = calculate_body_transform(x, y, z, rx, ry, rz)
            else
                -- Fall back to root node attachment
                return '', position, rotation
            end
        end
    end

    return bone_name, bone_pos, bone_rot
end

---Get all active attached arrow child entities on a target object
---@param target ObjectRef
---@return table List of ObjectRef arrow children
function XBows.get_attached_arrows(target)
    if not target or not target:is_valid() then
        return {}
    end
    if not target.get_children then
        return {}
    end
    local arrow_children = {}
    local children = target:get_children()
    if type(children) ~= 'table' then
        return {}
    end
    for _, child in ipairs(children) do
        if child and child:is_valid() then
            local child_ent = child:get_luaentity()
            if child_ent and (child_ent._is_arrow or (child_ent.name and child_ent.name:find('^x_bows:'))) then
                table.insert(arrow_children, child)
            end
        end
    end
    return arrow_children
end

---Safely cleanup and remove an attached arrow entity
---@param arrow_obj ObjectRef
local function remove_arrow_entity(arrow_obj)
    if arrow_obj and arrow_obj:is_valid() then
        local ent = arrow_obj:get_luaentity()
        if ent and XBowsEntityDef and XBowsEntityDef.cleanup then
            XBowsEntityDef.cleanup(ent)
        end
        arrow_obj:remove()
    end
end

---Transfer attached arrows from source player to corpse entity
---@param source_player ObjectRef
---@param corpse_obj ObjectRef
---@return number count Number of arrows transferred
function XBows.transfer_arrows_to_corpse(source_player, corpse_obj)
    if not source_player or not source_player:is_valid() then
        return 0
    end
    if not corpse_obj or not corpse_obj:is_valid() then
        return 0
    end

    local arrows = XBows.get_attached_arrows(source_player)
    local count = 0
    if #arrows > 0 then
        for _, arrow in ipairs(arrows) do
            if arrow and arrow:is_valid() then
                local _, bone, pos, rot = arrow:get_attach()
                bone = bone or ''
                pos = pos or vector.new(0, 0, 0)
                rot = rot or { x = 0, y = 0, z = 0 }

                local target_bone = bone
                local target_pos = pos
                local target_rot = rot

                -- If arrow was attached to root '', convert to Body or lay transform
                if target_bone == '' then
                    local has_body = false
                    if corpse_obj.get_bone_position then
                        local bpos = corpse_obj:get_bone_position('Body')
                        if bpos then
                            has_body = true
                        end
                    else
                        has_body = true
                    end

                    if has_body then
                        target_bone = 'Body'
                        target_pos, target_rot = calculate_body_transform(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z)
                    else
                        -- Pure root lay pose transform
                        target_pos = vector.new(pos.x, 2.0 + pos.z, -(pos.y - 6.5))
                        target_rot = { x = rot.x - 90, y = rot.y, z = rot.z }
                    end
                end

                arrow:set_attach(corpse_obj, target_bone, target_pos, target_rot, true)

                local arrow_ent = arrow.get_luaentity and arrow:get_luaentity()
                if arrow_ent then
                    arrow_ent._attached = true
                    arrow_ent._attached_to = arrow_ent._attached_to or {}
                    arrow_ent._attached_to.type = 'object'
                    arrow_ent._attached_to.pos = target_pos
                    arrow_ent._attached_bone = target_bone
                end

                count = count + 1
            end
        end
    end

    -- Cap attached arrows on corpse to 5
    local corpse_arrows = XBows.get_attached_arrows(corpse_obj)
    while #corpse_arrows > 5 do
        remove_arrow_entity(table.remove(corpse_arrows, 1))
    end

    return count
end

---Safely clear and remove any attached arrows from an object (e.g. living player on respawn)
---@param target ObjectRef
---@return number count Number of arrows removed
function XBows.clear_attached_arrows(target)
    local arrows = XBows.get_attached_arrows(target)
    local count = 0
    for _, arrow in ipairs(arrows) do
        remove_arrow_entity(arrow)
        count = count + 1
    end
    return count
end

---Safely clean up all attached arrows from a corpse before or upon corpse removal
---@param corpse_obj ObjectRef
---@return number count
function XBows.cleanup_corpse_arrows(corpse_obj)
    return XBows.clear_attached_arrows(corpse_obj)
end

---Function receive a "luaentity" table as `self`. Called when the object is instantiated.
---@param self EntityDef|EntityDefCustom|XBows
---@param selfObj EnityCustomAttrDef
---@param staticdata string
---@param dtime_s? integer|number
---@return nil
function XBowsEntityDef.on_activate(self, selfObj, staticdata, dtime_s)
    if not selfObj or not staticdata or staticdata == '' then
        selfObj.object:remove()
        return
    end

    local _staticdata = core.deserialize(staticdata) --[[@as EnityStaticDataAttrDef]]

    -- set/reset - do not inherit from previous entity table
    selfObj._velocity = { x = 0, y = 0, z = 0 }
    selfObj._old_pos = nil
    selfObj._attached = false
    selfObj._attached_to = {
        type = '',
        pos = nil
    }
    selfObj._attached_bone = ''
    selfObj._is_arrow = true
    selfObj._trail_spawner_id = nil
    selfObj._bubble_spawner_id = nil
    selfObj._has_particles = false
    selfObj._lifetimer = 60
    selfObj._nodechecktimer = 0.5
    selfObj._is_drowning = false
    selfObj._in_liquid = false
    selfObj._shot_from_pos = selfObj.object:get_pos()
    selfObj._arrow_name = _staticdata._arrow_name
    selfObj._bow_name = _staticdata._bow_name
    selfObj._user_name = _staticdata._user_name
    selfObj._user = core.get_player_by_name(_staticdata._user_name)
    selfObj._tflp = _staticdata._tflp
    selfObj._tool_capabilities = _staticdata._tool_capabilities
    selfObj._is_critical_hit = _staticdata._is_critical_hit
    selfObj._faster_arrows_multiplier = _staticdata._faster_arrows_multiplier
    selfObj._add_damage = _staticdata._add_damage
    selfObj._caused_damage = 0
    selfObj._caused_knockback = 0

    local x_bows_registered_arrow_def = self.registered_arrows[selfObj._arrow_name]
    selfObj._arrow_particle_effect = x_bows_registered_arrow_def.custom.particle_effect
    selfObj._arrow_particle_effect_crit = x_bows_registered_arrow_def.custom.particle_effect_crit
    selfObj._arrow_particle_effect_fast = x_bows_registered_arrow_def.custom.particle_effect_fast
    selfObj._flyby_sound_played = {
        ['player_name'] = true
    }

    ---Bow Def
    local x_bows_registered_bow_def = self.registered_bows[selfObj._bow_name]
    selfObj._sound_hit = x_bows_registered_bow_def.custom.sound_hit
    local bow_strength = x_bows_registered_bow_def.custom.strength
    local acc_x_min = x_bows_registered_bow_def.custom.acc_x_min
    local acc_y_min = x_bows_registered_bow_def.custom.acc_y_min
    local acc_z_min = x_bows_registered_bow_def.custom.acc_z_min
    local acc_x_max = x_bows_registered_bow_def.custom.acc_x_max
    local acc_y_max = x_bows_registered_bow_def.custom.acc_y_max
    local acc_z_max = x_bows_registered_bow_def.custom.acc_z_max
    local gravity = x_bows_registered_bow_def.custom.gravity
    local bow_strength_min = x_bows_registered_bow_def.custom.strength_min
    local bow_strength_max = x_bows_registered_bow_def.custom.strength_max

    ---X Enchanting
    selfObj._x_enchanting = _staticdata._x_enchanting or {}

    ---acceleration
    selfObj._player_look_dir = _staticdata._player_look_dir
        or (selfObj._user and selfObj._user:is_valid() and selfObj._user:get_look_dir())
        or vector.new(0, 0, 1)

    selfObj._acc_x = 0
    selfObj._acc_y = gravity or self.arrow_gravity or -19.62
    selfObj._acc_z = 0

    if acc_x_min and acc_x_max then
        selfObj._acc_x = math.random(acc_x_min, acc_x_max)
    end

    if acc_y_min and acc_y_max then
        selfObj._acc_y = math.random(acc_y_min, acc_y_max)
    end

    if acc_z_min and acc_z_max then
        selfObj._acc_z = math.random(acc_z_min, acc_z_max)
    end

    ---strength (quadratic charge easing curve: (progress^2 + 2*progress) / 3)
    local full_interval = (selfObj._tool_capabilities and selfObj._tool_capabilities.full_punch_interval) or 1.0
    local charge_progress = math.min(1.0, math.max(0.05, (selfObj._tflp or full_interval) / full_interval))
    local strength_multiplier = (charge_progress * charge_progress + 2.0 * charge_progress) / 3.0

    ---faster arrow, only on full punch interval
    if charge_progress >= 1.0 and selfObj._faster_arrows_multiplier then
        strength_multiplier = strength_multiplier + (strength_multiplier / selfObj._faster_arrows_multiplier)
    end

    if bow_strength_max and bow_strength_min then
        bow_strength = math.random(bow_strength_min, bow_strength_max)
    end

    selfObj._strength = bow_strength * strength_multiplier
    selfObj._charge_ratio = charge_progress
    selfObj._charge_curve = strength_multiplier

    ---rotation factor
    local x_bows_registered_entity_def = self.registered_entities[selfObj.name]
    selfObj._rotation_factor = x_bows_registered_entity_def._custom.rotation_factor

    if type(selfObj._rotation_factor) == 'function' then
        selfObj._rotation_factor = selfObj._rotation_factor()
    end

    ---add infotext
    selfObj.object:set_properties({
        infotext = selfObj._arrow_name,
    })

    ---idle animation
    if x_bows_registered_entity_def and x_bows_registered_entity_def._custom.animations.idle then
        selfObj.object:set_animation(unpack(x_bows_registered_entity_def._custom.animations.idle)--[[@as table]])
    end

    ---counter, e.g. for initial values set `on_step`
    selfObj._step_count = 0

    ---Callbacks
    local on_after_activate_callback = x_bows_registered_arrow_def.custom.on_after_activate

    if on_after_activate_callback then
        on_after_activate_callback(selfObj)
    end
end

---Calculate directional node impact shrapnel velocity based on surface normal (Newton's 3rd law recoil)
---@param normal Vector
---@return Vector, Vector
local function get_shrapnel_velocity(normal)
    local tangent = 1.6

    -- Floor: blast upward and outward
    if normal.y > 0.5 then
        return vector.new(-tangent, 1.8, -tangent), vector.new(tangent, 4.0, tangent)
    -- Ceiling: blast downward and outward
    elseif normal.y < -0.5 then
        return vector.new(-tangent, -3.5, -tangent), vector.new(tangent, -1.2, tangent)
    end

    -- Vertical wall: blast horizontally outward along surface normal with slight upward kick
    local min_x = normal.x > 0.3 and 1.2 or (normal.x < -0.3 and -3.5 or -tangent)
    local max_x = normal.x > 0.3 and 3.5 or (normal.x < -0.3 and -1.2 or tangent)
    local min_z = normal.z > 0.3 and 1.2 or (normal.z < -0.3 and -3.5 or -tangent)
    local max_z = normal.z > 0.3 and 3.5 or (normal.z < -0.3 and -1.2 or tangent)

    return vector.new(min_x, 0.4, min_z), vector.new(max_x, 2.5, max_z)
end

---Check if an object is a valid, hittable player or entity (matches x_obsidianmese improvements)
---@param object ObjectRef|nil
---@param shooter_name string|nil
---@return boolean
function XBows.is_valid_player_or_entity(self, object, shooter_name)
    if not object or not object:is_valid() then
        return false
    end

    if object:is_player() then
        if object:get_hp() <= 0 then
            return false
        end
        if shooter_name and object:get_player_name() == shooter_name then
            return false
        end
        return true
    end

    local luaentity = object:get_luaentity()
    if not luaentity then
        return false
    end

    -- Do not hit dropped items or other arrow projectiles
    local name = luaentity.name or ''
    if name == '__builtin:item' or name:find('^x_bows:') or luaentity._is_arrow then
        return false
    end

    -- Check for health, hp, fleshy armor group, or mob classification (Creatura, CMI, Mobs Redo, physical)
    local armor_groups = object:get_armor_groups() or {}
    local ent_armor = luaentity.armor_groups or {}
    local fleshy = (armor_groups.fleshy or 0) > 0 or (ent_armor.fleshy or 0) > 0

    if luaentity.physical
        or object:get_properties().physical
        or luaentity._creatura_mob
        or luaentity._cmi_is_mob
        or luaentity.health
        or luaentity.hp
        or fleshy
    then
        return true
    end

    return false
end

---Clean up entity runtime resources (e.g. attached particle spawners)
---@param selfObj EnityCustomAttrDef
function XBowsEntityDef.cleanup(selfObj)
    if selfObj._trail_spawner_id then
        core.delete_particlespawner(selfObj._trail_spawner_id)
        selfObj._trail_spawner_id = nil
    end
    if selfObj._bubble_spawner_id then
        core.delete_particlespawner(selfObj._bubble_spawner_id)
        selfObj._bubble_spawner_id = nil
    end
end

---Function receive a "luaentity" table as `self`. Called when the object is deactivated.
---@param self XBows
---@param selfObj EnityCustomAttrDef
---@param removal boolean True if object is being removed, false if mapblock is unloaded
---@return nil
function XBowsEntityDef.on_deactivate(self, selfObj, removal)
    XBowsEntityDef.cleanup(selfObj)

    -- In multiplayer: if mapblock unloads while arrow is still flying in mid-air,
    -- remove it so it does not freeze as a permanent ghost projectile at chunk borders
    if not removal and not selfObj._attached then
        selfObj.object:remove()
    end
end

---Function receive a "luaentity" table as `self`. Called when the object dies.
---@param self XBows
---@param selfObj EnityCustomAttrDef
---@param killer ObjectRef|nil
---@return nil
function XBowsEntityDef.on_death(self, selfObj, killer)
    XBowsEntityDef.cleanup(selfObj)

    -- Prevent duplicate drops if called multiple times
    if selfObj._dropped then
        return
    end
    selfObj._dropped = true

    -- Creative mode or Infinity enchantment - arrows cannot be retrieved
    if selfObj._is_creative
        or (selfObj._x_enchanting and selfObj._x_enchanting.infinity and selfObj._x_enchanting.infinity.value > 0)
    then
        return
    end

    local drop_pos = (selfObj.object and selfObj.object:is_valid() and selfObj.object:get_pos()) or selfObj._old_pos
    if drop_pos then
        core.item_drop(ItemStack(selfObj._arrow_name), nil, vector.round(drop_pos))
    end
end

--- Function receive a "luaentity" table as `self`. Called on every server tick, after movement and collision processing.
---`dtime`: elapsed time since last call. `moveresult`: table with collision info (only available if physical=true).
---@param self XBows
---@param selfObj EnityCustomAttrDef
---@param dtime number
---@return nil
function XBowsEntityDef.on_step(self, selfObj, dtime)
    selfObj._step_count = selfObj._step_count + 1

    -- Initialize velocity, acceleration, yaw, and particle trail on step 1
    if selfObj._step_count == 1 then
        selfObj.object:set_velocity(vector.multiply(selfObj._player_look_dir, selfObj._strength))
        selfObj.object:set_acceleration({ x = selfObj._acc_x, y = selfObj._acc_y, z = selfObj._acc_z })
        selfObj.object:set_yaw(core.dir_to_yaw(selfObj._player_look_dir))

        -- Attached particle trail: spawned once at flight start, deleted on impact/water
        -- (Matches x_obsidianmese attached projectile trail to avoid per-tick packet spam)
        if not selfObj._trail_spawner_id and not selfObj._in_liquid then
            local p_name
            if selfObj._tflp >= selfObj._tool_capabilities.full_punch_interval then
                if selfObj._is_critical_hit then
                    p_name = selfObj._arrow_particle_effect_crit
                elseif selfObj._faster_arrows_multiplier then
                    p_name = selfObj._arrow_particle_effect_fast
                else
                    p_name = selfObj._arrow_particle_effect
                end
            end
            if p_name then
                selfObj._trail_spawner_id = self:get_particle_effect_for_arrow(p_name, nil, selfObj.object)
            end
        end
    end

    -- Attached arrow processing (early return: zero raycasts or physics overhead when stuck)
    if selfObj._attached then
        selfObj._lifetimer = selfObj._lifetimer - dtime
        if selfObj._lifetimer <= 0 then
            XBowsEntityDef.cleanup(selfObj)
            selfObj.object:remove()
            return
        end

        -- Check if attached to node and node was dug
        if selfObj._attached_to.type == 'node' then
            selfObj._nodechecktimer = selfObj._nodechecktimer - dtime
            if selfObj._nodechecktimer <= 0 then
                selfObj._nodechecktimer = 0.5
                local node = core.get_node_or_nil(selfObj._attached_to.pos)
                if not node or node.name == 'air' then
                    -- Node was dug: detach and let arrow drop by gravity
                    selfObj._attached = false
                    selfObj._attached_to.type = ''
                    selfObj._attached_to.pos = nil
                    selfObj._old_pos = selfObj.object:get_pos()
                    selfObj.object:set_velocity({ x = 0, y = -3, z = 0 })
                    selfObj.object:set_acceleration({ x = 0, y = -9.81, z = 0 })
                    selfObj.object:set_properties({ collisionbox = { 0, 0, 0, 0, 0, 0 } })
                    return
                end
            end
        elseif selfObj._attached_to.type == 'object' then
            -- Remove arrow if parent entity died or despawned
            if not selfObj.object:get_attach() then
                XBowsEntityDef.cleanup(selfObj)
                selfObj.object:remove()
                return
            end
        end

        return
    end

    -- In-flight position and lifetime checks
    local pos = selfObj.object:get_pos()
    if not pos then
        XBowsEntityDef.cleanup(selfObj)
        selfObj.object:remove()
        return
    end

    selfObj._lifetimer = selfObj._lifetimer - dtime
    if selfObj._lifetimer <= 0 then
        XBowsEntityDef.cleanup(selfObj)
        selfObj.object:remove()
        return
    end

    selfObj._old_pos = selfObj._old_pos or pos

    -- In-flight pitch adjustment
    local velocity = selfObj.object:get_velocity()
    if velocity then
        local v_rotation = selfObj.object:get_rotation()
        local horiz = math.sqrt(velocity.x ^ 2 + velocity.z ^ 2)
        local pitch = math.atan2(velocity.y, horiz)

        selfObj.object:set_rotation({
            x = pitch,
            y = v_rotation.y,
            z = v_rotation.z + (selfObj._rotation_factor or math.pi / 2)
        })
    end

    -- Flyby sound for near misses (runs in open air outside collision loop, throttled to every 2 steps)
    if selfObj._step_count % 2 == 0 then
        for _, object in ipairs(core.get_objects_inside_radius(pos, 5)) do
            if object:is_player()
                and object:get_hp() > 0
                and object:get_player_name() ~= selfObj._user_name
                and not selfObj._flyby_sound_played[object:get_player_name()]
            then
                selfObj._flyby_sound_played[object:get_player_name()] = true
                local p2 = object:get_pos()
                if p2 then
                    local distance = math.max(1, math.round(vector.distance(pos, p2)))
                    local gain = math.min(1.0, 1.0 / distance)

                    core.sound_play({
                        name = 'x_bows_arrow_flyby',
                        gain = gain
                    }, {
                        to_player = object:get_player_name(),
                        pitch = math.random(7, 13) / 10,
                    }, true)
                end
            end
        end
    end

    -- Raycast collision detection (using clean for pt in ray iterator)
    local ray = core.raycast(selfObj._old_pos, pos, true, true)
    local hit = false
    local in_liquid = false

    for pointed_thing in ray do
        local ip_pos = pointed_thing.intersection_point or pos
        selfObj.pointed_thing = pointed_thing

        if pointed_thing.type == 'object'
            and self:is_valid_player_or_entity(pointed_thing.ref, selfObj._user_name)
        then
            -- Stop attached particle trails (air trail & bubble trail)
            XBowsEntityDef.cleanup(selfObj)

            -- Shooter feedback sound
            if selfObj._user_name then
                if pointed_thing.ref:is_player() then
                    core.sound_play('x_bows_arrow_successful_hit', {
                        to_player = selfObj._user_name,
                        gain = 0.3
                    })
                else
                    core.sound_play({
                        name = selfObj._sound_hit,
                        gain = 0.6
                    }, {
                        to_player = selfObj._user_name,
                        pitch = math.random(7, 13) / 10
                    }, true)
                end
            end

            selfObj.object:set_velocity({ x = 0, y = 0, z = 0 })
            selfObj.object:set_acceleration({ x = 0, y = 0, z = 0 })

            -- Calculate damage
            local full_punch_interval = selfObj._tool_capabilities.full_punch_interval or 1.0
            local tflp = selfObj._tflp or full_punch_interval
            local charge_ratio = limit(tflp / full_punch_interval, 0.0, 1.0)
            local charge_curve = selfObj._charge_curve or ((charge_ratio * charge_ratio + 2.0 * charge_ratio) / 3.0)
            local base_arrow_damage = (selfObj._tool_capabilities.damage_groups and selfObj._tool_capabilities.damage_groups.fleshy) or 2
            local base_damage = base_arrow_damage * charge_curve

            if selfObj._add_damage and selfObj._add_damage > 0 then
                base_damage = base_damage + selfObj._add_damage
            end

            if selfObj._x_enchanting.power and selfObj._x_enchanting.power.value > 0 then
                base_damage = base_damage * (1.0 + (selfObj._x_enchanting.power.value / 100.0))
            end

            if selfObj._is_critical_hit then
                base_damage = base_damage * 2
            end

            -- Armor mitigation and inverse scaling (matches x_obsidianmese)
            local is_player = pointed_thing.ref:is_player()
            local target_armor_groups = pointed_thing.ref:get_armor_groups() or {}
            local ent = not is_player and pointed_thing.ref:get_luaentity()
            if ent and ent.armor_groups then
                for k, v in pairs(ent.armor_groups) do
                    if target_armor_groups[k] == nil then
                        target_armor_groups[k] = v
                    end
                end
            end

            local is_immortal = is_player
                and ((target_armor_groups.immortal or 0) > 0)
                or ((target_armor_groups.fleshy or 0) == 0 and (target_armor_groups.immortal or 0) > 0)

            local punch_fleshy = 0
            local desired_damage = 0

            if not is_immortal and base_damage > 0 then
                local fleshy_group = target_armor_groups.fleshy or 100
                local mitigation = math.max(0.25, math.min(1.0, fleshy_group / 100.0))
                desired_damage = math.max(1, math.floor(base_damage * mitigation + 0.5))

                if fleshy_group > 0 and fleshy_group < 100 then
                    punch_fleshy = math.ceil(desired_damage * (100.0 / fleshy_group))
                else
                    punch_fleshy = desired_damage
                end
            end

            -- Flight trajectory for knockback and local attachment orientation
            local flight_dir
            if selfObj._shot_from_pos and ip_pos and vector.distance(selfObj._shot_from_pos, ip_pos) > 0.001 then
                flight_dir = vector.direction(selfObj._shot_from_pos, ip_pos)
            else
                local vel = selfObj.object:get_velocity()
                flight_dir = (vel and vector.length(vel) > 0.001) and vector.normalize(vel) or vector.new(0, 0, 1)
            end

            -- Knockback calculation
            local distance = selfObj._shot_from_pos and ip_pos and vector.distance(selfObj._shot_from_pos, ip_pos) or 0
            local old_calculate_knockback = core.calculate_knockback
            local knockback = old_calculate_knockback(
                pointed_thing.ref,
                selfObj.object,
                full_punch_interval,
                {
                    full_punch_interval = full_punch_interval,
                    damage_groups = { fleshy = desired_damage },
                },
                flight_dir,
                distance,
                desired_damage
            )

            local shooter = (selfObj._user_name and core.get_player_by_name(selfObj._user_name))
                or (selfObj._user and selfObj._user:is_valid() and selfObj._user:is_player() and selfObj._user)
                or selfObj.object

            local shooter_is_player = shooter and shooter:is_player()
            local is_pvp = is_player and shooter_is_player and (shooter:get_player_name() ~= pointed_thing.ref:get_player_name())
            local pvp_blocked = is_pvp and not XBows.pvp

            if pvp_blocked then
                desired_damage = 0
                punch_fleshy = 0
            end

            if is_player then
                if not pvp_blocked then
                    -- For players: use add_velocity with punch knockback=0 to avoid engine C++ double-knockback jitter
                    local punch_val = selfObj._x_enchanting.punch and selfObj._x_enchanting.punch.value
                    local knockback_vel = XBows.calculate_knockback_velocity(flight_dir, selfObj._is_critical_hit, punch_val)
                    pointed_thing.ref:add_velocity(knockback_vel)
                end
            else
                -- For mobs/entities: apply velocity and pass knockback into damage_groups so mobs_redo / mobkit
                -- receive their intended knockback impulse and properly trigger their runaway flee behavior
                local mob_kb = knockback
                local punch_val = selfObj._x_enchanting.punch and selfObj._x_enchanting.punch.value
                if punch_val and punch_val > 0 then
                    mob_kb = mob_kb * (1.0 + (punch_val / 100.0))
                end
                pointed_thing.ref:add_velocity({
                    x = flight_dir.x * mob_kb,
                    y = 5,
                    z = flight_dir.z * mob_kb
                })
            end

            pointed_thing.ref:punch(
                shooter,
                full_punch_interval,
                {
                    full_punch_interval = full_punch_interval,
                    damage_groups = { fleshy = punch_fleshy, knockback = is_player and 0 or knockback }
                },
                flight_dir
            )

            selfObj._caused_damage = desired_damage
            selfObj._caused_knockback = knockback

            if desired_damage > 0 then
                XBows:show_damage_numbers(selfObj.object:get_pos(), desired_damage, selfObj._is_critical_hit, shooter)
            end

            -- If mob entity died or was removed from this hit, remove arrow immediately.
            -- For players, keep the arrow attached so it transfers to their fallen corpse.
            if not is_player and pointed_thing.ref:get_hp() <= 0 then
                selfObj.object:remove()
                return
            end

            if not XBows.settings.x_bows_attach_arrows_to_entities and not is_player then
                selfObj.object:remove()
                return
            end

            -- Attach arrow to target
            local target = pointed_thing.ref
            local target_pos = target:get_pos()
            if not target_pos then
                selfObj.object:remove()
                return
            end

            local target_yaw = (is_player and target:get_look_horizontal()) or target:get_yaw() or 0
            local cos_y = math.cos(target_yaw)
            local sin_y = math.sin(target_yaw)

            -- Hit position in target's local reference frame
            local world_delta = vector.subtract(ip_pos, target_pos)
            local local_x = world_delta.x * cos_y + world_delta.z * sin_y
            local local_y = world_delta.y
            local local_z = -world_delta.x * sin_y + world_delta.z * cos_y

            -- Flight trajectory in target's local reference frame
            local local_dir_x = flight_dir.x * cos_y + flight_dir.z * sin_y
            local local_dir_y = flight_dir.y
            local local_dir_z = -flight_dir.x * sin_y + flight_dir.z * cos_y

            -- Offset slightly outward along flight path so dynamic mob meshes don't bury the arrow.
            -- For players, keep at 0 so arrow doesn't float away from the player mesh.
            local outward_offset = is_player and 0.0 or 0.20
            local_x = local_x - (local_dir_x * outward_offset)
            local_y = local_y - (local_dir_y * outward_offset)
            local_z = local_z - (local_dir_z * outward_offset)

            -- Irrlicht Euler convention: rot_x = -pitch, rot_y = atan2(dx, dz)
            local horiz_len = math.sqrt(local_dir_x ^ 2 + local_dir_z ^ 2)
            local rot_x = -math.deg(math.atan2(local_dir_y, horiz_len))
            local rot_y = math.deg(math.atan2(local_dir_x, local_dir_z))

            local rotation = {
                x = rot_x + math.random(-3, 3),
                y = rot_y + math.random(-3, 3),
                z = math.random(-25, 25)
            }

            -- Universal entity scale normalization (Animalia, Creatura, etc.)
            local obj_to_props = target:get_properties()
            local target_vs = obj_to_props.visual_size or { x = 1, y = 1 }
            local vs_x = (target_vs.x and target_vs.x > 0) and target_vs.x or 1
            local vs_y = (target_vs.y and target_vs.y > 0) and target_vs.y or 1

            selfObj.object:set_properties({
                visual_size = { x = 1.0 / vs_x, y = 1.0 / vs_y }
            })

            local position = vector.new(
                (local_x * 10) / vs_x,
                (local_y * 10) / vs_y,
                (local_z * 10) / vs_x
            )

            local bone_name, bone_pos, bone_rot = XBows.calculate_impact_bone(target, position, rotation)

            ---`after` here prevents visual glitch when the arrow still shows as huge for a split second
            ---before the new calculated scale is applied
            core.after(0, function()
                if selfObj.object and selfObj.object:is_valid()
                    and target and target:is_valid()
                    and selfObj.object:get_pos() and target:get_pos()
                then
                    selfObj.object:set_attach(
                        target,
                        bone_name,
                        bone_pos,
                        bone_rot,
                        true
                    )
                end
            end)

            selfObj._attached = true
            selfObj._attached_to.type = pointed_thing.type
            selfObj._attached_to.pos = bone_pos
            selfObj._attached_bone = bone_name

            -- Cap attached arrows on entity across all arrow types
            local arrow_children = XBows.get_attached_arrows(target)
            while #arrow_children > 5 do
                remove_arrow_entity(table.remove(arrow_children, 1))
            end

            if is_player then
                local on_hit_player_cb = self.registered_arrows[selfObj._arrow_name].custom.on_hit_player
                if on_hit_player_cb then
                    on_hit_player_cb(selfObj, pointed_thing)
                end
            else
                local on_hit_entity_cb = self.registered_arrows[selfObj._arrow_name].custom.on_hit_entity
                if on_hit_entity_cb then
                    on_hit_entity_cb(selfObj, pointed_thing)
                end
            end

            hit = true
            break

        elseif pointed_thing.type == 'node' then
            local node = core.get_node_or_nil(pointed_thing.under)
            local node_def = node and core.registered_nodes[node.name]

            if node_def then
                if node_def.drawtype == 'liquid' then
                    in_liquid = true
                    local viscosity = (node_def.liquid_viscosity and node_def.liquid_viscosity > 0)
                        and node_def.liquid_viscosity or 1

                    if not selfObj._in_liquid then
                        -- Initial liquid entry: shock drag, replace air trail with attached bubble trail
                        selfObj._in_liquid = true

                        if selfObj._trail_spawner_id then
                            core.delete_particlespawner(selfObj._trail_spawner_id)
                            selfObj._trail_spawner_id = nil
                        end

                        if not selfObj._bubble_spawner_id then
                            selfObj._bubble_spawner_id = self:get_particle_effect_for_arrow('bubble', nil, selfObj.object)
                        end

                        local cur_vel = selfObj.object:get_velocity()
                        if cur_vel then
                            local entry_factor = math.max(0.20, 0.40 / (viscosity * 0.5 + 0.5))
                            local new_vel = {
                                x = cur_vel.x * entry_factor,
                                y = math.max(-3.5, cur_vel.y * entry_factor),
                                z = cur_vel.z * entry_factor
                            }
                            selfObj.object:set_velocity(new_vel)
                            selfObj.object:set_acceleration({ x = 0, y = -3.0, z = 0 })
                        end
                    else
                        -- Continuous liquid ballistics: smooth hydrodynamic drag & natural downward terminal sinking
                        local cur_vel = selfObj.object:get_velocity()
                        if cur_vel then
                            local horiz = math.sqrt(cur_vel.x ^ 2 + cur_vel.z ^ 2)
                            local terminal_sink = -2.8 * math.sqrt(viscosity)

                            if horiz > 0.15 then
                                -- Forward speed bleeds off smoothly without packet-spamming oscillation
                                local drag_factor = math.max(0.0, 1.0 - (3.5 * viscosity * dtime))
                                local new_y = cur_vel.y > terminal_sink
                                    and math.max(terminal_sink, cur_vel.y - (4.0 * dtime))
                                    or terminal_sink

                                selfObj.object:set_velocity({
                                    x = cur_vel.x * drag_factor,
                                    y = new_y,
                                    z = cur_vel.z * drag_factor
                                })
                                selfObj.object:set_acceleration({ x = 0, y = -1.5, z = 0 })
                            elseif not selfObj._is_drowning then
                                -- Settled sinking phase: steady terminal downward sinking.
                                -- Zero acceleration avoids continuous network packet floods to clients
                                selfObj._is_drowning = true
                                selfObj.object:set_velocity({ x = 0, y = terminal_sink, z = 0 })
                                selfObj.object:set_acceleration({ x = 0, y = 0, z = 0 })
                            end
                        end
                    end
                elseif node_def.walkable then
                    -- Stop attached particle trails (air trail & bubble trail)
                    XBowsEntityDef.cleanup(selfObj)

                    selfObj.object:set_velocity({ x = 0, y = 0, z = 0 })
                    selfObj.object:set_acceleration({ x = 0, y = 0, z = 0 })
                    selfObj.object:set_pos(ip_pos)
                    selfObj.object:set_rotation(selfObj.object:get_rotation())
                    selfObj._attached = true
                    selfObj._attached_to.type = pointed_thing.type
                    selfObj._attached_to.pos = pointed_thing.under
                    selfObj.object:set_properties({ collisionbox = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2 } })

                    -- Mesecons target node support
                    if XBows.mesecons and node.name == 'x_bows:target' then
                        local distance = vector.distance(pointed_thing.under, ip_pos)
                        distance = math.floor(distance * 100) / 100
                        if distance < 0.54 then
                            mesecon.receptor_on(pointed_thing.under)
                            core.get_node_timer(pointed_thing.under):start(2)
                        end
                    end

                    -- Cap attached arrows in 1 node radius across all arrow types
                    local node_arrows = {}
                    for _, object in ipairs(core.get_objects_inside_radius(pointed_thing.under, 1)) do
                        if not object:is_player() then
                            local ent_obj = object:get_luaentity()
                            if ent_obj and (ent_obj._is_arrow or (ent_obj.name and ent_obj.name:find('^x_bows:'))) then
                                table.insert(node_arrows, object)
                            end
                        end
                    end
                    if #node_arrows > 5 then
                        local old_arrow = node_arrows[1]
                        local old_ent = old_arrow:get_luaentity()
                        if old_ent then
                            XBowsEntityDef.cleanup(old_ent)
                        end
                        old_arrow:remove()
                    end

                    -- Wiggle animation
                    local x_bows_registered_entity_def = self.registered_entities[selfObj.name]
                    if x_bows_registered_entity_def and x_bows_registered_entity_def._custom.animations.on_hit_node then
                        selfObj.object:set_animation(
                            unpack(x_bows_registered_entity_def._custom.animations.on_hit_node)
                        )
                    end

                    local on_hit_node_cb = self.registered_arrows[selfObj._arrow_name].custom.on_hit_node
                    if on_hit_node_cb then
                        on_hit_node_cb(selfObj, pointed_thing)
                    end

                    local shooter = (selfObj._user_name and core.get_player_by_name(selfObj._user_name))
                        or (selfObj._user and selfObj._user:is_valid() and selfObj._user:is_player() and selfObj._user)

                    if node_def.on_punch and shooter then
                        node_def.on_punch(
                            pointed_thing.under,
                            { name = node.name, param1 = node.param1, param2 = node.param2 },
                            shooter,
                            pointed_thing
                        )
                    end

                    -- Node impact shrapnel particles (Newton's 3rd law recoil opposite to hit surface)
                    local normal = (pointed_thing.above and pointed_thing.under and not vector.equals(pointed_thing.above, pointed_thing.under))
                        and vector.subtract(pointed_thing.above, pointed_thing.under)
                        or vector.new(0, 1, 0)
                    if normal.x == 0 and normal.y == 0 and normal.z == 0 then
                        normal = vector.new(0, 1, 0)
                    end

                    local spawn_pos = vector.add(ip_pos, vector.multiply(normal, 0.05))
                    local min_vel, max_vel = get_shrapnel_velocity(normal)

                    if core.has_feature and core.has_feature({ dynamic_add_media_table = true, particlespawner_tweenable = true }) then
                        -- Modern syntax (v5.6.0+)
                        core.add_particlespawner({
                            amount = 10,
                            time = 0.1,
                            pos = spawn_pos,
                            radius = { min = 0.05, max = 0.25 },
                            vel = {
                                min = min_vel,
                                max = max_vel,
                            },
                            acc = vector.new(0, -9.81, 0),
                            drag = vector.new(0.3, 0.05, 0.3),
                            bounce = { min = 0.2, max = 0.4 },
                            exptime = { min = 0.5, max = 1.0 },
                            size = { min = 0.7, max = 1.5 },
                            node = { name = node_def.name },
                            collisiondetection = true,
                            collision_removal = false,
                            object_collision = false,
                        })
                    else
                        -- Graceful fallback for older engines (< v5.6)
                        core.add_particlespawner({
                            amount = 10,
                            time = 0.1,
                            minpos = vector.subtract(spawn_pos, 0.15),
                            maxpos = vector.add(spawn_pos, 0.15),
                            minvel = min_vel,
                            maxvel = max_vel,
                            minacc = vector.new(0, -9.81, 0),
                            maxacc = vector.new(0, -9.81, 0),
                            minexptime = 0.5,
                            maxexptime = 1.0,
                            minsize = 0.7,
                            maxsize = 1.5,
                            node = { name = node_def.name },
                            collisiondetection = true,
                            collision_removal = false,
                            object_collision = false,
                        })
                    end

                    core.sound_play({
                        name = selfObj._sound_hit,
                        gain = 0.6,
                    }, {
                        pos = pointed_thing.under,
                        pitch = math.random(7, 13) / 10,
                        max_hear_distance = 16
                    }, true)

                    hit = true
                    break
                end
            end
        end
    end

    -- Exit water transition (e.g. shot through thin waterfall/fountain into open air)
    if selfObj._in_liquid and not in_liquid and not hit then
        selfObj._in_liquid = false
        selfObj._is_drowning = false
        if selfObj._bubble_spawner_id then
            core.delete_particlespawner(selfObj._bubble_spawner_id)
            selfObj._bubble_spawner_id = nil
        end
        selfObj.object:set_acceleration({ x = selfObj._acc_x, y = selfObj._acc_y, z = selfObj._acc_z })
    end

    if not hit then
        selfObj._old_pos = pos
    end
end

---Function receive a "luaentity" table as `self`. Called when somebody punches the object.
---Note that you probably want to handle most punches using the automatic armor group system.
---Can return `true` to prevent the default damage mechanism.
---@param self XBows
---@param selfObj EnityCustomAttrDef
---@param puncher ObjectRef|nil
---@param time_from_last_punch number|integer|nil
---@param tool_capabilities ToolCapabilitiesDef
---@param dir Vector
---@param damage number|integer
---@return boolean
function XBowsEntityDef.on_punch(self, selfObj, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    local pos = selfObj.object:get_pos()

    if pos then
        core.sound_play('default_dig_choppy', {
            pos = pos,
            gain = 0.4
        })
    end

    return false
end

---Register new projectile entity
---@param self XBows
---@param name string
---@param def XBowsEntityDef
function XBows.register_entity(self, name, def)
    def._custom = def._custom or {}
    def._custom.animations = def._custom.animations or {}

    local mod_name = def._custom.mod_name or 'x_bows'
    def._custom.name = mod_name .. ':' .. name
    def.initial_properties = mergeTables({
        ---defaults
        visual = 'wielditem',
        collisionbox = { 0, 0, 0, 0, 0, 0 },
        selectionbox = { 0, 0, 0, 0, 0, 0 },
        physical = false,
        textures = { 'air' },
        hp_max = 1,
        visual_size = { x = 1, y = 1, z = 1 },
        glow = 1,
        static_save = false
    }, def.initial_properties or {})

    def.on_death = function(selfObj, killer)
        return XBowsEntityDef:on_death(selfObj, killer)
    end

    if def._custom.on_death then
        def.on_death = def._custom.on_death
    end

    def.on_activate = function(selfObj, killer)
        return XBowsEntityDef:on_activate(selfObj, killer)
    end

    def.on_deactivate = function(selfObj, removal)
        return XBowsEntityDef:on_deactivate(selfObj, removal)
    end

    if def._custom.on_deactivate then
        def.on_deactivate = def._custom.on_deactivate
    end

    def.on_step = function(selfObj, dtime)
        return XBowsEntityDef:on_step(selfObj, dtime)
    end

    def.on_punch = function(selfObj, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        return XBowsEntityDef:on_punch(selfObj, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    end

    if def._custom.on_punch then
        def.on_punch = def._custom.on_punch
    end

    self.registered_entities[def._custom.name] = def

    core.register_entity(def._custom.name, {
        initial_properties = def.initial_properties,
        on_death = def.on_death,
        on_activate = def.on_activate,
        on_deactivate = def.on_deactivate,
        on_step = def.on_step,
        on_punch = def.on_punch
    })
end

----
--- QUIVER API
----

core.register_entity('x_bows:quiver_entity', {
    initial_properties = {
        visual = 'mesh',
        mesh = 'x_bows_quiver.obj',
        textures = { 'x_bows_quiver_mesh.png' },
        visual_size = { x = 1, y = 1, z = 1 },
        collisionbox = { 0, 0, 0, 0, 0, 0 },
        selectionbox = { 0, 0, 0, 0, 0, 0 },
        pointable = false,
        physical = false,
        static_save = false,
        glow = 0,
        backface_culling = true,
        shaded = true,
    },
    on_activate = function(self)
        self.object:set_armor_groups({ immortal = 1 })
    end,
    on_punch = function()
        return true
    end,
})

---Get attachment position and rotation for a quiver entity based on model format
---@param self XBowsQuiver
---@param format? string Model format ('glb' or 'b3d')
---@return Vector pos Attachment offset vector
---@return Vector rot Attachment rotation vector in degrees
function XBowsQuiver.get_attachment_transform(self, format)
    local fmt = format or (XBows.x_player_api and x_player_api.get_model_format()) or 'b3d'
    if fmt == 'b3d' then
        -- In B3D player models (character.b3d, 3d_armor_character.b3d), the 'Body' bone
        -- has a 180° rotation around Y (quaternion (0, 0, 1, 0)) relative to glTF/GLB models.
        -- We rotate by 180° around Y to cancel the bone's rotation and place the quiver squarely on the back.
        return { x = 0, y = 0, z = 0 }, { x = 0, y = 180, z = 0 }
    end
    -- In glTF/GLB models (character.glb, 3d_armor_character.glb), the 'Body' bone rest
    -- transform has identity rotation (0, 0, 0), so canonical relative offset (0, 0, 0) applies.
    return { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }
end

---Attach a quiver entity to a player
---@param self XBowsQuiver
---@param entity ObjectRef
---@param player ObjectRef
function XBowsQuiver.attach_quiver_entity(self, entity, player)
    if not entity or not entity:is_valid() or not player or not player:is_valid() or not player:is_player() then
        return
    end

    local pos_glb, rot_glb = self:get_attachment_transform('glb')
    local pos_b3d, rot_b3d = self:get_attachment_transform('b3d')

    if XBows.x_player_api and not x_player_api.is_pure_native_b3d_active(player) then
        local proxies = x_player_api.get_visual_proxies(player)
        if proxies then
            if x_player_api.get_model_format() ~= 'b3d' and proxies.glb and proxies.glb:is_valid() then
                entity:set_attach(proxies.glb, 'Body', pos_glb, rot_glb, false)
                entity:set_observers(x_player_api.get_modern_observers())
                return
            elseif proxies.b3d and proxies.b3d:is_valid() then
                entity:set_attach(proxies.b3d, 'Body', pos_b3d, rot_b3d, false)
                entity:set_observers(x_player_api.get_legacy_observers())
                return
            end
        end
    end

    local pos, rot = self:get_attachment_transform()
    entity:set_attach(player, 'Body', pos, rot, false)
end

---Ensures a quiver stack has a unique quiver_id, generating one if missing.
---@param self XBowsQuiver
---@param stack ItemStack
---@return string The quiver_id
function XBowsQuiver.get_or_init_quiver_id(self, stack)
    if not stack or stack:is_empty() then
        return ''
    end

    local meta = stack:get_meta()
    local qid = meta:get_string('quiver_id')

    if qid == '' then
        qid = stack:get_name() .. '_' .. XBows.uuid()
        meta:set_string('quiver_id', qid)
    end

    return qid
end

---Initializes a quiver in an inventory slot, ensuring it has an ID, creating its detached inventory and setting visual state.
---@param self XBowsQuiver
---@param player ObjectRef
---@param inventory InvRef
---@param listname string
---@param index? number
function XBowsQuiver.init_quiver_in_slot(self, player, inventory, listname, index)
    index = index or 1
    local stack = inventory:get_stack(listname, index)
    if not stack or stack:is_empty() then
        return
    end

    if stack:get_name() == 'x_bows:quiver_open' then
        stack = self:get_replacement_item(stack, 'x_bows:quiver')
    end

    local quiver_id = self:get_or_init_quiver_id(stack)
    inventory:set_stack(listname, index, stack)

    local st_meta = stack:get_meta()
    local detached_inv = self:get_or_create_detached_inv(
        quiver_id,
        player:get_player_name(),
        st_meta:get_string('quiver_items')
    )

    if detached_inv then
        if detached_inv:is_empty('main') then
            XBowsQuiver.quiver_empty_state[player:get_player_name()] = false
            self:show_3d_quiver(player, { is_empty = true })
        else
            XBowsQuiver.quiver_empty_state[player:get_player_name()] = true
            self:show_3d_quiver(player)
        end
    end
end

---Close one or all open quivers in players inventory
---@param self XBowsQuiver
---@param player ObjectRef
---@param quiver_id? string If `nil` then all open quivers will be closed
---@return nil
function XBowsQuiver.close_quiver(self, player, quiver_id)
    local player_inv = player:get_inventory()
    if not player_inv then
        return
    end

    -- Normalize x_bows:quiver_inv if it holds an open quiver
    local q_st = player_inv:get_stack('x_bows:quiver_inv', 1)
    if not q_st:is_empty() and q_st:get_name() == 'x_bows:quiver_open' then
        if not quiver_id or q_st:get_meta():get_string('quiver_id') == quiver_id then
            local replace_item = self:get_replacement_item(q_st, 'x_bows:quiver')
            player_inv:set_stack('x_bows:quiver_inv', 1, replace_item)
        end
    end

    ---find matching quiver item in players main inventory
    if player_inv:contains_item('main', 'x_bows:quiver_open') then
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            local st_meta = st:get_meta()

            if not st:is_empty() and st:get_name() == 'x_bows:quiver_open' then
                if not quiver_id or st_meta:get_string('quiver_id') == quiver_id then
                    local replace_item = self:get_replacement_item(st, 'x_bows:quiver')
                    player_inv:set_stack('main', i, replace_item)
                    if quiver_id then
                        break
                    end
                end
            end
        end
    end
end

---Swap item in player inventory indicating open quiver. Preserve all ItemStack definition and meta.
---@param self XBowsQuiver
---@param from_stack ItemStack transfer data from this item
---@param to_item_name string transfer data to this item
---@return ItemStack ItemStack replacement item
function XBowsQuiver.get_replacement_item(self, from_stack, to_item_name)
    local replace_item = ItemStack(from_stack)
    replace_item:set_name(to_item_name)
    return replace_item
end

---Gets arrow from quiver
---@param self XBowsQuiver
---@param player ObjectRef
---@diagnostic disable-next-line: codestyle-check
---@return {["found_arrow_stack"]: ItemStack|nil, ["quiver_id"]: string|nil, ["quiver_name"]: string|nil, ["found_arrow_stack_idx"]: number}
function XBowsQuiver.get_itemstack_arrow_from_quiver(self, player)
    local player_inv = player:get_inventory()
    local wielded_stack = player:get_wielded_item()
    ---@type ItemStack|nil
    local found_arrow_stack = nil
    local found_arrow_stack_idx = 1
    local prev_detached_inv_list = {}
    local quiver_id = nil
    local quiver_name = nil

    ---check quiver inventory slot
    if player_inv and player_inv:contains_item('x_bows:quiver_inv', 'x_bows:quiver') then
        local player_name = player:get_player_name()
        local quiver_stack = player_inv:get_stack('x_bows:quiver_inv', 1)
        quiver_id = self:get_or_init_quiver_id(quiver_stack)
        player_inv:set_stack('x_bows:quiver_inv', 1, quiver_stack)

        local st_meta = quiver_stack:get_meta()
        local detached_inv = self:get_or_create_detached_inv(
            quiver_id,
            player_name,
            st_meta:get_string('quiver_items')
        )

        if detached_inv and not detached_inv:is_empty('main') then
            local detached_inv_list = detached_inv:get_list('main')
            prev_detached_inv_list = detached_inv_list

            ---find arrows inside quiver inventory
            for j, qst in ipairs(detached_inv_list) do
                if not qst:is_empty() and not found_arrow_stack then
                    local is_allowed_ammunition = self:is_allowed_ammunition(wielded_stack:get_name(), qst:get_name())

                    if is_allowed_ammunition then
                        quiver_name = quiver_stack:get_name()
                        found_arrow_stack = ItemStack({ name = qst:get_name(), count = 1 })
                        found_arrow_stack_idx = j
                        break
                    end
                end
            end
        end

        if found_arrow_stack then
            ---show HUD - quiver inventory
            self:udate_or_create_hud(player, prev_detached_inv_list, found_arrow_stack_idx)
        end
    end

    if not found_arrow_stack and self.fallback_quiver then
        ---find matching quiver item in players inventory
        if player_inv and player_inv:contains_item('main', 'x_bows:quiver') then
            local inv_list = player_inv:get_list('main')

            for i, st in ipairs(inv_list) do
                if not st:is_empty() and st:get_name() == 'x_bows:quiver' then
                    local player_name = player:get_player_name()
                    quiver_id = self:get_or_init_quiver_id(st)
                    player_inv:set_stack('main', i, st)

                    local st_meta = st:get_meta()
                    local detached_inv = self:get_or_create_detached_inv(
                        quiver_id,
                        player_name,
                        st_meta:get_string('quiver_items')
                    )

                    if detached_inv and not detached_inv:is_empty('main') then
                        local detached_inv_list = detached_inv:get_list('main')
                        prev_detached_inv_list = detached_inv_list

                        ---find arrows inside quiver inventory
                        for j, qst in ipairs(detached_inv_list) do
                            if not qst:is_empty() and not found_arrow_stack then
                                local is_allowed_ammunition = self:is_allowed_ammunition(
                                    wielded_stack:get_name(),
                                    qst:get_name()
                                )

                                if is_allowed_ammunition then
                                    quiver_name = st:get_name()
                                    found_arrow_stack = ItemStack({ name = qst:get_name(), count = 1 })
                                    found_arrow_stack_idx = j
                                    break
                                end
                            end
                        end
                    end
                end

                if found_arrow_stack then
                    ---show HUD - quiver inventory
                    self:udate_or_create_hud(player, prev_detached_inv_list, found_arrow_stack_idx)
                    break
                end
            end
        end
    end

    return {
        found_arrow_stack = found_arrow_stack,
        quiver_id = quiver_id,
        quiver_name = quiver_name,
        found_arrow_stack_idx = found_arrow_stack_idx
    }
end

---Remove all added HUDs
---@param self XBowsQuiver
---@param player ObjectRef
---@return nil
function XBowsQuiver.remove_hud(self, player)
    local player_name = player:get_player_name()

    if self.hud_item_ids[player_name] then
        for _, v in pairs(self.hud_item_ids[player_name]) do
            if type(v) == 'table' then
                for _, v2 in pairs(v) do
                    player:hud_remove(v2)
                end
            else
                player:hud_remove(v)
            end
        end

        self.hud_item_ids[player_name] = {
            arrow_inv_img = {},
            stack_count = {}
        }
    else
        self.hud_item_ids[player_name] = {
            arrow_inv_img = {},
            stack_count = {}
        }
    end
end

---@todo implement hud_change?
---Update or create quiver HUD
---@param self XBowsQuiver
---@param player ObjectRef
---@param inv_list ItemStack[]
---@param idx? number
---@return nil
function XBowsQuiver.udate_or_create_hud(self, player, inv_list, idx)
    local player_meta = player:get_meta()
    local x_bows_show_hud_overlay = player_meta:get_string('x_bows_show_hud_overlay')

    if x_bows_show_hud_overlay == 'false' then
        return
    end

    local _idx = idx or 1
    local player_name = player:get_player_name()
    local selected_bg_added = false
    local is_arrow = #inv_list == 1
    local item_def = core.registered_items['x_bows:quiver']
    local is_no_ammo = false

    if is_arrow then
        item_def = core.registered_items[inv_list[1]:get_name()]
        is_no_ammo = inv_list[1]:get_name() == 'x_bows:no_ammo'
    end

    if is_no_ammo then
        item_def = {
            inventory_image = 'x_bows_arrow_slot.png',
            short_description = S('No Ammo') .. '!'
        }
    end

    if not item_def then
        return
    end

    ---cancel previous timeouts and reset
    if self.after_job[player_name] then
        for _, v in pairs(self.after_job[player_name]) do
            v:cancel()
        end

        self.after_job[player_name] = {}
    else
        self.after_job[player_name] = {}
    end

    self:remove_hud(player)

    ---title image
    self.hud_item_ids[player_name].title_image = player:hud_add({
        type = 'image',
        position = { x = 1, y = 0.5 },
        offset = { x = -120, y = -140 },
        text = item_def.inventory_image,
        scale = { x = 4, y = 4 },
        alignment = 0,
    })

    ---title copy
    self.hud_item_ids[player_name].title_copy = player:hud_add({
        type = 'text',
        position = { x = 1, y = 0.5 },
        offset = { x = -120, y = -75 },
        text = item_def.short_description,
        alignment = 0,
        scale = { x = 100, y = 30 },
        number = 0xFFFFFF,
    })

    ---hotbar bg
    self.hud_item_ids[player_name].hotbar_bg = player:hud_add({
        type = 'image',
        position = { x = 1, y = 0.5 },
        offset = { x = -238, y = 0 },
        text = is_arrow and 'x_bows_single_hotbar.png' or 'x_bows_quiver_hotbar.png',
        scale = { x = 1, y = 1 },
        alignment = { x = 1, y = 0 },
    })

    for j, qst in ipairs(inv_list) do
        if not qst:is_empty() then
            local found_arrow_stack_def = core.registered_items[qst:get_name()]

            if is_no_ammo then
                found_arrow_stack_def = item_def
            end

            if not selected_bg_added and j == _idx then
                selected_bg_added = true

                ---ui selected bg
                self.hud_item_ids[player_name].hotbar_selected = player:hud_add({
                    type = 'image',
                    position = { x = 1, y = 0.5 },
                    offset = { x = -308 + (j * 74), y = 2 },
                    text = 'x_bows_hotbar_selected.png',
                    scale = { x = 1, y = 1 },
                    alignment = { x = 1, y = 0 },
                })
            end

            if found_arrow_stack_def then
                ---arrow inventory image
                table.insert(self.hud_item_ids[player_name].arrow_inv_img, player:hud_add({
                    type = 'image',
                    position = { x = 1, y = 0.5 },
                    offset = { x = -300 + (j * 74), y = 0 },
                    text = found_arrow_stack_def.inventory_image,
                    scale = { x = 4, y = 4 },
                    alignment = { x = 1, y = 0 },
                }))

                ---stack count
                table.insert(self.hud_item_ids[player_name].stack_count, player:hud_add({
                    type = 'text',
                    position = { x = 1, y = 0.5 },
                    offset = { x = -244 + (j * 74), y = 23 },
                    text = is_no_ammo and 0 or qst:get_count(),
                    alignment = -1,
                    scale = { x = 50, y = 10 },
                    number = 0xFFFFFF,
                }))
            end
        end
    end

    ---@param v_player_name string
    table.insert(self.after_job[player_name], core.after(10, function(v_player_name)
        local v_player = core.get_player_by_name(v_player_name)
        if v_player and v_player:is_valid() then
            self:remove_hud(v_player)
        end
    end, player_name))
end

---Alias for typo in method name
XBowsQuiver.update_or_create_hud = XBowsQuiver.udate_or_create_hud

---Alias for backwards compatibility and cross-object safety
XBows.get_or_create_detached_inv = function(self, ...)
    return XBowsQuiver:get_or_create_detached_inv(...)
end

---Get existing detached inventory or create new one
---@param self XBowsQuiver
---@param quiver_id string
---@param player_name string
---@param quiver_items? string
---@return InvRef|nil
function XBowsQuiver.get_or_create_detached_inv(self, quiver_id, player_name, quiver_items)
    if not quiver_id or quiver_id == '' then
        return nil
    end

    local detached_inv = core.get_inventory({ type = 'detached', name = quiver_id })

    if not detached_inv then
        detached_inv = core.create_detached_inventory(quiver_id, {
            ---@param inv InvRef detached inventory
            ---@param from_list string
            ---@param from_index number
            ---@param to_list string
            ---@param to_index number
            ---@param count number
            ---@param player ObjectRef
            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                if self:quiver_can_allow(inv, player) then
                    return count
                else
                    return 0
                end
            end,
            ---@param inv InvRef detached inventory
            ---@param listname string listname of the inventory, e.g. `'main'`
            ---@param index number
            ---@param stack ItemStack
            ---@param player ObjectRef
            allow_put = function(inv, listname, index, stack, player)
                if core.get_item_group(stack:get_name(), 'arrow') ~= 0 and self:quiver_can_allow(inv, player) then
                    return stack:get_count()
                else
                    return 0
                end
            end,
            ---@param inv InvRef detached inventory
            ---@param listname string listname of the inventory, e.g. `'main'`
            ---@param index number
            ---@param stack ItemStack
            ---@param player ObjectRef
            allow_take = function(inv, listname, index, stack, player)
                if self:quiver_can_allow(inv, player) then
                    return stack:get_count()
                else
                    return 0
                end
            end,
            ---@param inv InvRef detached inventory
            ---@param from_list string
            ---@param from_index number
            ---@param to_list string
            ---@param to_index number
            ---@param count number
            ---@param player ObjectRef
            on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                self:save(inv, player)
            end,
            ---@param inv InvRef detached inventory
            ---@param listname string listname of the inventory, e.g. `'main'`
            ---@param index number index where was item put
            ---@param stack ItemStack stack of item what was put
            ---@param player ObjectRef
            on_put = function(inv, listname, index, stack, player)
                local quiver_inv_st = player:get_inventory():get_stack('x_bows:quiver_inv', 1)

                if quiver_inv_st and quiver_inv_st:get_meta():get_string('quiver_id') == inv:get_location().name then
                    if inv:is_empty('main') then
                        self:show_3d_quiver(player, { is_empty = true })
                    else
                        self:show_3d_quiver(player)
                    end
                end

                self:save(inv, player)
            end,
            ---@param inv InvRef detached inventory
            ---@param listname string listname of the inventory, e.g. `'main'`
            ---@param index number
            ---@param stack ItemStack
            ---@param player ObjectRef
            on_take = function(inv, listname, index, stack, player)
                local quiver_inv_st = player:get_inventory():get_stack('x_bows:quiver_inv', 1)

                if quiver_inv_st and quiver_inv_st:get_meta():get_string('quiver_id') == inv:get_location().name then
                    if inv:is_empty('main') then
                        self:show_3d_quiver(player, { is_empty = true })
                    else
                        self:show_3d_quiver(player)
                    end
                end

                self:save(inv, player)
            end,
        }, player_name)

        detached_inv:set_size('main', 3 * 1)

        ---populate items in inventory only upon creation
        if quiver_items and quiver_items ~= '' then
            self:set_string_to_inv(detached_inv, quiver_items)
        end
    end

    return detached_inv
end

---Get formspec for quiver
---@param self XBowsQuiver
---@param name string
---@return string Formspec
function XBowsQuiver.get_formspec(self, name)
    -- Fetch inventory to check which slots currently have arrows
    local inv = core.get_inventory({ type = 'detached', name = name })
    local invlist = inv and inv:get_list('main')

    local formspec = {
        'formspec_version[6]',
        'size[10.75,7.4]',
        'box[0,0;10.75,7.4;#101010]',
        'spacing[0.25,0.25]',

        -- Sleek dark mode theme for inventory slots and hover states
        'listcolors[#1a1a1a;#2c2c2c;#333333;#0d0d0d;#ffffff]',

        -- Quiver container (3 slots, centered horizontally)
        'container[3.625,0.5]',
    }

    --- Placeholder arrow icons for empty quiver slots (relative to container, placed before list)
    for i = 1, 3 do
        if not invlist or not invlist[i] or invlist[i]:is_empty() then
            local px = (i - 1) * 1.25
            formspec[#formspec + 1] = 'image[' .. px .. ',0;1,1;x_bows_arrow_slot.png]'
        end
    end

    --- Quiver detached inventory (3 slots)
    formspec[#formspec + 1] = 'list[detached:' .. name .. ';main;0,0;3,1;]'
    formspec[#formspec + 1] = 'container_end[]'

    -- Full player inventory container (8 columns x 4 rows)
    formspec[#formspec + 1] = 'container[0.5,1.9]'

    --- Main storage inventory (24 slots: rows 2-4, slots 9 to 32)
    formspec[#formspec + 1] = 'list[current_player;main;0,0;8,3;8]'

    --- Sleek accent divider line between main storage and hotbar
    formspec[#formspec + 1] = 'box[0,3.65;9.75,0.02;#282828]'

    --- Active Hotbar (8 slots: row 1, slots 1 to 8)
    formspec[#formspec + 1] = 'list[current_player;main;0,3.85;8,1;0]'
    formspec[#formspec + 1] = 'container_end[]'

    -- Shift-click rings between quiver and player inventory
    formspec[#formspec + 1] = 'listring[detached:' .. name .. ';main]'
    formspec[#formspec + 1] = 'listring[current_player;main]'

    return table.concat(formspec, '')
end

---Convert inventory of itemstacks to serialized string
---@param self XBowsQuiver
---@param inv InvRef
---@return {['inv_string']: string, ['content_description']: string}
function XBowsQuiver.get_string_from_inv(self, inv)
    local inv_list = inv:get_list('main')
    local t = {}
    local content_description = ''

    for i, st in ipairs(inv_list) do
        if not st:is_empty() then
            table.insert(t, st:to_table())
            content_description = content_description .. '\n' .. st:get_short_description() .. ' ' .. st:get_count()
        else
            table.insert(t, { is_empty = true })
        end
    end

    return {
        inv_string = core.serialize(t),
        content_description = content_description == '' and '\n' .. S('Empty') or content_description
    }
end

---Set items from serialized string to inventory
---@param self XBowsQuiver
---@param inv InvRef inventory to add items to
---@param str string previously stringified inventory of itemstacks
---@return nil
function XBowsQuiver.set_string_to_inv(self, inv, str)
    local t = (str and str ~= '') and core.deserialize(str) or nil
    local size = inv:get_size('main')

    for i = 1, size do
        local item = t and t[i]
        if item and not item.is_empty then
            inv:set_stack('main', i, ItemStack(item))
        else
            inv:set_stack('main', i, ItemStack(nil))
        end
    end
end

---Save quiver inventory to itemstack meta
---@param self XBowsQuiver
---@param inv InvRef
---@param player ObjectRef
---@param quiver_is_closed? boolean
---@return boolean True if quiver was found in player inventory and saved
function XBowsQuiver.save(self, inv, player, quiver_is_closed)
    local player_inv = player:get_inventory() --[[@as InvRef]]
    if not player_inv then
        return false
    end

    local inv_loc = inv:get_location()
    local player_quiver_inv_stack = player_inv:get_stack('x_bows:quiver_inv', 1)

    if not player_quiver_inv_stack:is_empty()
        and player_quiver_inv_stack:get_meta():get_string('quiver_id') == inv_loc.name
    then
        local st_meta = player_quiver_inv_stack:get_meta()
        ---save inventory items in quiver item meta
        local string_from_inventory_result = self:get_string_from_inv(inv)

        st_meta:set_string('quiver_items', string_from_inventory_result.inv_string)

        ---update description while preserving base stats (faster arrows, bonus damage)
        local qdef = self.registered_quivers[player_quiver_inv_stack:get_name()]
        local base_desc = (qdef and qdef.short_description) or player_quiver_inv_stack:get_short_description()
        local new_description = base_desc .. '\n' .. string_from_inventory_result.content_description .. '\n'

        st_meta:set_string('description', new_description)
        player_inv:set_stack('x_bows:quiver_inv', 1, player_quiver_inv_stack)
        return true
    elseif player_inv then
        ---find matching quiver item in players inventory
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            local st_name = st:get_name()
            local st_meta = st:get_meta()

            if not st:is_empty()
                and (st_name == 'x_bows:quiver' or st_name == 'x_bows:quiver_open')
                and st_meta:get_string('quiver_id') == inv_loc.name
            then
                ---save inventory items in quiver item meta
                local string_from_inventory_result = self:get_string_from_inv(inv)

                st_meta:set_string('quiver_items', string_from_inventory_result.inv_string)

                ---update description while preserving base stats (faster arrows, bonus damage)
                local qdef = self.registered_quivers[st_name]
                local base_desc = (qdef and qdef.short_description) or st:get_short_description()
                local new_description = base_desc .. '\n' .. string_from_inventory_result.content_description .. '\n'

                st_meta:set_string('description', new_description)
                player_inv:set_stack('main', i, st)

                return true
            end
        end
    end

    return false
end

---Check if we are allowing actions in the correct quiver inventory
---@param self XBowsQuiver
---@param inv InvRef
---@param player ObjectRef
---@return boolean
function XBowsQuiver.quiver_can_allow(self, inv, player)
    local player_inv = player:get_inventory() --[[@as InvRef]]
    local inv_loc = inv:get_location()
    local player_quiver_inv_stack = player_inv:get_stack('x_bows:quiver_inv', 1)

    if not player_quiver_inv_stack:is_empty()
        and player_quiver_inv_stack:get_meta():get_string('quiver_id') == inv_loc.name
    then
        ---find quiver in player `quiver_inv` inv list
        return true
    elseif player_inv then
        ---find quiver in player `main` inv list
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            local st_name = st:get_name()
            local st_meta = st:get_meta()

            if not st:is_empty()
                and (st_name == 'x_bows:quiver' or st_name == 'x_bows:quiver_open')
                and st_meta:get_string('quiver_id') == inv_loc.name
            then
                return true
            end
        end
    end

    return false
end

---Open quiver
---@param self XBows
---@param itemstack ItemStack
---@param user ObjectRef
---@return ItemStack
function XBows.open_quiver(self, itemstack, user)
    local pname = user:get_player_name()
    local quiver_id = XBowsQuiver:get_or_init_quiver_id(itemstack)
    local itemstack_meta = itemstack:get_meta()
    local quiver_items = itemstack_meta:get_string('quiver_items')

    XBowsQuiver:get_or_create_detached_inv(quiver_id, pname, quiver_items)

    ---show open variation of quiver
    local replace_item = XBowsQuiver:get_replacement_item(itemstack, 'x_bows:quiver_open')

    itemstack:replace(replace_item)

    core.sound_play('x_bows_quiver', {
        to_player = user:get_player_name(),
        gain = 0.1
    })

    core.show_formspec(pname, quiver_id, XBowsQuiver:get_formspec(quiver_id))
    return itemstack
end

---Register sfinv page
---@param self XBowsQuiver
function XBowsQuiver.sfinv_register_page(self)
    sfinv.register_page('x_bows:quiver_page', {
        title = 'X Bows',
        get = function(this, player, context)
            local formspec = {
                ---arrow
                'label[0,0;' .. core.formspec_escape(S('Arrows')) .. ':]',
                'image[0,0.5;1,1;x_bows_arrow_slot.png]',
                'list[current_player;x_bows:arrow_inv;0,0.5;1,1;]',
                ---quiver
                'label[3.5,0;' .. core.formspec_escape(S('Quiver')) .. ':]',
                'image[3.5,0.5;1,1;x_bows_quiver_slot.png]',
                'list[current_player;x_bows:quiver_inv;3.5,0.5;1,1;]',
                ---settings button
                'image_button[7,3.5;1,1;x_bows_settings_btn.png;x_bows_settings_btn;]',
                'tooltip[x_bows_settings_btn;' .. core.formspec_escape(S('X Bows Settings')) .. ']'
            }

            local player_inv = player:get_inventory() --[[@as InvRef]]
            context._itemstack_arrow = player_inv:get_stack('x_bows:arrow_inv', 1)
            context._itemstack_quiver = player_inv:get_stack('x_bows:quiver_inv', 1)

            if context._itemstack_arrow and not context._itemstack_arrow:is_empty() then
                local x_bows_registered_arrow_def = self.registered_arrows[context._itemstack_arrow:get_name()]
                local short_description = context._itemstack_arrow:get_short_description()

                if x_bows_registered_arrow_def and short_description then
                    formspec[#formspec + 1] = 'label[0,1.5;' ..
                        core.formspec_escape(short_description) .. '\n' ..
                        core.formspec_escape(x_bows_registered_arrow_def.custom.description_abilities) .. ']'
                end
            end

            if context._itemstack_quiver and not context._itemstack_quiver:is_empty() then
                local quiver_id = self:get_or_init_quiver_id(context._itemstack_quiver)
                player_inv:set_stack('x_bows:quiver_inv', 1, context._itemstack_quiver)

                local st_meta = context._itemstack_quiver:get_meta()
                self:get_or_create_detached_inv(quiver_id, player:get_player_name(), st_meta:get_string('quiver_items'))

                local short_description = context._itemstack_quiver:get_short_description()

                ---description
                if short_description then
                    formspec[#formspec + 1] = 'label[3.5,1.5;' ..
                        core.formspec_escape(short_description) .. ']'
                end

                formspec[#formspec + 1] = 'list[detached:' .. quiver_id .. ';main;4.5,0.5;3,1;]'
                formspec[#formspec + 1] = 'listring[detached:' .. quiver_id .. ';main]'
                formspec[#formspec + 1] = 'listring[current_player;main]'
            else
                formspec[#formspec + 1] = 'listring[current_player;x_bows:quiver_inv]'
                formspec[#formspec + 1] = 'listring[current_player;main]'
            end

            return sfinv.make_formspec(player, context, table.concat(formspec, ''), true)
        end
    })
end

function XBowsQuiver.show_settings_page(self, player)
    local player_meta = player:get_meta()
    local x_bows_show_damage_numbers_player = player_meta:get_string('x_bows_show_damage_numbers')
    local x_bows_show_damage_numbers_settings = XBows.settings.x_bows_show_damage_numbers
    local x_bows_show_damage_numbers_priv = core.check_player_privs(player, 'x_bows_show_damage_numbers')
    local x_bows_show_hud_overlay = player_meta:get_string('x_bows_show_hud_overlay')
    x_bows_show_damage_numbers_player = x_bows_show_damage_numbers_player == 'true' and 'true' or 'false'
    x_bows_show_hud_overlay = x_bows_show_hud_overlay == 'true' and 'true' or 'false'
    local line_height_default = 0.5
    local line_height = line_height_default

    local formspec = {
        'size[11,5.5,false]',
        'label[0.5,0.5;', S('X Bows Settings'), ']',
        'button_exit[4.5,5;2,0.5;x_bows_settings_done_btn;', S('Done'), ']',
    }

    -- Show damage numbers
    line_height = line_height * 2
    formspec[#formspec + 1] = 'checkbox[0.5,' .. line_height .. ';x_bows_show_damage_numbers;' .. S('Show Damage Numbers') .. ';' .. x_bows_show_damage_numbers_player .. ']'
    formspec[#formspec + 1] = 'tooltip[x_bows_show_damage_numbers;' .. S('Shows the amount of damage done to the mob or player with the arrow.') .. ']'

    if not x_bows_show_damage_numbers_settings and not x_bows_show_damage_numbers_priv then
        -- Server setting disabled but player setting enabled
        line_height = line_height + line_height_default
        formspec[#formspec + 1] = 'label[0.5, ' .. line_height .. ';' .. S('Disabled by server. This will have no effect without "x_bows_show_damage_numbers" privilege.') .. ']'
    end

    -- Display HUD
    line_height = line_height + line_height_default
    formspec[#formspec + 1] = 'checkbox[0.5,' .. line_height .. ';x_bows_show_hud_overlay;' .. S('Show HUD Overlay') .. ';' .. x_bows_show_hud_overlay .. ']'
    formspec[#formspec + 1] = 'tooltip[x_bows_show_hud_overlay;' .. S('Displays the HUD overlay on the right side of the screen, showing the current arrows, the selected arrow, and their total number.') .. ']'

    formspec = table.concat(formspec, '')

    core.show_formspec(player:get_player_name(), 'xbows_settings_page', formspec)
end

---Register i3 page
function XBowsQuiver.i3_register_page(self)
    i3.new_tab('x_bows_quiver_page', {
        description = 'X Bows',
        slots = true,
        formspec = function(player, data, fs)
            local formspec = {
                ---arrow
                'label[0.5,1;' .. core.formspec_escape(S('Arrows')) .. ':]',
                'list[current_player;x_bows:arrow_inv;0.5,1.5;1,1;]',
                ---quiver
                'label[5,1;' .. core.formspec_escape(S('Quiver')) .. ':]',
                'list[current_player;x_bows:quiver_inv;5,1.5;1,1;]',
                ---settings button
                'image_button[8.5,5.5;1,1;x_bows_settings_btn.png;x_bows_settings_btn;]',
                'tooltip[x_bows_settings_btn;' .. core.formspec_escape(S('X Bows Settings')) .. ']'
            }

            local context = {}
            local player_inv = player:get_inventory()
            context._itemstack_arrow = player_inv:get_stack('x_bows:arrow_inv', 1)
            context._itemstack_quiver = player_inv:get_stack('x_bows:quiver_inv', 1)

            if context._itemstack_arrow and not context._itemstack_arrow:is_empty() then
                local x_bows_registered_arrow_def = self.registered_arrows[context._itemstack_arrow:get_name()]

                if x_bows_registered_arrow_def then
                    formspec[#formspec + 1] = 'label[0.5,3;' ..
                        core.formspec_escape(context._itemstack_arrow:get_short_description()) .. '\n' ..
                        core.formspec_escape(x_bows_registered_arrow_def.custom.description_abilities) .. ']'
                end
            end

            if context._itemstack_quiver and not context._itemstack_quiver:is_empty() then
                local quiver_id = self:get_or_init_quiver_id(context._itemstack_quiver)
                player_inv:set_stack('x_bows:quiver_inv', 1, context._itemstack_quiver)

                local st_meta = context._itemstack_quiver:get_meta()
                self:get_or_create_detached_inv(quiver_id, player:get_player_name(), st_meta:get_string('quiver_items'))

                ---description
                formspec[#formspec + 1] = 'label[5,3;' ..
                    core.formspec_escape(context._itemstack_quiver:get_short_description()) .. ']'
                formspec[#formspec + 1] = 'list[detached:' .. quiver_id .. ';main;6.3,1.5;3,1;]'
                formspec[#formspec + 1] = 'listring[detached:' .. quiver_id .. ';main]'
                formspec[#formspec + 1] = 'listring[current_player;main]'
            else
                formspec[#formspec + 1] = 'listring[current_player;x_bows:quiver_inv]'
                formspec[#formspec + 1] = 'listring[current_player;main]'
            end

            formspec = table.concat(formspec, '')

            fs(formspec)
        end
    })
end

---Register i3 page
function XBowsQuiver.ui_register_page(self)
    unified_inventory.register_page('x_bows:quiver_page', {
        get_formspec = function(player, data, fs)
            local formspec = {
                unified_inventory.style_full.standard_inv_bg,
                'listcolors[#00000000;#00000000]',
                ---arrow
                'label[0.5,0.5;' .. core.formspec_escape(S('Arrows')) .. ':]',
                unified_inventory.single_slot(0.4, 0.9),
                'list[current_player;x_bows:arrow_inv;0.5,1;1,1;]',
                ---quiver
                'label[5,0.5;' .. core.formspec_escape(S('Quiver')) .. ':]',
                unified_inventory.single_slot(4.9, 0.9),
                'list[current_player;x_bows:quiver_inv;5,1;1,1;]',
                ---settings button
                'image_button[9,4.5;1,1;x_bows_settings_btn.png;x_bows_settings_btn;]',
                'tooltip[x_bows_settings_btn;' .. core.formspec_escape(S('X Bows Settings')) .. ']'
            }

            local context = {}
            context._itemstack_arrow = player:get_inventory():get_stack('x_bows:arrow_inv', 1)
            context._itemstack_quiver = player:get_inventory():get_stack('x_bows:quiver_inv', 1)

            if context._itemstack_arrow and not context._itemstack_arrow:is_empty() then
                local x_bows_registered_arrow_def = self.registered_arrows[context._itemstack_arrow:get_name()]

                if x_bows_registered_arrow_def then
                    formspec[#formspec + 1] = 'label[0.5,2.5;' ..
                        core.formspec_escape(context._itemstack_arrow:get_short_description()) .. '\n' ..
                        core.formspec_escape(x_bows_registered_arrow_def.custom.description_abilities) .. ']'
                end
            end


            if context._itemstack_quiver and not context._itemstack_quiver:is_empty() then
                local quiver_id = self:get_or_init_quiver_id(context._itemstack_quiver)
                local player_inv = player:get_inventory()
                player_inv:set_stack('x_bows:quiver_inv', 1, context._itemstack_quiver)

                local st_meta = context._itemstack_quiver:get_meta()
                self:get_or_create_detached_inv(quiver_id, player:get_player_name(), st_meta:get_string('quiver_items'))

                ---description
                formspec[#formspec + 1] = 'label[5,2.5;' ..
                    core.formspec_escape(context._itemstack_quiver:get_short_description()) .. ']'
                formspec[#formspec + 1] = unified_inventory.single_slot(6.4, 0.9)
                formspec[#formspec + 1] = unified_inventory.single_slot(7.65, 0.9)
                formspec[#formspec + 1] = unified_inventory.single_slot(8.9, 0.9)
                formspec[#formspec + 1] = 'list[detached:' .. quiver_id .. ';main;6.5,1;3,1;]'
                formspec[#formspec + 1] = 'listring[detached:' .. quiver_id .. ';main]'
                formspec[#formspec + 1] = 'listring[current_player;main]'
            else
                formspec[#formspec + 1] = 'listring[current_player;x_bows:quiver_inv]'
                formspec[#formspec + 1] = 'listring[current_player;main]'
            end

            return {
                formspec = table.concat(formspec, '')
            }
        end
    })

    unified_inventory.register_button('x_bows:quiver_page', {
        type = 'image',
        image = "x_bows_bow_wood_charged.png",
        tooltip = 'X Bows',
    })
end

---Show 3D quiver entity on the player's back
---@param self XBowsQuiver
---@param player ObjectRef
---@param props? { is_empty?: boolean }
function XBowsQuiver.show_3d_quiver(self, player, props)
    if not XBows.settings.x_bows_show_3d_quiver or not player or not player:is_player() then
        return
    end

    local _props = props or {}
    local p_name = player:get_player_name()
    local is_empty = _props.is_empty == true
    local quiver_texture = is_empty and 'x_bows_quiver_empty_mesh.png' or 'x_bows_quiver_mesh.png'

    local current = self.active_quivers[p_name]
    local has_valid = false

    if current then
        if type(current) == 'table' then
            for _, ent in pairs(current) do
                if ent and ent:is_valid() then
                    has_valid = true
                    if self.quiver_empty_state[p_name] ~= is_empty then
                        ent:set_properties({ textures = { quiver_texture } })
                    end
                end
            end
        elseif current and current:is_valid() then
            has_valid = true
            if self.quiver_empty_state[p_name] ~= is_empty then
                current:set_properties({ textures = { quiver_texture } })
            end
        end

        if has_valid then
            if type(current) == 'table' then
                local prx = XBows.x_player_api and not x_player_api.is_pure_native_b3d_active(player)
                    and x_player_api.get_visual_proxies(player)
                if current.glb and current.glb:is_valid() and prx and prx.glb and prx.glb:is_valid() then
                    local pos_glb, rot_glb = self:get_attachment_transform('glb')
                    current.glb:set_attach(prx.glb, 'Body', pos_glb, rot_glb, false)
                end
                if current.b3d and current.b3d:is_valid() and prx and prx.b3d and prx.b3d:is_valid() then
                    local pos_b3d, rot_b3d = self:get_attachment_transform('b3d')
                    current.b3d:set_attach(prx.b3d, 'Body', pos_b3d, rot_b3d, false)
                end
                if current.obj and current.obj:is_valid() then
                    local pos_fb, rot_fb = self:get_attachment_transform()
                    current.obj:set_attach(player, 'Body', pos_fb, rot_fb, false)
                end
            end
            self.quiver_empty_state[p_name] = is_empty
            return
        end
    end

    local pos = player:get_pos()
    if not pos then
        return
    end

    local proxies = XBows.x_player_api and not x_player_api.is_pure_native_b3d_active(player)
        and x_player_api.get_visual_proxies(player)

    local quivers = {}

    if proxies and (proxies.glb or proxies.b3d) then
        if proxies.glb and proxies.glb:is_valid() then
            local ent_glb = core.add_entity(pos, 'x_bows:quiver_entity')
            if ent_glb then
                local pos_glb, rot_glb = self:get_attachment_transform('glb')
                ent_glb:set_properties({ textures = { quiver_texture } })
                ent_glb:set_attach(proxies.glb, 'Body', pos_glb, rot_glb, false)
                ent_glb:set_observers(x_player_api.get_modern_observers())
                quivers.glb = ent_glb
            end
        end

        if proxies.b3d and proxies.b3d:is_valid() then
            local ent_b3d = core.add_entity(pos, 'x_bows:quiver_entity')
            if ent_b3d then
                local pos_b3d, rot_b3d = self:get_attachment_transform('b3d')
                ent_b3d:set_properties({ textures = { quiver_texture } })
                ent_b3d:set_attach(proxies.b3d, 'Body', pos_b3d, rot_b3d, false)
                ent_b3d:set_observers(x_player_api.get_legacy_observers())
                quivers.b3d = ent_b3d
            end
        end
    else
        local ent_obj = core.add_entity(pos, 'x_bows:quiver_entity')
        if ent_obj then
            local pos_fb, rot_fb = self:get_attachment_transform()
            ent_obj:set_properties({ textures = { quiver_texture } })
            ent_obj:set_attach(player, 'Body', pos_fb, rot_fb, false)
            quivers.obj = ent_obj
        end
    end

    self.active_quivers[p_name] = quivers
    self.quiver_empty_state[p_name] = is_empty
end

---Hide/remove 3D quiver entity from the player's back
---@param self XBowsQuiver
---@param player ObjectRef|string
function XBowsQuiver.hide_3d_quiver(self, player)
    if not player then
        return
    end

    local p_name = type(player) == 'string' and player or player:get_player_name()
    if not p_name or p_name == '' then
        return
    end

    if self.active_quivers and self.active_quivers[p_name] then
        local current = self.active_quivers[p_name]
        if type(current) == 'table' then
            for _, ent in pairs(current) do
                if ent and ent:is_valid() then
                    ent:remove()
                end
            end
        elseif current and current:is_valid() then
            current:remove()
        end
        self.active_quivers[p_name] = nil
    end

    if self.quiver_empty_state then
        self.quiver_empty_state[p_name] = nil
    end
end

---string split to characters
---@param str string
---@return string[] | nil
local function split(str)
    if #str > 0 then
        return str:sub(1, 1), split(str:sub(2))
    end
end

function XBows.show_damage_numbers(self, pos, damage, is_crit, player)
    if not player or not player:is_valid() or not player:is_player() then
        return
    end

    local player_meta = player:get_meta()

    local x_bows_show_damage_numbers_player = player_meta:get_string('x_bows_show_damage_numbers')
    local x_bows_show_damage_numbers_settings = self.settings.x_bows_show_damage_numbers
    local x_bows_show_damage_numbers_priv = core.check_player_privs(player, 'x_bows_show_damage_numbers')
    x_bows_show_damage_numbers_player = x_bows_show_damage_numbers_player == 'true' and 'true' or 'false'

    if not pos then
        return
    end

    if
        x_bows_show_damage_numbers_player == 'false'
        or (
            x_bows_show_damage_numbers_player == 'true'
            and not x_bows_show_damage_numbers_settings
            and not x_bows_show_damage_numbers_priv
        )
    then
        return
    end

    ---get damage texture
    local dmgstr = tostring(math.round(damage))
    local results = { split(dmgstr) }
    local texture = ''
    local dmg_nr_offset = 0

    for i, value in ipairs(results) do
        if i == 1 then
            texture = texture .. '[combine:' .. 7 * #results .. 'x9:0,0=x_bows_dmg_' .. value .. '.png'
        else
            texture = texture .. ':' .. dmg_nr_offset .. ',0=x_bows_dmg_' .. value .. '.png'
        end

        dmg_nr_offset = dmg_nr_offset + 7
    end

    if texture and texture ~= '' then
        local size = 7

        if is_crit then
            size = 14
            texture = texture .. '^[colorize:#FF0000:255'
        else
            texture = texture .. '^[colorize:#FFFF00:127'
        end

        -- Calculate flyout direction towards the shooter
        local spawn_pos = vector.new(pos.x, pos.y + 1.4, pos.z)
        local player_pos = player:get_pos()
        local to_player
        if player_pos then
            local eye_pos = vector.new(player_pos.x, player_pos.y + 1.5, player_pos.z)
            to_player = vector.direction(spawn_pos, eye_pos)
            if vector.length(to_player) < 0.001 then
                to_player = vector.new(0, 0, 1)
            end
        else
            to_player = vector.new(0, 0, 1)
        end

        local flyout_speed = 1.6
        local spread_x = (math.random() - 0.5) * 0.35
        local spread_z = (math.random() - 0.5) * 0.35

        local min_vel = vector.new(
            to_player.x * flyout_speed + spread_x - 0.1,
            3.4,
            to_player.z * flyout_speed + spread_z - 0.1
        )
        local max_vel = vector.new(
            to_player.x * flyout_speed + spread_x + 0.1,
            4.2,
            to_player.z * flyout_speed + spread_z + 0.1
        )

        if core.has_feature and core.has_feature({ dynamic_add_media_table = true, particlespawner_tweenable = true }) then
            -- Modern syntax (Luanti 5.6.0+)
            core.add_particlespawner({
                amount = 1,
                time = 0.01,
                playername = player:get_player_name(),
                pos = spawn_pos,
                vel = { min = min_vel, max = max_vel },
                acc = vector.new(0, -2.2, 0),
                drag = vector.new(0.4, 0.05, 0.4),
                exptime = { min = 1.8, max = 2.4 },
                size = { min = size, max = size },
                texture = {
                    name = texture,
                    alpha_tween = { 1.0, 0.0 }, -- Fades out smoothly as it floats
                    scale_tween = {
                        { x = is_crit and 1.35 or 1.15, y = is_crit and 1.35 or 1.15 },
                        { x = 0.9, y = 0.9 },
                    },
                    blend = 'alpha',
                },
                glow = 12,
                collisiondetection = true,
                bounce = { min = 0.1, max = 0.2 },
            })
        else
            -- Graceful fallback for older clients (< v5.6)
            core.add_particlespawner({
                amount = 1,
                time = 0.01,
                playername = player:get_player_name(),
                minpos = spawn_pos,
                maxpos = spawn_pos,
                minvel = min_vel,
                maxvel = max_vel,
                minacc = vector.new(0, -2.2, 0),
                maxacc = vector.new(0, -2.2, 0),
                minexptime = 1.8,
                maxexptime = 2.4,
                minsize = size,
                maxsize = size,
                texture = texture,
                glow = 10,
                collisiondetection = true,
            })
        end
    end
end

---Cleanup player resources on leave
---@param player ObjectRef
function XBows.on_leaveplayer(player)
    if not player then
        return
    end

    XBows:reset_charged_bow(player, true)
    XBowsQuiver:close_quiver(player)
    XBowsQuiver:hide_3d_quiver(player)

    local player_name = player:get_player_name()

    if XBows.charge_sound_after_job and XBows.charge_sound_after_job[player_name] then
        for _, v in pairs(XBows.charge_sound_after_job[player_name]) do
            if v and v.cancel then
                v:cancel()
            end
        end
        XBows.charge_sound_after_job[player_name] = nil
    end

    if XBowsQuiver.after_job and XBowsQuiver.after_job[player_name] then
        for _, v in pairs(XBowsQuiver.after_job[player_name]) do
            if v and v.cancel then
                v:cancel()
            end
        end
        XBowsQuiver.after_job[player_name] = nil
    end

    if XBowsQuiver.hud_item_ids and XBowsQuiver.hud_item_ids[player_name] then
        XBowsQuiver.hud_item_ids[player_name] = nil
    end

    if XBowsQuiver.quiver_empty_state and XBowsQuiver.quiver_empty_state[player_name] then
        XBowsQuiver.quiver_empty_state[player_name] = nil
    end

    if XBows.player_bow_sneak then
        XBows.player_bow_sneak[player_name] = nil
    end
end

---Cleanup player state on death
---@param player ObjectRef
---@param reason table
function XBows.on_dieplayer(player, reason)
    if not player or not player:is_valid() then
        return
    end

    XBowsQuiver:hide_3d_quiver(player)

    local player_name = player:get_player_name()

    -- Reset aiming physics, FOV zoom, and sneak state if aiming on death
    if XBows.player_bow_sneak and XBows.player_bow_sneak[player_name] and XBows.player_bow_sneak[player_name].sneak then
        if XBows.playerphysics then
            playerphysics.remove_physics_factor(player, 'speed', 'x_bows:bow_charged_speed')
        elseif XBows.player_monoids then
            player_monoids.speed:del_change(player, 'x_bows:bow_charged_speed')
        elseif XBows.pova then
            pova.del_override(player_name, 'x_bows:bow_charged_speed')
            pova.do_override(player)
        end
        XBows.player_bow_sneak[player_name].sneak = false
        player:set_fov(0, true, 0.4)
    end

    if XBowsQuiver.quiver_empty_state then
        XBowsQuiver.quiver_empty_state[player_name] = nil
    end

    XBows:reset_charged_bow(player, true)
    XBowsQuiver:close_quiver(player)
end

---Cleanup attached arrows on respawn
---@param player ObjectRef
function XBows.on_respawnplayer(player)
    if player and player:is_valid() then
        XBows.clear_attached_arrows(player)

        local quiver_stack = player:get_inventory():get_stack('x_bows:quiver_inv', 1)
        if quiver_stack and not quiver_stack:is_empty() then
            XBowsQuiver:init_quiver_in_slot(player, player:get_inventory(), 'x_bows:quiver_inv', 1)
        end
    end
end
