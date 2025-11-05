# res://scripts/localmapgenscripts/statichubentry.gd
extends Node
# 🔖 Universal static hub loader for pre-authored local maps
# Used for Tradeposts, Guildhalls, etc.

const NpcPoolData = preload("res://constants/npc_pool_data.gd")
const MapNpcPlacer = preload("res://scripts/localmapgenscripts/MapNpcPlacer.gd")

var chunked_npc_data := {}

func generate_static_hub(hub_name: String) -> void:
		# 🧹 Clear old cached NPC data from previous biome
	if "chunked_npc_data" in LoadHandlerSingleton:
		LoadHandlerSingleton.chunked_npc_data.clear()
	chunked_npc_data.clear()

	print("🏪 StaticHubEntry: Preparing static hub →", hub_name)

	# ✅ Canonical biome data
	var biome_key = hub_name.to_lower()  # e.g. "tradepost"
	var biome_short_key = Constants.get_biome_chunk_key(biome_key)
	var biome_config = Constants.get_biome_config(biome_short_key)
	var biome_folder = biome_config["folder"]

	var z_level = "z0"
	var save_slot = LoadHandlerSingleton.get_save_slot()
	var save_dir = "user://saves/save%d/localchunks/%s/%s/" % [save_slot, biome_folder, z_level]
	DirAccess.make_dir_recursive_absolute(save_dir)

	# ✅ Locate prefab source folder
	var source_dir = "res://data/%s/%s/" % [biome_folder, z_level]
	var dir = DirAccess.open(source_dir)
	if dir == null:
		push_error("❌ StaticHubEntry: Could not open hub data folder: " + source_dir)
		return

	# ✅ Copy preauthored JSON chunks into save folder
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			var src_path = source_dir + file_name
			var dst_path = save_dir + file_name
			var data = LoadHandlerSingleton.load_json_file(src_path)
			LoadHandlerSingleton.save_json_file(dst_path, data)
			print("📁 Copied:", file_name)

	# ✅ Load NPC spawn rules for this biome
	var npc_rules: Dictionary = NpcPoolData.NPC_POOLS.get(biome_folder, {})
	LoadHandlerSingleton.save_npc_pool(biome_key, npc_rules)

	if npc_rules.is_empty():
		print("⚙️ No NPC pool defined for biome:", biome_folder)
	else:
		print("🐾 Applying NPC placement rules for:", biome_folder)
		# Static hubs are single-chunk, so we fake one grid
		var chunk_key = "chunk_0_0"
		var origin = Vector2i(0, 0)
		var size = biome_config["chunk_size"]

		var tile_path = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_key, biome_short_key, z_level)
		if not FileAccess.file_exists(tile_path):
			print("⚠️ No tile grid found at:", tile_path)
		else:
			var tile_data = LoadHandlerSingleton.load_json_file(tile_path)
			var grid = []
			if tile_data.has("tile_grid"):
				var tile_grid = tile_data["tile_grid"]
				grid.resize(size.x)
				for x in range(size.x):
					grid[x] = []
					for y in range(size.y):
						var key = "%d_%d" % [x, y]
						grid[x].append(tile_grid.get(key, { "tile": "grass", "state": {} }))

				# Placeholder for placed objects (no dynamic placer yet)
				var placed_objects: Dictionary = {}
				
				# ✅ FIXED: instantiate the MapNpcPlacer before calling the function
				var npc_placer = MapNpcPlacer.new()
				var placed_npcs = npc_placer.place_npcs(grid, placed_objects, chunk_key, origin, npc_rules)

				print("🐾 NPC placement rules for chunk", chunk_key, ":", npc_rules)
				print("🐾 Placed NPCs count:", placed_npcs.size(), "for chunk", chunk_key)
				chunked_npc_data[chunk_key] = { "npcs": placed_npcs }
				LoadHandlerSingleton.chunked_npc_data[chunk_key] = { "npcs": placed_npcs }
				LoadHandlerSingleton.save_chunked_npc_chunk(chunk_key, { "npcs": placed_npcs })

	# ✅ Build minimal placement metadata
	var placement := LoadHandlerSingleton.load_temp_localmap_placement()
	if not placement.has("local_map"):
		placement["local_map"] = {}

	placement["local_map"]["biome_key"] = biome_folder
	placement["local_map"]["valid_chunks"] = ["0_0"]

	var spawn_chunk = Constants.get_spawn_chunk_for_biome(biome_key)
	var spawn_offset = Constants.get_spawn_offset_for_biome(biome_key)

	placement["local_map"]["spawn_chunk"] = spawn_chunk
	placement["local_map"]["spawn_offset"] = { "x": spawn_offset.x, "y": spawn_offset.y }
	placement["local_map"]["current_chunk_id"] = spawn_chunk
	placement["local_map"]["__chunk_id_set_by"] = "StaticHubEntry"

	LoadHandlerSingleton.save_temp_placement(placement)

	print("✅ StaticHubEntry setup complete for:", hub_name)
