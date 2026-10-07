# X Bows

![X Bows Screenshot](screenshot.png)

[![ContentDB](https://content.luanti.org/packages/SaKeL/x_bows/shields/title.svg)](https://content.luanti.org/packages/SaKeL/x_bows/)
[![License: LGPL v2.1](https://img.shields.io/badge/License-LGPL_v2.1-blue.svg)](LICENSE.txt)

**X Bows** is a comprehensive, authentic archery and projectile combat mod for Luanti. It delivers fluid bow mechanics, realistic parabolic ballistic trajectory physics, tiered arrows with dynamic charging curves, 3D back-quivers with inventory quickview, interactive target blocks, enchanting support, and a flexible developer API.

---

## Key Features

### Realistic Ballistic Flight & Trajectory Physics
- **True Parabolic Trajectory**: Arrows travel with continuous acceleration, realistic gravity curves, and pitch alignment along their velocity vector.
- **Water Deceleration & Bubbles**: Arrows entering water decelerate, spawn buoyant bubble particle trails, and slowly sink to the floor.
- **Near-Miss Flyby Audio**: Arrows soaring past nearby players play realistic supersonic flyby whoosh cues.
- **Smart Attachment Lifecycle**:
  - Embedded arrows stick to solid nodes, entities (mobs), and players.
  - Arrows lodged in solid nodes can be retrieved by walking over or punching them.
  - If an attached block is dug or destroyed, the arrow detaches and falls by gravity.
  - **DeathStats Corpse Transfer**: Arrows embedded in players seamlessly transfer to their fallen corpse entity upon death.

### Dynamic Charging & Critical Hits
- **Progressive Draw Tension**: Hold right-click (or place) to draw the bow, accompanied by progressive string creak audio cues and an audible click when reaching full draw.
- **Draw Visuals**: Bow visually transitions through uncharged, semi-charged, and fully charged states.
- **Quadratic Charge Easing Curve**: Arrow velocity, flight distance, and damage scale quadratically with draw duration.
- **Critical Strike Chance**: Fully charged shots have a chance to score a critical hit (double damage), indicated by a high-velocity crimson particle trail and a distinct audio cue.
- **Tactical Movement**: Charging forces player sneak/slowdown (when `playerphysics`, `player_monoids`, or `pova` is installed) and subtly tightens the field of view (FOV).
- **Safe Unload**: Switching hotbar slots, dropping the bow, or disconnecting safely refunds the loaded arrow and resets the bow.

### Tiered Arrows
Six progressive arrow tiers provide escalating damage, tighter charge times, and specialized recipes:

| Arrow Tier | Damage | Charge Time | Materials / Recipe |
| :--- | :---: | :---: | :--- |
| **Wood Arrow** | 2 HP | 1.0s | Flint, Wooden Stick, Feather / Grass |
| **Stone Arrow** | 3 HP | 0.9s | Flint, Cobblestone, Feather / Grass |
| **Bronze Arrow** | 4 HP | 0.9s | Flint, Bronze Ingot, Feather / Grass |
| **Steel Arrow** | 5 HP | 0.8s | Flint, Steel Ingot, Feather / Grass |
| **Mese Arrow** | 6 HP | 0.8s | Flint, Mese Crystal, Feather / Grass |
| **Diamond Arrow** | 8 HP | 0.7s | Flint, Diamond, Feather / Grass |

### 3D Quivers & Inventory Quickview
- **Dedicated Equipment Slots**: Seamlessly integrates dedicated arrow and quiver inventory slots into `i3`, `unified_inventory`, and `sfinv`.
- **Passive Quiver Perks**: Firing arrows directly from an equipped quiver grants **Faster Arrows** (+10% velocity, blue/purple particle trail) and **Bonus Damage** (+1 damage).
- **HUD Quickview Dock**: Loading or shooting from a quiver temporarily displays a semi-transparent HUD overlay peeking into the quiver's contents.
- **3D Quiver Model**: Renders a stylish 3D quiver on the player's back in 3rd-person view (compatible with `player_api`, `3d_armor`, and `skinsdb`).
- **Dynamic Quiver States**: Displays filled or empty visual states based on remaining ammunition.

### Interactive Target Block
- **Archery Practice & Competitions**: Placeable hay target block (`x_bows:target`) that detects projectile impacts on all 6 faces.
- **Mesecons Signal Generator**: Emits a momentary Mesecons pulse when struck by an arrow, enabling automated archery range targets, door triggers, and minigames.
- **Fall Cushioning**: Landing on a target block reduces fall damage by -30 HP for safe high-altitude drops.

### Enchantment Integration (`x_enchanting`)
Enhance bows with magical enchantments:
- **Power**: Multiplies base arrow damage.
- **Punch**: Amplifies arrow knockback velocity and vertical lift.
- **Infinity**: Fires without consuming arrows from inventory.
- **Unbreaking**: Substantially reduces durability wear.

---

## How to Play

### Shooting the Bow
1. **Load Ammunition**: Place arrows and/or a quiver in your dedicated quiver inventory slot (accessible via your inventory screen tab).
2. **Draw & Aim**: With the bow wielded, hold **Right-Click** (or place block action).
3. **Listen for Full Draw**: The string will creak; wait for the distinct "click" confirming maximum charge for peak speed, range, and critical strike chance.
4. **Release**: Press **Left-Click** (or dig block action) to loose the arrow.

### Equipping Quivers
- Open your inventory and place a crafted quiver into the dedicated quiver slot.
- Fill the quiver with arrows to activate the passive speed and damage bonuses.
- Shift-click or hover over a quiver to view its remaining contents via hover tooltip infotext.

---

## Crafting Recipes

### Bow
- `3x String` + `3x Wooden Stick` arranged in a classic curved bow pattern.

### Quiver
- `3x Leather` (or Wool) + `1x String` to craft a portable quiver.

### Target Block
- `4x Wheat / Straw` + `4x Wood Planks` surrounding a central bullseye.

---

## Configuration

Settings can be customized via the in-game Settings menu (`Settings -> All Settings -> Mods -> x_bows`) or directly in `luanti.conf`:

```ini
# Attach arrows to entities and mobs
x_bows_attach_arrows_to_entities = true

# Display animated floating damage numbers on hit
x_bows_show_damage_numbers = false

# Show 3D quiver model on player back in 3rd person view
x_bows_show_3d_quiver = true

# Toggle individual arrow tiers and their crafting recipes
x_bows_enable_arrow_wood = true
x_bows_enable_arrow_stone = true
x_bows_enable_arrow_bronze = true
x_bows_enable_arrow_steel = true
x_bows_enable_arrow_mese = true
x_bows_enable_arrow_diamond = true
```

---

## Developer API

X Bows provides an extensible, modular API for registering custom bows, arrows, and quivers:

```lua
-- Register a custom arrow
XBows:register_arrow("arrow_fire", {
    description = "Fire Arrow",
    inventory_image = "my_mod_arrow_fire.png",
    custom = {
        recipe = {
            { "default:flint" },
            { "default:torch" },
            { "farming:wheat" }
        },
        tool_capabilities = {
            full_punch_interval = 0.8,
            max_drop_level = 1,
            damage_groups = { fleshy = 7 }
        },
        particle_effect = "fire_trail",
        on_hit_node = function(pos, node, shooter)
            core.set_node(pos, { name = "fire:basic_flame" })
        end
    }
})

-- Register a custom bow
XBows:register_bow("bow_longbow", {
    description = "Reinforced Longbow",
    inventory_image = "my_mod_longbow.png",
    custom = {
        strength = 75,             -- Higher arrow velocity
        uses = 350,                -- Increased durability
        crit_chance = 4,           -- 1-in-4 (25%) critical hit rate
        sound_shoot = "my_mod_longbow_shoot"
    }
})

-- Register a custom quiver
XBows:register_quiver("quiver_elven", {
    description = "Elven Quiver",
    inventory_image = "my_mod_quiver_elven.png",
    custom = {
        faster_arrows = 1.3,       -- +30% arrow flight speed
        add_damage = 3             -- +3 bonus damage
    }
})
```

---

## Compatibility

- **Damage & Armor**: Native integration with Luanti Game damage mechanics and `3d_armor`.
- **Combat & Death Tracking**: Full damage attribution and corpse arrow transfer with `deathstats`.
- **Inventory Management**: Built-in tabs and detached inventory synchronization for `i3`, `unified_inventory`, and `sfinv`.
- **Player Models & Skins**: 3D back-quiver support for `player_api`, `x_player_api`, `3d_armor`, `skinsdb`, `simple_skins`, `u_skins`, and `wardrobe`.
- **Locomotion & Sneak**: Movement throttling while drawing via `playerphysics`, `player_monoids`, and `pova`.
- **Automation & Circuitry**: Mesecons strike activation with `mesecons`.
- **Enchanting**: Full enchantment compatibility with `x_enchanting`.

---

## License

- **Code**: LGPL-2.1-or-later (see [LICENSE.txt](LICENSE.txt))
- **Media & Assets**: CC-BY-SA-4.0 / CC0-1.0 (see [LICENSE.txt](LICENSE.txt) for full attribution)
