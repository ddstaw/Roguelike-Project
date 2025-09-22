extends Node

func generate_cellar_chunk(chunk_coords: Vector2i, biome_key: String, from_egress: Dictionary, structure_map: Dictionary) -> void:
	var short_key = Constants.get_biome_chunk_key(biome_key)
	var biome_config = Constants.get_biome_config(short_key)

	match short_key:
		"gef":
			var prefab_chunk: String = from_egress.get("chunk", "chunk_1_1")
			generate_all_grassland_cellars(biome_key, from_egress, biome_config, structure_map, prefab_chunk)
		"fep":
			print("🌲 Forest cellar not implemented yet.")
		"vses":
			print("🏚️ Slum cellar not implemented yet.")
		_:
			print("⚠️ Unknown biome key:", biome_key)


func generate_gef_cellar(chunk_coords: Vector2i, biome_key: String, from_egress: Dictionary, structure_map: Dictionary) -> void:
	#print("💥 ENTERED generate_gef_cellar")
	var biome_key_short = Constants.get_biome_chunk_key(biome_key)  # the correct function
	var biome_folder = Constants.get_chunk_folder_for_key(biome_key_short)
	#print("🌍 cellar biome_key_short =", biome_key_short)
	#print("🌍 cellar biome_folder =", biome_folder)
	var chunk_key = "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]

	var chunk_size = Vector2i(40, 40)
	var chunk_blueprints = LoadHandlerSingleton.get_chunk_blueprints()
	if chunk_blueprints.has(chunk_key):
		var bp = chunk_blueprints[chunk_key]
		chunk_size = Vector2i(bp["size"][0], bp["size"][1])
	else:
		chunk_blueprints[chunk_key] = {
			"size": [chunk_size.x, chunk_size.y],
			"tiles": [], "objects": [], "walkability": []
		}

	var origin = chunk_coords * chunk_size

	# Build initial dirt grid
	var grid := []
	for x in range(chunk_size.x):
		grid.append([])
		for y in range(chunk_size.y):
			grid[x].append({
				"tile": "dirt",
				"state": {}
			})

	# ✅ Overlay prefab from register (if exists)
	var prefab_data = LoadHandlerSingleton.load_prefab_register(biome_folder)
	if prefab_data.has(chunk_key):
		var entry = prefab_data[chunk_key]
		#print("📥 Found prefab register entry:", entry)

		var prefab_id = entry.get("prefab_id", "")
		var z_level = -1  # We're *in* cellar gen, this should be explicit
		var coords = entry.get("coords", {"x": 0, "y": 0})

		var prefab_load = LoadHandlerSingleton.load_prefab_data(biome_key_short)
		var all_prefabs = prefab_load[0]
		var all_blueprints = prefab_load[1]

		var prefab_bundle = null
		for p in all_prefabs:
			if p.get("name", "") == prefab_id:
				prefab_bundle = p
				break

		if prefab_bundle == null:
			print("❌ Could not find prefab ID in loaded prefab data:", prefab_id)
		else:
			var floor_key = str(z_level)
			var blueprint_name = prefab_bundle.get("floors", {}).get(floor_key, "")
			if blueprint_name == "":
				print("❌ No floor", floor_key, "defined in prefab:", prefab_id)
			elif not all_blueprints.has(blueprint_name):
				print("❌ Missing blueprint for floor:", blueprint_name)
			else:
				var blueprint_data = all_blueprints[blueprint_name]
				var width = blueprint_data["width"]
				var height = blueprint_data["height"]
				var tiles = blueprint_data["tiles"]
				var legend = blueprint_data.get("legend", {})

				var local_x = coords["x"] - origin.x
				var local_y = coords["y"] - origin.y
				#print("📍 Placing prefab:", prefab_id, "at local:", local_x, local_y, "within chunk", chunk_key)

				for y in range(height):
					if y >= tiles.size():
						#print("⚠️ Tile row index out of bounds:", y)
						continue

					var row = tiles[y]
					for x in range(width):
						if x >= row.length():
							#print("⚠️ Row too short at x =", x, "in row", y, "| Row content:", row)
							continue

						var grid_x = local_x + x
						var grid_y = local_y + y

						if grid_x >= chunk_size.x or grid_y >= chunk_size.y:
							#print("⚠️ Skipping out-of-bounds grid index:", grid_x, grid_y)
							continue

						var symbol = row[x]
						var tex_path = legend.get(symbol, null)
						if tex_path == null:
							#print("⚠️ Unknown symbol in legend:", symbol, "at", x, y)
							continue

						var tex = load(tex_path)
						if tex == null:
							#print("❌ Failed to load texture at:", tex_path, "for symbol:", symbol)
							continue

						var tile_name = Constants.TEXTURE_TO_NAME.get(tex, "dirt")
						#print("✅ Placing tile:", tile_name, "at", grid_x, grid_y, "for symbol:", symbol)
						grid[grid_x][grid_y] = {
							"tile": tile_name,
							"state": LoadHandlerSingleton.get_tile_state_for(tile_name)
						}


	# 🕳️ Inject random stonefloor_hole in Z-1
	var valid_stonefloors := []
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			if grid[x][y].get("tile", "") == "stonefloor":
				valid_stonefloors.append(Vector2i(x, y))

	if valid_stonefloors.size() > 0:
		var pick: Vector2i = valid_stonefloors[randi() % valid_stonefloors.size()]
		grid[pick.x][pick.y] = {
			"tile": "stonefloor_hole",
			"state": LoadHandlerSingleton.get_tile_state_for("stonefloor_hole"),
			"manual_egress": true  # 🔐 Prevent automatic re-registration
		}

		var egress = {
			"type": "stonefloor_hole",
			"target_z": -2,
			"position": { "x": pick.x, "y": pick.y, "z": -1 },  # ⬅️ LOCAL COORDS
			"chunk": chunk_key,
			"biome": Constants.get_biome_name_from_key(biome_key_short)
		}
		LoadHandlerSingleton.register_egress_point(egress)

		# Register corresponding ladder in Z-2
		var global_x = origin.x + pick.x
		var global_y = origin.y + pick.y
		var ladder_chunk_coords = Vector2i(
			floori(global_x / chunk_size.x),
			floori(global_y / chunk_size.y)
		)
		var ladder_chunk_key = "chunk_%d_%d" % [ladder_chunk_coords.x, ladder_chunk_coords.y]

		var ladder_egress = {
			"type": "short_ladder",
			"target_z": -1,
			"position": { "x": pick.x, "y": pick.y, "z": -2 },  # ⬅️ LOCAL COORDS again
			"chunk": chunk_key,
			"biome": Constants.get_biome_name_from_key(biome_key_short)
		}
		LoadHandlerSingleton.register_egress_point(ladder_egress)
		


	# 🧱 Flatten grid
	var flat_tile_grid := {}
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var key = "%d_%d" % [x, y]
			flat_tile_grid[key] = grid[x][y]

		# 🔍 TILE-based egress scan (excluding manual)
	for key in flat_tile_grid.keys():
		var tile_data = flat_tile_grid[key]
		if tile_data.get("manual_egress", false):
			continue  # 🔒 Skip manually registered ones

		var tile_name = tile_data.get("tile", "")
		if Constants.EGRESS_TYPES.has(tile_name):
			var parts = key.split("_")
			if parts.size() == 2:
				var local_x = int(parts[0])
				var local_y = int(parts[1])
				var global_x = origin.x + local_x
				var global_y = origin.y + local_y
				var target_z = Constants.EGRESS_TYPES[tile_name]
				LoadHandlerSingleton.add_egress_point({
					"type": tile_name,
					"target_z": target_z,
					"position": { "x": global_x, "y": global_y, "z": -1 },
					"chunk": chunk_key,
					"biome": Constants.get_biome_name_from_key(biome_key_short)

				})


	# 💾 Save to disk
	var biome_name = Constants.get_biome_name_from_key(biome_key_short)
	save_cellar_chunk(chunk_key, chunk_coords, chunk_size, biome_key_short, -1, flat_tile_grid, {})


func generate_all_grassland_cellars(
	biome_key: String,
	from_egress: Dictionary,
	biome_config: Dictionary,
	structure_map: Dictionary,
	prefab_chunk: String
) -> void:
	#print("📦 ENTERED generate_all_grassland_cellars")
	var chunk_blueprints = LoadHandlerSingleton.get_chunk_blueprints()
	var grid_size: Vector2i = biome_config.get("grid_size", Vector2i(1, 1))
	var chunk_size: Vector2i = biome_config.get("chunk_size", Vector2i(40, 40))

	for x in grid_size.x:
		for y in grid_size.y:
			var coords = Vector2i(x, y)
			var chunk_key = "chunk_%d_%d" % [coords.x, coords.y]

			if not chunk_blueprints.has(chunk_key):
				chunk_blueprints[chunk_key] = {
					"size": [chunk_size.x, chunk_size.y],
					"tiles": [],
					"objects": [],
					"walkability": []
				}

			var egress_data = {}
			if chunk_key == prefab_chunk:
				egress_data = from_egress

			generate_gef_cellar(coords, biome_key, egress_data, structure_map)


func save_cellar_chunk(chunk_key: String, chunk_coords: Vector2i, chunk_size: Vector2i, biome_key_short: String, z_level: int, tile_grid: Dictionary, object_layer: Dictionary) -> void:
	var origin = chunk_coords * chunk_size

	var tile_json = {
		"chunk_coords": chunk_key.replace("chunk_", ""),
		"chunk_origin": { "x": origin.x, "y": origin.y },
		"tile_grid": tile_grid
	}

	var tile_path = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_key, biome_key_short, str(z_level))
	#print("🛠 Saving cellar at Z:", z_level, "with chunk key:", chunk_key)
	#print("🧾 Cellar TILE FILE PATH:", tile_path)
	var object_path = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_key, biome_key_short, str(z_level))

	LoadHandlerSingleton.save_json_file(tile_path, tile_json)
	LoadHandlerSingleton.save_json_file(object_path, { "objects": object_layer })

