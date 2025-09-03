extends Node
class_name Constants

# Forward mapping
const TILE_TEXTURES := {
	"tree": preload("res://assets/localmap-graphics/tree.png"),
	"tree2": preload("res://assets/localmap-graphics/tree2.png"),
	"tree3": preload("res://assets/localmap-graphics/tree3.png"),
	"grass": preload("res://assets/localmap-graphics/grass.png"),
	"dirt": preload("res://assets/localmap-graphics/dirt.png"),
	"water": preload("res://assets/localmap-graphics/water.png"),
	"path": preload("res://assets/localmap-graphics/path.png"),
	"bush": preload("res://assets/localmap-graphics/bush.png"),
	"flowers": preload("res://assets/localmap-graphics/flowers.png"),
	"bridge": preload("res://assets/localmap-graphics/bridge.png"),
	"hole": preload("res://assets/localmap-graphics/hole.png"),
	"stonefloor": preload("res://assets/localmap-graphics/stonefloor.png"),
	"bed": preload("res://assets/localmap-graphics/bed.png"),
	"candelabra": preload("res://assets/localmap-graphics/candlelabra.png"),
	"stairs": preload("res://assets/localmap-graphics/stairs.png"),
	"stone_stairs_up": preload("res://assets/localmap-graphics/stonefloor_stairs_up.png"),
	"stone_stairs_down": preload("res://assets/localmap-graphics/stonefloor_stairs_down.png"),
	"stonefloor_hole": preload("res://assets/localmap-graphics/stonefloor_hole.png"),
	"woodchest": preload("res://assets/localmap-graphics/woodchest.png"),
	"stonewallside": preload("res://assets/localmap-graphics/stonewallside.png"),
	"stonewallsidewindow": preload("res://assets/localmap-graphics/stonewallsidewindow.png"),
	"stonewallbottom": preload("res://assets/localmap-graphics/stonewallbottom.png"),
	"short_ladder": preload("res://assets/localmap-graphics/short_ladder.png"),
	"long_ladder": preload("res://assets/localmap-graphics/long_ladder.png"),
	"stonedoor": preload("res://assets/localmap-graphics/stonedoor.png"),
	"stonedoor_open": preload("res://assets/localmap-graphics/stonedoor_open.png"),
	"stonewallbottomwindow": preload("res://assets/localmap-graphics/stonewallbottomwindow.png"),
	"stonewallbottomwindow_broken": preload("res://assets/localmap-graphics/stonewallbottomwindow_broken.png"),
	"stonewallbottomwindow_curtains": preload("res://assets/localmap-graphics/stonewallbottomwindow_curtains.png"),
	"stonewallbottomwindow_open": preload("res://assets/localmap-graphics/stonewallbottomwindow_open.png"),
	"stonewallsidewindow_broken": preload("res://assets/localmap-graphics/stonewallsidewindow_broken.png"),
	"stonewallsidewindow_curtains": preload("res://assets/localmap-graphics/stonewallsidewindow_curtains.png"),
	"stonewallsidewindow_open": preload("res://assets/localmap-graphics/stonewallsidewindow_open.png"),
	"candelabra_lit": preload("res://assets/localmap-graphics/candlelabra_lit.png"),
	"slum_brick_wallside": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_wallside.png"),
	"slum_brick_wallbottom": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_wallbottom.png"),
	"slum_brick_wallbottom_window": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_wallbottom_window.png"),
	"slum_brick_wallside_window": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_wallside_window.png"),
	"slum_brick_floor": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_floor.png"),
	"slum_brick_door": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_door.png"),
	"slum_brick_door_open": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_door_open.png"),
	"slum_brick_floor_stairs_down": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_floor_stairs_down.png"),
	"slum_brick_floor_stairs_up": preload("res://assets/localmap-graphics/terrain/village-slums/slum_brick_floor_stairs_up.png"),
	"slum_stone_floor": preload("res://assets/localmap-graphics/terrain/village-slums/slum_stone_floor.png"),
	"slum_streetlamp_broken": preload("res://assets/localmap-graphics/objects/village-slums/slum_streetlamp_broken.png"),
	"slum_streetlamp": preload("res://assets/localmap-graphics/objects/village-slums/slum_streetlamp.png"),
	"slum_trash_looted": preload("res://assets/localmap-graphics/objects/village-slums/slum_trash_looted.png"),
	"slum_trash": preload("res://assets/localmap-graphics/objects/village-slums/slum_trash.png"),
	"slum_wood_fence": preload("res://assets/localmap-graphics/terrain/village-slums/slum_wood_fence.png"),
	"slum_sidewalk_floor": preload("res://assets/localmap-graphics/terrain/village-slums/slum_sidewalk_floor.png"),
	"sewer_door": preload("res://assets/localmap-graphics/objects/village-slums/sewer_door.png"),
	"slum_road_floor": preload("res://assets/localmap-graphics/terrain/village-slums/slum_road_floor.png"),
	"caverock": preload("res://assets/localmap-graphics/caverock.png"),
	"cavewallbottom": preload("res://assets/localmap-graphics/cavewallbottom.png"),
	"cavewallside": preload("res://assets/localmap-graphics/cavewallside.png"),
	"orangecat": preload("res://assets/localmap-graphics/npcs/orange_cat.png"),
	"greensnake": preload("res://assets/localmap-graphics/npcs/green_snake.png"),
	"bluewizard": preload("res://assets/localmap-graphics/npcs/blue_wizard.png")



}


# Reverse lookup (manually declared)
const TEXTURE_TO_NAME := {
	TILE_TEXTURES["tree"]: "tree",
	TILE_TEXTURES["tree2"]: "tree2",
	TILE_TEXTURES["tree3"]: "tree3",
	TILE_TEXTURES["grass"]: "grass",
	TILE_TEXTURES["dirt"]: "dirt",
	TILE_TEXTURES["water"]: "water",
	TILE_TEXTURES["path"]: "path",
	TILE_TEXTURES["bush"]: "bush",
	TILE_TEXTURES["flowers"]: "flowers",
	TILE_TEXTURES["bridge"]: "bridge",
	TILE_TEXTURES["hole"]: "hole",
	TILE_TEXTURES["stonefloor"]: "stonefloor",
	TILE_TEXTURES["bed"]: "bed",
	TILE_TEXTURES["candelabra"]: "candelabra",
	TILE_TEXTURES["stairs"]: "stairs",
	TILE_TEXTURES["woodchest"]: "woodchest",
	TILE_TEXTURES["stonewallside"]: "stonewallside",
	TILE_TEXTURES["stonewallbottom"]: "stonewallbottom",
	TILE_TEXTURES["stonedoor_open"]: "stonedoor_open",
	TILE_TEXTURES["stonewallbottomwindow"]: "stonewallbottomwindow",
	TILE_TEXTURES["stonewallsidewindow"]: "stonewallsidewindow",
	TILE_TEXTURES["short_ladder"]: "short_ladder",
	TILE_TEXTURES["long_ladder"]: "long_ladder",
	TILE_TEXTURES["stone_stairs_up"]: "stone_stairs_up",
	TILE_TEXTURES["stone_stairs_down"]: "stone_stairs_down",
	TILE_TEXTURES["stonefloor_hole"]: "stonefloor_hole",
	TILE_TEXTURES["stonedoor"]: "stonedoor",
	TILE_TEXTURES["stonewallbottomwindow_broken"]: "stonewallbottomwindow_broken",
	TILE_TEXTURES["stonewallbottomwindow_curtains"]: "stonewallbottomwindow_curtains",
	TILE_TEXTURES["stonewallbottomwindow_open"]: "stonewallbottomwindow_open",
	TILE_TEXTURES["stonewallsidewindow_broken"]: "stonewallsidewindow_broken",
	TILE_TEXTURES["stonewallsidewindow_curtains"]: "stonewallsidewindow_curtains",
	TILE_TEXTURES["stonewallsidewindow_open"]: "stonewallsidewindow_open",
	TILE_TEXTURES["slum_brick_wallside"]: "slum_brick_wallside",
	TILE_TEXTURES["slum_brick_wallbottom"]: "slum_brick_wallbottom",
	TILE_TEXTURES["slum_brick_wallbottom_window"]: "slum_brick_wallbottom_window",
	TILE_TEXTURES["slum_brick_wallside_window"]: "slum_brick_wallside_window",
	TILE_TEXTURES["slum_brick_floor"]: "slum_brick_floor",
	TILE_TEXTURES["slum_brick_door"]: "slum_brick_door",
	TILE_TEXTURES["slum_brick_door_open"]: "slum_brick_door_open",
	TILE_TEXTURES["slum_brick_floor_stairs_down"]: "slum_brick_floor_stairs_down",
	TILE_TEXTURES["slum_brick_floor_stairs_up"]: "slum_brick_floor_stairs_up",
	TILE_TEXTURES["slum_stone_floor"]: "slum_stone_floor",
	TILE_TEXTURES["slum_streetlamp_broken"]: "slum_streetlamp_broken",
	TILE_TEXTURES["slum_streetlamp"]: "slum_streetlamp",
	TILE_TEXTURES["slum_trash_looted"]: "slum_trash_looted",
	TILE_TEXTURES["slum_trash"]: "slum_trash",
	TILE_TEXTURES["slum_wood_fence"]: "slum_wood_fence",
	TILE_TEXTURES["slum_sidewalk_floor"]: "slum_sidewalk_floor",
	TILE_TEXTURES["slum_road_floor"]: "slum_road_floor",
	TILE_TEXTURES["sewer_door"]: "sewer_door",
	TILE_TEXTURES["candelabra_lit"]: "candelabra_lit",
	TILE_TEXTURES["caverock"]: "caverock",
	TILE_TEXTURES["cavewallbottom"]: "cavewallbottom",
	TILE_TEXTURES["cavewallside"]: "cavewallside",
	TILE_TEXTURES["orangecat"]: "orangecat",
	TILE_TEXTURES["greensnake"]: "greensnake",
	TILE_TEXTURES["bluewizard"]: "bluewizard"
}

const TRANSITION_TEXTURES := {
	"north": preload("res://assets/localmap-graphics/transitions/north.png"),
	"east": preload("res://assets/localmap-graphics/transitions/east.png"),
	"south": preload("res://assets/localmap-graphics/transitions/south.png"),
	"west": preload("res://assets/localmap-graphics/transitions/west.png"),
	"exit": preload("res://assets/localmap-graphics/transitions/exit.png")
}

const DOOR_PAIRS := {
	"stonedoor": "stonedoor_open",
	"slum_brick_door": "slum_brick_door_open",
	"stonedoor_open": "stonedoor",
	"slum_brick_door_open": "slum_brick_door"
}

const EGRESS_TYPES := {
	"stairs": -1,
	"hole": -2,
	"sewer_door": -2,
	"short_ladder": 1,
	"long_ladder": 2,
	"slum_brick_floor_stairs_down": -1,
	"stone_stairs_up": 1,
	"stone_stairs_down": -1,
	"stonefloor_hole": -1,
	"slum_brick_floor_stairs_up": 1
}

static var REVERSE_EGRESS_TYPES = {
	"hole": "long_ladder",   # Assume hole goes down to z-2, reverse is ladder going up
	"stone_stairs_down": "stone_stairs_up", # Stairs go both ways, same symbol
	"stone_stairs_up": "stone_stairs_down", # Stairs go both ways, same symbol
	"slum_brick_floor_stairs_down": "slum_brick_floor_stairs_up", # Stairs go both ways, same symbol
	"slum_brick_floor_stairs_up": "slum_brick_floor_stairs_down", # Stairs go both ways, same symbol
	"sewer_door": "long_ladder" # Stairs go both ways, same symbol
}

static var MANUAL_EGRESS_TYPES = {
	"stonefloor_hole": true,
	"short_ladder": true
}

static func is_door(tile_type: String) -> bool:
	return DOOR_PAIRS.has(tile_type)

# Mapping of object types to texture keys
const OBJECT_TEXTURE_KEYS := {
	"bed": "bed",
	"candelabra": "candelabra",
	"woodchest": "woodchest",
	"short_ladder": "short_ladder",
	"long_ladder": "long_ladder",
	"stairs": "stairs",
	"sewer_door": "sewer_door",
	"slum_streetlamp": "slum_streetlamp",
	"slum_trash": "slum_trash",
	"hole": "hole",
	"mount": null
	# Add more here over time
}

# Mapping of npc types to texture keys
const NPC_TEXTURE_KEYS := {
	"orangecat": "orangecat",
	"greensnake": "greensnake",
	"bluewizard": "bluewizard"
	# Add more here over time
}

# Helper to get texture for an object type
static func get_object_texture(type: String) -> Texture2D:
	var key = OBJECT_TEXTURE_KEYS.get(type, null)
	return TILE_TEXTURES.get(key, null)

# Helper to get texture for an object type
static func get_npc_texture(type: String) -> Texture2D:
	var key = NPC_TEXTURE_KEYS.get(type, null)
	return TILE_TEXTURES.get(key, null)

const PLAYER_LOOKS_ASSETS := {
	"base": [
		"res://assets/localmap-graphics/player/base-player.png",
		"res://assets/localmap-graphics/player/base-player2.png"
	],
	"armor": [
		"res://assets/localmap-graphics/player/armor-1.png",
		"res://assets/localmap-graphics/player/armor-2.png"
	],
	"cape": [
		"res://assets/localmap-graphics/player/cape-1.png",
		"res://assets/localmap-graphics/player/cape-2.png"
	],
	"hat": [
		"res://assets/localmap-graphics/player/hat-1.png",
		"res://assets/localmap-graphics/player/hat-2.png"
	],
	"main_weapon": [
		"res://assets/localmap-graphics/player/main-1.png",
		"res://assets/localmap-graphics/player/main-2.png"
	],
	"offhand": [
		"res://assets/localmap-graphics/player/offhand-1.png",
		"res://assets/localmap-graphics/player/offhand-2.png",
		"res://assets/localmap-graphics/player/offhand-3.png"
	]
}

const BIOME_LABELS := {
	"village-gate": "Town Gate",
	"village-church": "Large Church",
	"village-commercial": "Markets",
	"village-manor": "Lavish Manor",
	"village-courthouse": "Courthouse",
	"village-center": "Town Center",
	"village-slumchurch": "Small Church",
	"village-slums": "Slums",
	"village-slumworkhouse": "Workhouses",
	"village-residence": "Cottages",
	"village-tavern": "Tavern",
	"grass": "Grasslands",
	"road": "Road",
	"bridge": "Bridge",
	"forest": "Forest",
	"mountains": "Mountains",
	"ocean": "Lake",
	"northpass": "Northern Passage",
	"eastpass": "Eastern Passage",
	"westpass": "Western Passage",
	"southpass": "Southern Passage"
}

# Optional animated tiles (used by MapRenderer)
const ANIMATED_TILE_DEFINITIONS := {
	"water": {
		"frames": [
			"res://assets/localmap-graphics/terrain/water-sprites/water1.png",
			"res://assets/localmap-graphics/terrain/water-sprites/water2.png",
			"res://assets/localmap-graphics/terrain/water-sprites/water3.png",
			"res://assets/localmap-graphics/terrain/water-sprites/water4.png"
		],
		"frame_time": 0.25
	}
}

const SLUM_STREETLAMP_COORDS := {
	"chunk_0_0": [Vector2i(5, 5), Vector2i(5, 24), Vector2i(5, 42), Vector2i(23, 42), Vector2i(23, 5)],
	"chunk_1_0": [Vector2i(1, 5), Vector2i(1, 42), Vector2i(18, 5), Vector2i(18, 42), Vector2i(35, 5), Vector2i(35, 42)],
	"chunk_2_0": [Vector2i(16, 5), Vector2i(16, 42), Vector2i(33, 42), Vector2i(33, 24), Vector2i(33, 5)],
}


static func get_animated_tile_config(name: String) -> Dictionary:
	return ANIMATED_TILE_DEFINITIONS.get(name, {})

static func get_biome_label(biome: String) -> String:
	return BIOME_LABELS.get(biome, biome.capitalize())

const TerrainData = preload("res://constants/terrain_data.gd")
const ObjectData = preload("res://constants/object_data.gd")
const NpcData = preload("res://constants/npc_data.gd")


static func get_object_property(type: String, property: String, default_value: Variant = null) -> Variant:
	return ObjectData.OBJECT_PROPERTIES.get(type, {}).get(property, default_value)

static func get_terrain_property(type: String, property: String, default_value: Variant = null) -> Variant:
	return TerrainData.TERRAIN_PROPERTIES.get(type, {}).get(property, default_value)

static func is_blocking_movement(terrain_type: String, object_type: String = "", tile_state: Dictionary = {}) -> bool:
	# 🚪 Special case: if it's a stonedoor and marked open in tile state, it's not blocking
	if Constants.is_door(terrain_type) and tile_state.get("is_open", false):
		return false  # Open doors don't block

	var terrain_blocks = TerrainData.TERRAIN_PROPERTIES.get(terrain_type, {}).get("blocks_movement", false)
	var object_blocks = ObjectData.OBJECT_PROPERTIES.get(object_type, {}).get("blocks_movement", false)
	return terrain_blocks or object_blocks


static func is_blocking_vision(terrain_type: String, object_type: String = "", tile_state: Dictionary = {}) -> bool:
	if Constants.is_door(terrain_type) and tile_state.get("is_open", false):
		return false  # Open doors don't block

	var terrain_blocks = TerrainData.TERRAIN_PROPERTIES.get(terrain_type, {}).get("blocks_vision", false)
	var object_blocks = ObjectData.OBJECT_PROPERTIES.get(object_type, {}).get("blocks_vision", false)
	return terrain_blocks or object_blocks

static func get_texture_from_name(name: String) -> Texture2D:
	return TILE_TEXTURES.get(name, null)

static func find_object_at(objects: Dictionary, x: int, y: int, return_with_id: bool = false) -> Dictionary:
	for obj_id in objects.keys():
		var obj = objects[obj_id]
		if obj.has("position"):
			var pos = obj["position"]
			if int(pos["x"]) == x and int(pos["y"]) == y:
				if return_with_id:
					return {
						"id": obj_id,
						"data": obj
					}
				else:
					return obj
	return {}

static func get_spawn_chunk_for_biome(biome: String) -> String:
	match biome:
		"grass": return "chunk_1_1"
		"village-slums": return "chunk_0_0"
		"forest": return "chunk_0_0"  # 🆕 Start at the leftmost forest chunk
		_: return "chunk_1_1"  # Default fallback

static func get_spawn_offset_for_biome(biome: String) -> Vector2i:
	match biome:
		"grass": return Vector2i(25, 25)
		"forest": return Vector2i(5, 3)  # Near western edge, but not hard corner
		"village-slums": return Vector2i(5, 10)  # Near western edge, but not hard corner
		_: return Vector2i(25, 25)  # Fallback

static func get_chunk_folder_for_key(key: String) -> String:
	match key:
		"gef": return "grassland_explore_fields"
		"fep": return "forest_explore_path"
		"vses": return "village_slums_explore_slumblock"
		_: return "default_chunk_folder"  # fallback for safety

static func get_biome_chunk_key(biome: String) -> String:
	match biome:
		"grass": return "gef"
		"forest": return "fep"
		"village-slums": return "vses"
		_: return "gef"  # default fallback

static func get_biome_folder_from_key(key: String) -> String:
	match key:
		"gef": return "grassland_explore_fields"
		"fep": return "forest_explore_path"
		"vses": return "village_slums_explore_slumblock"
		_: return "grassland_explore_fields"

static func get_chunk_key_from_folder(folder: String) -> String:
	match folder:
		"grassland_explore_fields": return "gef"
		"forest_explore_path": return "fep"
		"village_slums_explore_slumblock": return "vses"
		_: return "gef"  # fallback

static func get_biome_name_from_key(key: String) -> String:
	match key:
		"gef": return "grass"
		"fep": return "forest"
		"vses": return "village-slums"
		_: return "grass"  # fallback

static var BIOME_CONFIGS = {
	"gef": {
		"folder": "grassland_explore_fields",
		"chunk_size": Vector2i(40, 40),
		"grid_size": Vector2i(3, 3)
	},
	"fep": {
		"folder": "forest_explore_path",
		"chunk_size": Vector2i(32, 32),
		"grid_size": Vector2i(2, 2)
	},
	"vses": {
		"folder": "village_slums_explore_slumblock",
		"chunk_size": Vector2i(48, 48),
		"grid_size": Vector2i(4, 3)
	}
}

static func get_biome_config(short_key: String) -> Dictionary:
	return BIOME_CONFIGS.get(short_key, {
		"folder": "default_chunk_folder",
		"chunk_size": Vector2i(40, 40),
		"grid_size": Vector2i(1, 1)
	})
