---https://github.com/sumneko/lua-language-server/wiki

---@alias NodeDef NodeDefAbstract | NodeDefMtgFarming

---Node definition. Used by `minetest.register_node`.
---@class NodeDefAbstract
---@field name string
---@field next_plant string|nil
---@field liquidtype 'none'|'source'|'flowing' specifies liquid flowing physics, "none": no liquid flowing physics, "source": spawns flowing liquid nodes at all 4 sides and below; recommended drawtype: "liquid". "flowing": spawned from source, spawns more flowing liquid nodes around it until `liquid_range` is reached; will drain out without a source; recommended drawtype: "flowingliquid". If it's "source" or "flowing" and `liquid_range > 0`, then both `liquid_alternative_*` fields must be specified
---@field on_rightclick fun(pos: Vector, node: NodeDef, clicker: ObjectRef, itemstack: ItemStack, pointed_thing?: PointedThingDef): ItemStack default: nil, Called when clicker (an ObjectRef) used the 'place/build' key not neccessarily an actual rightclick) while pointing at the node at pos with 'node' being the node table. itemstack will hold clicker's wielded item. Shall return the leftover itemstack. Note: pointed_thing can be nil, if a mod calls this function. This function does not get triggered by clients <=0.4.16 if the "formspec" node metadata field is set.
---@field place_param2 number Value for param2 that is set when player places node
---@field param2 number Value for param2 that is set when player places node
---@field buildable_to boolean If true, placed nodes can replace this node. default: `false`
---@field tiles string|NodeTilesDef Textures of node; +Y, -Y, +X, -X, +Z, -Z. List can be shortened to needed length.
---@field sound NodeSoundDef Definition of node sounds to be played at various events.

---Textures of node; +Y, -Y, +X, -X, +Z, -Z. List can be shortened to needed length.
---@class NodeTilesDef
---@field name string
---@field animation TileAnimationDef
---@field backface_culling boolean backface culling enabled by default for most nodes
---@field align_style 'node'|'world'|'user' align style determines whether the texture will be rotated with the node or kept aligned with its surroundings. "user" means that client setting will be used, similar to `glasslike_framed_optional`. Note: supported by solid nodes and nodeboxes only.
---@field scale number|integer scale is used to make texture span several (exactly `scale`) nodes, instead of just one, in each direction. Works for world-aligned textures only. Note that as the effect is applied on per-mapblock basis, `16` should be equally divisible by `scale` or you may get wrong results.
---@field color ColorSpec the texture's color will be multiplied with this color. the tile's color overrides the owning node's color in all cases.
