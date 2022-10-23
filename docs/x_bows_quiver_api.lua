----
-- XBowsQuiver class extended from XBows
-- @author SaKeL
-- @license LGPL-2.1-or-later
-- @classmod XBowsQuiver
XBowsQuiver = {
    --- IDs of added HUDs
    hud_item_ids = {},
    --- `after` job tables
    after_job = {}
}

---Close one or all open quivers in players inventory
-- @param self XBowsQuiver
-- @param player ObjectRef
-- @param quiver_id? string If `nil` then all open quivers will be closed
-- @return nil
function XBowsQuiver.close_quiver(self, player, quiver_id) end

---Swap item in player inventory indicating open quiver. Preserve all ItemStack definition and meta.
-- @param self XBowsQuiver
-- @param from_stack ItemStack transfer data from this item
-- @param to_item_name string transfer data to this item
-- @return ItemStack ItemStack replacement item
function XBowsQuiver.get_replacement_item(self, from_stack, to_item_name) end

---Gets arrow from quiver
-- @param self XBowsQuiver
-- @param player ObjectRef
-- @return {["found_arrow_stack"]: ItemStack|nil, ["quiver_id"]: string|nil, ["quiver_name"]: string|nil, ["found_arrow_stack_idx"]: number}
function XBowsQuiver.get_itemstack_arrow_from_quiver(self, player) end

---Remove all added HUDs
-- @param self XBowsQuiver
-- @param player ObjectRef
-- @return nil
function XBowsQuiver.remove_hud(self, player) end

---Update or create quiver HUD
-- @param self XBowsQuiver
-- @param player ObjectRef
-- @param inv_list ItemStack[]
-- @param idx? number
-- @return nil
-- @todo implement hud_change?
function XBowsQuiver.udate_or_create_hud(self, player, inv_list, idx) end

---Get existing detached inventory or create new one
-- @param self XBowsQuiver
-- @param quiver_id string
-- @param player_name string
-- @param quiver_items? string
-- @return InvRef|unknown
function XBowsQuiver.get_or_create_detached_inv(self, quiver_id, player_name, quiver_items) end

---Create formspec
-- @param self XBowsQuiver
-- @param name string name of the form
-- @return string
function XBowsQuiver.get_formspec(self, name) end

---Convert inventory of itemstacks to serialized string
-- @param self XBowsQuiver
-- @param inv InvRef
-- @return {['inv_string']: string, ['content_description']: string}
function XBowsQuiver.get_string_from_inv(self, inv) end

---Set items from serialized string to inventory
-- @param self XBowsQuiver
-- @param inv InvRef inventory to add items to
-- @param str string previously stringified inventory of itemstacks
-- @return nil
function XBowsQuiver.set_string_to_inv(self, inv, str) end

---Save quiver inventory to itemstack meta
-- @param self XBowsQuiver
-- @param inv InvRef
-- @param player ObjectRef
-- @param quiver_is_closed? boolean
-- @return nil
function XBowsQuiver.save(self, inv, player, quiver_is_closed) end

---Check if we are allowing actions in the correct quiver inventory
-- @param self XBowsQuiver
-- @param inv InvRef
-- @param player ObjectRef
-- @return boolean
function XBowsQuiver.quiver_can_allow(self, inv, player) end
