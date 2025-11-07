PROJECT: Anima Mundi (Godot 4.2.2 roguelike)

The LoadHandlerSingleton.gd handles all global persistence, chunk I/O, and world-state logic.

STRUCTURE OVERVIEW:
- World and City Systems: manages cities, realms, z-levels, and placement (Ingestion Tests 1–2).
- Chunked Local Map System: chunked save/load for tiles, objects, npcs, terrain, z-levels (Tests 3–4).
- Registers & Loot Systems: node, loot, pile, storage, vendor, egress, prefab, and npc pools (Tests 4–6).
- Inventory Systems: player, mount, vendor, and storage inventories with normalization and weight tracking.
- Build System Integration: verifies materials and hammer tool for constructing objects.
- Time & Date Integration: relies on TimeManager for reset cycles and datetime tracking.
- Constants, ItemData, NodeTable, and BuildData are global definitions feeding all subsystems.

ALL JSON FILES follow this structure:
user://saves/saveX/localchunks/<biome_folder>/<register>.json
or user://saves/saveX/characterdata/<file>.json

Common utilities: save_json_file(), load_json_file(), normalize_stack_stats(), roll_node_loot(), expand_loot_to_inventory().
Signals: "inventory_changed" emitted on item transfers.

When adding new systems (like rumors, quests, journal entries, etc.), follow the REGISTER pattern:
- get_<register>_path()
- load_<register>()
- save_<register>()
- ensure_<register>_entry_with_data()
- clear_<register>_for_biome() [optional]
Each register lives under localchunks/<biome>/rumors_register.json or similar.

===============================

Project: Anima Mundi
Engine: Godot 4.2.2
Core Script: res://scripts/LoadHandlerSingleton.gd
Author: David Stawar
Last Updated: 2025-10-15

🧠 PROJECT DNA — RE-PRIME BLOCK
PROJECT: Anima Mundi (Godot 4.2.2 roguelike)

The LoadHandlerSingleton.gd handles all global persistence, chunk I/O, and world-state logic.

STRUCTURE OVERVIEW:
- World and City Systems: manages cities, realms, z-levels, and placement.
- Chunked Local Map System: chunked save/load for tiles, objects, npcs, terrain, z-levels.
- Registers & Loot Systems: node, loot, pile, storage, vendor, egress, prefab, npc pools.
- Inventory Systems: player, mount, vendor, and storage inventories with normalization and weight tracking.
- Build System Integration: verifies materials and hammer tool for constructing objects.
- Time & Date Integration: relies on TimeManager for reset cycles and datetime tracking.
- Constants, ItemData, NodeTable, and BuildData are global definitions feeding all subsystems.

ALL JSON FILES follow this structure:
user://saves/saveX/localchunks/<biome_folder>/<register>.json  
or user://saves/saveX/characterdata/<file>.json

Common utilities: save_json_file(), load_json_file(), normalize_stack_stats(), roll_node_loot(), expand_loot_to_inventory().  
Signal: "inventory_changed" emitted on item transfers.

When adding new systems (rumors, quests, journals, factions, etc.), follow the REGISTER pattern:
get_<register>_path()  
load_<register>()  
save_<register>()  
ensure_<register>_entry_with_data()  
clear_<register>_for_biome() (optional)

Each register lives under localchunks/<biome>/<register>_register.json

🗂️ KEY FILE PATHS
res://scripts/LoadHandlerSingleton.gd
res://scripts/CityGenScripts/VillageGenerator.gd
res://constants/ItemData.gd
res://constants/BuildData.gd
res://constants/NodeTable.gd
res://singletons/TimeManager.gd

🧱 REGISTER FUNCTION PATTERN
get_<register>_path()
load_<register>()
save_<register>()
ensure_<register>_entry_with_data()
clear_<register>_for_biome()

🗓️ SESSION HISTORY
[2025-10-15] LoadHandlerSingleton.gd fully ingested.

📄 OPTIONAL DEV REFERENCE SNAPSHOT (HEADER)
LOADHANDLERSINGLETON.GD — Core Manager  
Purpose: Central persistence & data management for all world systems, inventories, and chunked maps.  
Subsystems: World Placement, Chunk Management, Terrain, Egress, Prefabs, NPCs, Loot, Storage, Vendor,  
Inventory, Weight, Mounts, Build, Time Reset, Hotbar.  
External Dependencies: Constants.gd, ItemData.gd, BuildData.gd, NodeTable.gd, TimeManager.gd.  
Signal: inventory_changed (global).  
JSON Convention: { z_level → chunk_key → biome_key → entity_id → data }.  

===============================

🧩 LOADHANDLERSINGLETON.GD — Developer Reference Sheet

(Fully ingested as of Lines 1–3315)
Project: Anima Mundi — Godot 4.2.2 roguelike
Purpose: Central persistence & data management for all world systems, inventories, and chunked maps.

🌍 WORLD & PLACEMENT SYSTEM
Function	Description
load_temp_localmap_placement() / save_temp_placement()	Load/save current local_map metadata (chunks, z-levels, biome keys).
get_chunk_origin(chunk_id)	Returns world coordinate origin for a given chunk.
get_chunk_size_for_chunk_id(chunk_id)	Fetches stored chunk dimensions from blueprint data.
get_current_chunk_id() / get_current_z_level()	Tracks player’s active chunk and Z-level.
reset_chunk_state()	Clears all transient chunk data from memory.
set_chunk_blueprints(bp) / get_chunk_blueprints()	Sets or retrieves blueprint data structure.
get_chunk_key_for_pos(pos)	Determines which chunk contains a given global tile position.
_ctx_for_pos(pos)	Returns biome, z-level, and chunk context for a given coordinate.

🗺️ CHUNK MANAGEMENT
Function	Description
save_all_chunked_localmap_files()	Saves multi-chunk data (tiles, objects, NPCs) to disk.
save_chunked_tile_chunk() / object_chunk() / npc_chunk()	Save chunk JSONs individually.
load_chunked_tile_chunk() / object_chunk() / npc_chunk()	Load chunk data by ID.
normalize_chunk_tile_grid() / normalize_object_positions_in_chunk() / normalize_npc_positions_in_chunk()	Normalize coordinates from global → local.
chunk_exists(chunk_coords)	Checks whether chunk is valid/explored.
mark_chunk_as_explored()	Adds chunk to explored list in placement.
flatten_tile_dict_grid()	Converts 2D array → single flat dictionary keyed by "x_y".
get_tile_state_for(tile_name)	Returns default interaction state (e.g., doors/windows).

🧱 TERRAIN, OBJECTS & WALKABILITY
Function	Description
build_position_lookup_from_grid(grid)	Converts walkability grid to lookup dictionary.
get_walkability_bounds(grid)	Returns width and height of walk grid.
is_tile_walkable(grid, pos)	Boolean test for walkability.
get_walkability_grid_for_chunk(chunk_id)	Builds walkability from tiles + object data.
is_tile_walkable_in_chunk(chunk_coords, tile_pos_global)	High-level pathfinding utility using terrain + object layers.

🚪 EGRESS & Z-LEVEL MANAGEMENT
Function	Description
add_egress_point() / get_egress_points()	Add or retrieve egress transition data (stairs, holes, etc.).
save_egress_register() / load_egress_register()	Persistent store for all egresses per biome.
register_egress_point()	Registers both forward and reverse egresses automatically.
get_egress_points_for_z(z)	Filters egress list for a specific z-level.
load_global_egress_data()	Loads cached egress data globally.
reload_from_temp_placement() / change_z_level()	Handles reloading LocalMap scene on Z-level change.
clear_cached_egress_register()	Resets cached register data.

🏗️ PREFAB & BLUEPRINT SYSTEM
Function	Description
load_prefab_data(biome_key)	Loads prefab + blueprint data for biome.
register_prefab_data_for_chunk()	Tracks which prefab blueprint generated which chunk.
get_blueprint_from_register_entry()	Resolves prefab entry to a blueprint definition.
clear_prefab_register_for_biome()	Clears prefab register JSON for biome.
get_prefab_json_path_for_biome()	Maps biome key → prefab data path.

🧍 NPC & ENTITY SYSTEMS
Function	Description
get_npcs_in_chunk(chunk_id)	Loads NPCs for a chunk.
load_npc_pool() / save_npc_pool()	Persistent biome-level NPC pool.
save_chunked_npc_data()	Writes NPC data for multiple chunks.
normalize_npc_positions_in_chunk()	Converts NPC coordinates from global → local.

💎 NODE & LOOT SYSTEMS
Function	Description
get_node_register_path() / load_node_register() / save_node_register()	Manages node_register.json files per biome.
reset_node_register_for_biome()	Resets expired node inventories using TimeManager.
clear_node_register_for_biome()	Clears node register JSON file.
roll_node_loot(node_type, rolls, rng)	Rolls weighted loot from node pool.
expand_loot_to_inventory(rolled, timestamp)	Expands rolled loot into inventory-ready stacks.
ensure_node_entry_with_loot()	Ensures node register entry exists and rolls loot if missing.
update_node_inventory()	Updates node’s saved inventory after looting.
_weighted_pick()	Utility for weighted random selection.

📦 STORAGE, PILE, LOOT, AND VENDOR REGISTERS
Function	Description
load_storage_register() / save_storage_register()	Manages chests and storage objects.
ensure_storage_entry_with_loot()	Rolls natural chest contents on first open.
update_storage_inventory()	Updates stored chest data.
load_pile_register() / save_pile_register()	Handles piles (dropped loot stacks).
load_loot_register() / save_loot_register()	Global loot register per biome.
ensure_vendor_entry_with_loot()	Creates vendor inventories with randomized stock.
clear_vendor_register_for_biome()	Wipes vendor register.

🧰 INVENTORY MANAGEMENT
Function	Description
load_player_inventory_dict() / save_player_inventory_dict()	Core inventory load/save functions.
transfer_item(source, target, stack_id, qty)	Moves or merges stacks between inventories.
_on_transfer_item_completed()	Emits global signal "inventory_changed".
normalize_stack_stats(item)	Updates item’s weight, value, and per-unit stats.
get_best_equipped_light_item_with_id()	Finds equipped light source with largest radius.
is_light_source_equipped() / get_player_light_radius() / get_player_light_color()	Lighting system helpers.

🐎 MOUNT SYSTEM
Function	Description
get_mount_inv_path() / load_mount_inv() / save_mount_inv()	Mount inventory persistence.
chunked_mount_placement()	Automatically places mount objects in chunk near player spawn.
recalc_player_and_mount_weight()	Recalculates combined weight stats.

⚖️ WEIGHT SYSTEM
Function	Description
_get_item_stack_weight(item)	Returns per-stack weight.
_calc_inventory_weight(inv)	Totals inventory weight.
get_player_weight_path() / load_player_weight() / save_player_weight()	Load/save player weight data.
get_avg_value_per(item)	Returns average item value.

🔨 BUILD SYSTEM
Function	Description
get_player_buildreg_path() / load_player_buildreg() / save_player_buildreg()	Handles current build selection and player constructions.
is_holding_hammer_tool()	Returns true if player is holding a valid construction tool.
set_current_build(id)	Updates selected build type.
has_required_materials_for_current_build()	Checks inventory for required materials to build selected object.

🔥 TIME & RESET INTEGRATION
Function	Description
is_datetime_expired(reset_at, current)	Determines if node reset time passed.
calculate_next_reset(current)	Generates next reset datetime (+1440 minutes).
Integrates with TimeManager.get_total_minutes_from_string() and TimeManager.advance_datetime()	

🪶 HOTBAR & QUICK ACCESS
Function	Description
get_player_hotbar_path() / load_player_hotbar() / save_player_hotbar()	Persistent player quick-access slots.

🧱 STATIC UTILITIES & CONSTANTS
Function	Description
get_node_table() / get_node_pool(node_type)	Access constants from NodeTable.
get_chunked_*_path()	All file path generators for chunks.
clear_chunks_for_key()	Deletes all JSON files for a biome folder.
get_localmap_biome_key() / get_localmap_z_key()	Shortcuts for reading placement metadata.
_make_unique_id(rng)	Generates unique item IDs (iXXXXXXXX).
save_json_file() / load_json_file()	Base JSON I/O utilities (implied from ingestion).

🔔 SIGNALS
Signal	Description
inventory_changed	Emitted globally when inventory or storage contents update.

🗂️ PATH CONVENTIONS
Category	Path Example
Save Root	user://saves/saveX/
Character Data	characterdata/player_inventoryX.json
Local Maps	localchunks/<biome_folder>/z<z_level>/chunk_tile_<id>.json
Registers	localchunks/<biome_folder>/<register>_register.json
Prefabs	res://data/prefabs/<biome>-prefabs.json
🧩 EXTERNAL DEPENDENCIES

Constants.gd — biome keys, folder mappings, object blocking rules, reverse egress definitions.
ItemData.gd — item property definitions (ITEM_PROPERTIES).
BuildData.gd — construction definitions (BUILD_PROPERTIES).
NodeTable.gd — defines node loot tables.
TimeManager.gd — time and reset calculations.

🧠 DEVELOPER NOTES

Every new register (e.g. rumors_register.json) should follow the same get/load/save/ensure/clear structure.
All registers live under localchunks/<biome>/ for persistence and chunk context.
Prefer dictionary nesting order: { z_level → chunk_key → biome_key → entity_id → data }.
Always normalize item stacks via normalize_stack_stats() before saving.
Use emit_signal("inventory_changed") after inventory-affecting operations.
If creating new systems (e.g. quests, journals, factions), extend via this same pattern.
