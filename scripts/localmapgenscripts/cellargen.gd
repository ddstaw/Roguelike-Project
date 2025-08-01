extends Node

func generate_cellar_chunk(chunk_coords: Vector2i, biome_key: String, from_egress: Dictionary) -> void:
	print("🔧 Generating Z-1 cellar for biome:", biome_key, "at chunk", chunk_coords)
	var short_key = Constants.get_biome_chunk_key(biome_key)
	match short_key:
		"gef":
			generate_gef_cellar(chunk_coords, short_key, from_egress)
		"fep":
			print("🌲 Forest cellar not implemented yet.")
		"vses":
			print("🏚️ Slum cellar not implemented yet.")
		_:
			print("⚠️ Unknown biome key:", biome_key)

func generate_gef_cellar(chunk_coords: Vector2i, biome_key: String, from_egress: Dictionary) -> void:
	var biome_folder = biome_key  # already the full folder name
	var biome_key_short = Constants.get_chunk_key_from_folder(biome_folder)
	var chunk_key = "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]

	# 🔍 Get chunk size from blueprint
	var chunk_size = Vector2i(40, 40)  # fallback
	var chunk_blueprints = LoadHandlerSingleton.get_chunk_blueprints()
	if chunk_blueprints.has(chunk_key):
		var bp = chunk_blueprints[chunk_key]
		chunk_size = Vector2i(bp["size"][0], bp["size"][1])
	else:
		print("⚠️ No blueprint found for", chunk_key, "→ using fallback chunk size:", chunk_size)

	var origin = chunk_coords * chunk_size

	# 🧱 Build full grid first
	var grid := []
	for x in range(chunk_size.x):
		grid.append([])
		for y in range(chunk_size.y):
			grid[x].append({
				"tile": "dirt",
				"state": {}
			})

	# 🪜 Place ladder before flattening
	if from_egress.has("position"):
		var pos = from_egress["position"]
		var ladder_pos = Vector2i(pos["x"], pos["y"])
		var local_pos = ladder_pos - origin
		grid[local_pos.x][local_pos.y] = {
			"tile": "ladder",
			"state": LoadHandlerSingleton.get_tile_state_for("ladder")
		}
		print("🪜 Ladder placed at:", "%d_%d" % [local_pos.x, local_pos.y], "→ global:", ladder_pos)
	else:
		print("⚠️ No position in egress data!")

	# 🧱 Flatten grid AFTER edits
	var flat_tile_grid := {}
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var key = "%d_%d" % [x, y]
			flat_tile_grid[key] = grid[x][y]
	print("🧱 Flat dirt grid contains:", flat_tile_grid.size(), "tiles")

	# 🔲 Build object dictionary (correct format)
	var object_layer := {}
	object_layer["candelabra_0"] = {
		"type": "candelabra",
		"position": { "x": 45, "y": 44, "z": -1 },
		"state": { "is_lit": false }
	}

	# 💾 Save
	var z_level = str(from_egress["position"]["z"] - 1)
	print("🧱 Sample tile keys:", flat_tile_grid.keys().slice(0, 5))
	print("🧱 Sample tile value:", flat_tile_grid.get("0_0", {}))
	save_cellar_chunk(chunk_key, chunk_coords, chunk_size, biome_folder, z_level, flat_tile_grid, object_layer)


func save_cellar_chunk(chunk_key: String, chunk_coords: Vector2i, chunk_size: Vector2i, biome_folder: String, z_level: String, tile_grid: Dictionary, object_layer: Dictionary) -> void:
	var origin = chunk_coords * chunk_size

	var tile_json = {
		"chunk_coords": chunk_key.replace("chunk_", ""),
		"chunk_origin": { "x": origin.x, "y": origin.y },
		"tile_grid": tile_grid
	}

	var tile_path = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_key, biome_folder, z_level)
	print("🛠 Saving cellar at Z:", z_level, "with chunk key:", chunk_key)
	var object_path = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_key, biome_folder, z_level)

	LoadHandlerSingleton.save_json_file(tile_path, tile_json)
	LoadHandlerSingleton.save_json_file(object_path, { "objects": object_layer })


	print("💾 Cellar chunk saved:", chunk_key, "→ Z:", z_level)
	var confirm_check = LoadHandlerSingleton.load_json_file(tile_path)
	if confirm_check == null:
		print("❌ Could not load saved tile file! Path was:", tile_path)
	else:
		print("🧪 Confirmed written tile_grid size:", confirm_check.get("tile_grid", {}).size())

