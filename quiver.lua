---Close one or all open quivers in players inventory
---@param player ObjectRef
---@param quiver_id? string If `nil` then all open quivers will be closed
---@returns nil
function x_bows.quiver.close_quiver(player, quiver_id)
    local player_inv = player:get_inventory()

    ---find matching quiver item in players inventory with the open formspec name
    if player_inv and player_inv:contains_item('main', 'x_bows:quiver_open') then
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            local st_meta = st:get_meta()

            if not st:is_empty() and st:get_name() == 'x_bows:quiver_open' then
                if quiver_id and st_meta:get_string('quiver_id') == quiver_id then
                    local replace_item = x_bows.quiver.get_replacement_item(st, 'x_bows:quiver')
                    player_inv:set_stack('main', i, replace_item)
                    break
                else
                    local replace_item = x_bows.quiver.get_replacement_item(st, 'x_bows:quiver')
                    player_inv:set_stack('main', i, replace_item)
                end
            end
        end
    end
end

---Swap item in player inventory indicating open quiver. Preserve all ItemStack definition and meta.
---@param from_stack ItemStack transfer data from this item
---@param to_item_name string transfer data to this item
---@return ItemStack ItemStack replacement item
function x_bows.quiver.get_replacement_item(from_stack, to_item_name)
    ---@type ItemStack
    local replace_item = ItemStack({
        name = to_item_name,
        count = from_stack:get_count(),
        wear = from_stack:get_wear()
    })
    local replace_item_meta = replace_item:get_meta()
    local from_stack_meta = from_stack:get_meta()

    replace_item_meta:set_string('quiver_items', from_stack_meta:get_string('quiver_items'))
    replace_item_meta:set_string('quiver_id', from_stack_meta:get_string('quiver_id'))
    replace_item_meta:set_string('description', from_stack_meta:get_string('description'))

    return replace_item
end

---Gets arrow from quiver
---@param player ObjectRef
---@return {["found_arrow_stack"]: ItemStack|nil, ["quiver_id"]: string|nil, ["quiver_name"]: string|nil}
function x_bows.quiver.get_itemstack_arrow_from_quiver(player)
    local player_inv = player:get_inventory()
    ---@type ItemStack|nil
    local found_arrow_stack
    local prev_detached_inv_list = {}
    local quiver_id
    local quiver_name

    ---find matching quiver item in players inventory with the open formspec name
    if player_inv and player_inv:contains_item('main', 'x_bows:quiver') then
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            if not st:is_empty() and st:get_name() == 'x_bows:quiver' then
                local st_meta = st:get_meta()
                local player_name = player:get_player_name()
                quiver_id = st_meta:get_string('quiver_id')

                local detached_inv = x_bows.quiver.get_or_create_detached_inv(
                    quiver_id,
                    player_name,
                    st_meta:get_string('quiver_items')
                )

                if not detached_inv:is_empty('main') then
                    local detached_inv_list = detached_inv:get_list('main')

                    ---find arrows inside quiver inventory
                    for j, qst in ipairs(detached_inv_list) do
                        ---save copy of inv list before we take the item
                        table.insert(prev_detached_inv_list, detached_inv:get_stack('main', j))

                        if not qst:is_empty() and not found_arrow_stack then
                            quiver_name = st:get_name()
                            found_arrow_stack = qst:take_item()

                            if not x_bows.is_creative(player_name) then
                                detached_inv:set_list('main', detached_inv_list)
                                x_bows.quiver.save(detached_inv, player, true)
                            end
                        end
                    end
                end
            end

            if found_arrow_stack then
                ---show HUD - quiver inventory
                x_bows.quiver.udate_or_create_hud(player, prev_detached_inv_list)

                break
            end
        end
    end

    return {
        found_arrow_stack = found_arrow_stack,
        quiver_id = quiver_id,
        quiver_name = quiver_name
    }
end

---Remove all added HUDs
---@param player ObjectRef
function x_bows.quiver.remove_hud(player)
    local player_name = player:get_player_name()

    if x_bows.quiver.hud_item_ids[player_name] then
        for _, v in pairs(x_bows.quiver.hud_item_ids[player_name]) do
            if type(v) == 'table' then
                for _, v2 in pairs(v) do
                    player:hud_remove(v2)
                end
            else
                player:hud_remove(v)
            end
        end

        x_bows.quiver.hud_item_ids[player_name] = {
            arrow_inv_img = {},
            stack_count = {}
        }
    else
        x_bows.quiver.hud_item_ids[player_name] = {
            arrow_inv_img = {},
            stack_count = {}
        }
    end
end

---Update or create HUD
---@todo implement hud_change?
---@param player ObjectRef
---@param inv_list ItemStack[]
---@return nil
function x_bows.quiver.udate_or_create_hud(player, inv_list)
    local player_name = player:get_player_name()
    local selected_bg_added = false

    if x_bows.quiver.after_job[player_name] then
        for _, v in pairs(x_bows.quiver.after_job[player_name]) do
            v:cancel()
        end

        x_bows.quiver.after_job[player_name] = {}
    else
        x_bows.quiver.after_job[player_name] = {}
    end

    x_bows.quiver.remove_hud(player)

    ---title image
    x_bows.quiver.hud_item_ids[player_name].title_image = player:hud_add({
        hud_elem_type = 'image',
        position = {x = 1, y = 0.5},
        offset = {x = -120, y = -140},
        text = 'x_bows_quiver.png',
        scale = {x = 4, y = 4},
        alignment = 0,
    })

    ---title copy
    local quiver_def = minetest.registered_items['x_bows:quiver']
    x_bows.quiver.hud_item_ids[player_name].title_copy = player:hud_add({
        hud_elem_type = 'text',
        position = {x = 1, y = 0.5},
        offset = {x = -120, y = -75},
        text = quiver_def.short_description,
        alignment = 0,
        scale = {x = 100, y = 30},
        number = 0xFFFFFF,
    })

    ---hotbar bg
    x_bows.quiver.hud_item_ids[player_name].hotbar_bg = player:hud_add({
        hud_elem_type = 'image',
        position = {x = 1, y = 0.5},
        offset = {x = -238, y = 0},
        text = 'x_bows_quiver_hotbar.png',
        scale = {x = 1, y = 1},
        alignment = {x = 1, y = 0 },
    })

    for j, qst in ipairs(inv_list) do
        if not qst:is_empty() then
            local found_arrow_stack_def = minetest.registered_items[qst:get_name()]

            if not selected_bg_added then
                selected_bg_added = true

                ---ui selected bg
                x_bows.quiver.hud_item_ids[player_name].hotbar_selected = player:hud_add({
                    hud_elem_type = 'image',
                    position = {x = 1, y = 0.5},
                    offset = {x = -308 + (j * 74), y = 2},
                    text = 'x_bows_quiver_hotbar_selected.png',
                    scale = {x = 1, y = 1},
                    alignment = {x = 1, y = 0 },
                })
            end

            if found_arrow_stack_def then
                ---arrow inventory image
                table.insert(x_bows.quiver.hud_item_ids[player_name].arrow_inv_img, player:hud_add({
                    hud_elem_type = 'image',
                    position = {x = 1, y = 0.5},
                    offset = {x = -300 + (j * 74), y = 0},
                    text = found_arrow_stack_def.inventory_image,
                    scale = {x = 4, y = 4},
                    alignment = {x = 1, y = 0 },
                }))

                ---stack count
                table.insert(x_bows.quiver.hud_item_ids[player_name].stack_count, player:hud_add({
                    hud_elem_type = 'text',
                    position = {x = 1, y = 0.5},
                    offset = {x = -244 + (j * 74), y = 23},
                    text = qst:get_count(),
                    alignment = -1,
                    scale = {x = 50, y = 10},
                    number = 0xFFFFFF,
                }))
            end
        end
    end

    ---@param v_player ObjectRef
    table.insert(x_bows.quiver.after_job[player_name], minetest.after(10, function(v_player)
        x_bows.quiver.remove_hud(v_player)
    end, player))
end

---Get existing detached inventory or create new one
---@param quiver_id string
---@param player_name string
---@param quiver_items? string
---@return InvRef
function x_bows.quiver.get_or_create_detached_inv(quiver_id, player_name, quiver_items)
    local detached_inv

    if quiver_id ~= '' then
        detached_inv = minetest.get_inventory({type='detached', name=quiver_id})
    end

    if not detached_inv then
        detached_inv = minetest.create_detached_inventory(quiver_id, {
            ---@param inv InvRef detached inventory
            ---@param from_list string
            ---@param from_index number
            ---@param to_list string
            ---@param to_index number
            ---@param count number
            ---@param player ObjectRef
            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                if x_bows.quiver.quiver_can_allow(inv, player) then
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
                if minetest.get_item_group(stack:get_name(), 'arrow') ~= 0 and x_bows.quiver.quiver_can_allow(inv, player) then
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
                if minetest.get_item_group(stack:get_name(), 'arrow') ~= 0 and x_bows.quiver.quiver_can_allow(inv, player) then
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
                x_bows.quiver.save(inv, player)
            end,
            ---@param inv InvRef detached inventory
            ---@param listname string listname of the inventory, e.g. `'main'`
            ---@param index number index where was item put
            ---@param stack ItemStack stack of item what was put
            ---@param player ObjectRef
            on_put = function(inv, listname, index, stack, player)
                x_bows.quiver.save(inv, player)
            end,
            ---@param inv InvRef detached inventory
            ---@param listname string listname of the inventory, e.g. `'main'`
            ---@param index number
            ---@param stack ItemStack
            ---@param player ObjectRef
            on_take = function(inv, listname, index, stack, player)
                x_bows.quiver.save(inv, player)
            end,
       }, player_name)

       detached_inv:set_size('main', 3 * 1)
    end

    ---populate items in inventory
    if quiver_items and quiver_items ~= '' then
        x_bows.quiver.set_string_to_inv(detached_inv, quiver_items)
    end

    return detached_inv
end

---create UUID
---@return string
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

    ---@diagnostic disable-next-line: redundant-return-value
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---create formspec
---@param name string name of the form
---@return string
local function get_formspec(name)
    local width = 3
    local height = 1
    local list_w = 8
    local list_pos_x = (list_w - width) / 2

    local formspec =
        'size['..list_w..',6]' ..
        'list[detached:'..name..';main;'..list_pos_x..',0.3;'..width..',1;]'..
        'list[current_player;main;0,'..(height + 0.85)..';'..list_w..',1;]'..
        'list[current_player;main;0,'..(height + 2.08)..';'..list_w..',3;8]'..
        'listring[detached:'..name..';main]'..
        'listring[current_player;main]'..
        default.get_hotbar_bg(0, height + 0.85)

    --update formspec
    local inv = minetest.get_inventory({type='detached', name=name})
    local invlist = inv:get_list(name)

    ---inventory slots overlay
    local px, py = list_pos_x, 0.3

    for i = 1, 3 do
        if not invlist or invlist[i]:is_empty() then
            formspec = formspec ..
                'image[' .. px .. ',' .. py .. ';1,1;x_bows_arrow_slot.png]'
        end

        px = px + 1
    end

    return formspec
end

---convert inventory of itemstacks to serialized string
---@param inv InvRef
---@return {['inv_string']: string, ['content_description']: string}
local function get_string_from_inv(inv)
    local inv_list = inv:get_list('main')
    local t = {}
    local content_description = ''

    for i, st in ipairs(inv_list) do
        if not st:is_empty() then
            table.insert(t, st:to_table())
            content_description = content_description .. '\n' ..st:get_short_description()..' '..st:get_count()
        else
            table.insert(t, {is_empty = true})
        end
    end

    return {
        inv_string = minetest.serialize(t),
        content_description = content_description == '' and '\nEmpty' or content_description
    }
end

---set items from serialized string to inventory
---@param inv InvRef inventory to add items to
---@param str string previously stringified inventory of itemstacks
function x_bows.quiver.set_string_to_inv(inv, str)
    local t = minetest.deserialize(str)

    for i, item in ipairs(t) do
        if not item.is_empty then
            inv:set_stack('main', i, ItemStack(item))
        end
    end
end

---save quiver inventory to itemstack meta
---@param inv InvRef
---@param player ObjectRef
---@param quiver_is_closed? boolean default `false`
function x_bows.quiver.save(inv, player, quiver_is_closed)
    local player_inv = player:get_inventory()
    local inv_loc = inv:get_location()
    local quiver_item_name = quiver_is_closed and 'x_bows:quiver' or 'x_bows:quiver_open'

    ---find matching quiver item in players inventory with the open formspec name
    if player_inv and player_inv:contains_item('main', quiver_item_name) then
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            local st_meta = st:get_meta()

            if not st:is_empty() and st:get_name() == quiver_item_name and st_meta:get_string('quiver_id') == inv_loc.name then
                ---save inventory items in quiver item meta
                local string_from_inventory_result = get_string_from_inv(inv)

                st_meta:set_string('quiver_items', string_from_inventory_result.inv_string)

                ---update description
                local new_description = st:get_short_description()..'\n'..string_from_inventory_result.content_description..'\n'

                st_meta:set_string('description', new_description)
                player_inv:set_stack('main', i, st)

                break
            end
        end
    end
end

---check if we are allowing actions in the correct quiver inventory
---@param inv InvRef
---@param player ObjectRef
---@return boolean
function x_bows.quiver.quiver_can_allow(inv, player)
    local player_inv = player:get_inventory()
    local inv_loc = inv:get_location()

    ---find matching quiver item in players inventory with the open formspec name
    if player_inv and player_inv:contains_item('main', 'x_bows:quiver_open') then
        local inv_list = player_inv:get_list('main')

        for i, st in ipairs(inv_list) do
            local st_meta = st:get_meta()

            if not st:is_empty() and st:get_name() == 'x_bows:quiver_open' and st_meta:get_string('quiver_id') == inv_loc.name then
                return true
            end
        end
    end

    return false
end

---Open quiver
---@param itemstack ItemStack
---@param user ObjectRef
---@return ItemStack
function x_bows.open_quiver(itemstack, user)
    local itemstack_meta = itemstack:get_meta()
    local pname = user:get_player_name()
    local quiver_id = itemstack_meta:get_string('quiver_id')

    ---create inventory id and save it
    if quiver_id == '' then
        quiver_id = itemstack:get_name()..'_'..uuid()
        itemstack_meta:set_string('quiver_id', quiver_id)
    end

    local quiver_items = itemstack_meta:get_string('quiver_items')

    x_bows.quiver.get_or_create_detached_inv(quiver_id, pname, quiver_items)

    ---show open variation of quiver
    local replace_item = x_bows.quiver.get_replacement_item(itemstack, 'x_bows:quiver_open')

    itemstack:replace(replace_item)

    minetest.sound_play('x_bows_quiver', {
        to_player = user:get_player_name(),
        gain = 0.1
    })

    minetest.show_formspec(pname, quiver_id, get_formspec(quiver_id))
    return itemstack
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if player and fields.quit then
        x_bows.quiver.close_quiver(player, formname)
    end
end)
