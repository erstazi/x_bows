---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---The varying types of decorations that can be placed.
---@class DecorationDef
---@field deco_type 'simple'|'schematic' `simple`: Creates a 1 times `H` times 1 column of a specified node (or a random node from a list, if a decoration list is specified). Can specify a certain node it must spawn next to, such as water or lava, for example. Can also generate a decoration of random height between a specified lower and upper bound. This type of decoration is intended for placement of grass, flowers, cacti, papyri, waterlilies and so on. `schematic`: Copies a box of `MapNodes` from a specified schematic file (or raw description). Can specify a probability of a node randomly appearing when placed. This decoration type is intended to be used for multi-node sized discrete structures, such as trees, cave spikes, rocks, and so on.
---@field biomes any List of biomes in which this decoration occurs. Occurs in all biomes if this is omitted, and ignored if the Mapgen being used does not support biomes. Can be a list of (or a single) biome names, IDs, or definitions.
---@field decoration string| string[] The node name used as the decoration. If instead a list of strings, a randomly selected node from the list is placed as the decoration.
---@field place_on string| string[] Node (or list of nodes) that the decoration can be placed on
