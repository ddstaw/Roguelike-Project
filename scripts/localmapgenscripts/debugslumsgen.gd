extends Node

# 🔖 Village Slums GENERATOR (biome-specific configuration)

# 🧭 Generation grid layout (used for blueprint loop)
const CHUNK_GRID_WIDTH := 3
const CHUNK_GRID_HEIGHT := 3
const CENTER_CHUNK_COORD := Vector2i(1, 0)  # Used for prefab placement or spawn bias


# 🧱 Tile rendering
const TILE_SIZE := 88  # Each tile is 88x88 pixels (visual, not logical)

const TEXTURE_SLUM_SIDEWALK_FLOOR := Constants.TILE_TEXTURES["slum_sidewalk_floor"]
const TEXTURE_SLUM_ROAD_FLOOR := Constants.TILE_TEXTURES["slum_road_floor"]
const TEXTURE_SLUM_BRICK_FLOOR := Constants.TILE_TEXTURES["slum_brick_floor"]
const TEXTURE_SLUM_STONE_FLOOR := Constants.TILE_TEXTURES["slum_stone_floor"]
const TEXTURE_BED := Constants.TILE_TEXTURES["bed"]
const TEXTURE_CANDLELABRA := Constants.TILE_TEXTURES["candelabra"]
const TEXTURE_SEWER_DOOR := Constants.TILE_TEXTURES["sewer_door"]
const TEXTURE_STONEFLOOR := Constants.TILE_TEXTURES["stonefloor"]
const TEXTURE_WOODCHEST := Constants.TILE_TEXTURES["woodchest"]
const TEXTURE_SLUM_STREETLAMP := Constants.TILE_TEXTURES["slum_streetlamp"]
const TEXTURE_SLUM_BRICK_FLOOR_STAIRS_UP := Constants.TILE_TEXTURES["slum_brick_floor_stairs_up"]
const TEXTURE_SLUM_BRICK_FLOOR_STAIRS_DOWN := Constants.TILE_TEXTURES["slum_brick_floor_stairs_down"]
const TEXTURE_SLUM_TRASH := Constants.TILE_TEXTURES["slum_trash"]


# 🧠 Object spawn rules (tile → object compatibility)
const OBJECT_RULES = {
	TEXTURE_SLUM_SIDEWALK_FLOOR: [TEXTURE_SLUM_STREETLAMP, TEXTURE_SLUM_TRASH],
	TEXTURE_SLUM_ROAD_FLOOR: [TEXTURE_SEWER_DOOR],
	TEXTURE_SLUM_STONE_FLOOR: [TEXTURE_SEWER_DOOR, TEXTURE_SLUM_TRASH],
	TEXTURE_SLUM_BRICK_FLOOR: [TEXTURE_BED, TEXTURE_CANDLELABRA, TEXTURE_WOODCHEST],
}


func _ready() -> void:
	randomize()  # Ensures randi/randf are not locked to the same sequence
	print("🛠 DEBUG: village slum _ready() is running...")

	await get_tree().process_frame

	var tile_container = null
	var attempts = 0
	var max_attempts = 60  # Allow 60 frames instead of 20

	# Try to find TileContainer
	while tile_container == null and attempts < max_attempts:
		await get_tree().process_frame
		tile_container = get_parent().get_node_or_null("TileContainer")
		attempts += 1

	if tile_container == null:
		print("⚠️ WARNING: TileContainer STILL NOT FOUND after", attempts, "retries!")
		return

	print("✅ SUCCESS: TileContainer found after", attempts, "retries.")

	# Delay one more frame to ensure LocalMap is fully initialized
	await get_tree().process_frame

	if is_instance_valid(tile_container):
		print("⏳ Delayed chunk-based generation start...")
		await generate_chunked_map(tile_container)
	else:
		print("❌ Still no valid tile_container after delay.")


func _on_tile_container_ready(container):
	print("✅ Signal received. Starting chunk-based map generation...")
	await generate_chunked_map(container)

func generate_chunked_map(tile_container: Node) -> Array:
	print("🌲 Starting chunk-based village slum generate_chunked_map()...")

	var biome := "village-slums"
	var chunked_tile_data := {}
	var chunked_object_data := {}
	var chunk_blueprints := {}

	# 🔄 Reset state
	if LoadHandlerSingleton.has_method("reset_chunk_state"):
		LoadHandlerSingleton.reset_chunk_state()


	# 🌆 Define blueprint structure for Village Slums (3 chunks wide)

	chunk_blueprints["chunk_0_0"] = { "origin": [0, 0], "size": [39, 48] }
	chunk_blueprints["chunk_1_0"] = { "origin": [39, 0], "size": [36, 48] }
	chunk_blueprints["chunk_2_0"] = { "origin": [75, 0], "size": [39, 48] }

	# 📦 Push blueprints for later use
	if LoadHandlerSingleton.has_method("set_chunk_blueprints"):
		LoadHandlerSingleton.set_chunk_blueprints(chunk_blueprints)

	# 🏰 Prefab loading
	var tower_prefab := {}
	var prefabs = load_prefab_data()
	if prefabs.size() > 0:
		var tower_variants := []
		for p in prefabs:
			if "stone_tower" in p["name"]:
				tower_variants.append(p)
		if tower_variants.size() > 0:
			tower_prefab = tower_variants[randi() % tower_variants.size()]
			print("🏰 Chosen prefab:", tower_prefab["name"])

	# 🔁 Loop each chunk
	for chunk_key in chunk_blueprints.keys():
		var data = chunk_blueprints[chunk_key]
		var origin := Vector2i(data["origin"][0], data["origin"][1])
		var size = Vector2i(data["size"][0], data["size"][1])

		print("🧱 Generating", chunk_key, "at origin", origin)
		var result = generate_chunk(origin, size, chunk_key)
		var grid = result["grid"]

		# 🏗️ Structure placement BEFORE flattening
		if prefabs.size() > 0:
			var prefab_slots = []

			if chunk_key == "chunk_0_0":
				print("🏗 Placing prefabs into chunk_0_0 plots...")
				prefab_slots = [
					{ "origin": Vector2i(7, 7), "facing": "upper" },
					{ "origin": Vector2i(24, 7), "facing": "upper" },
					{ "origin": Vector2i(7, 25), "facing": "lower" },
					{ "origin": Vector2i(24, 25), "facing": "lower" }
				]

			elif chunk_key == "chunk_1_0":
				print("🏗 Placing prefabs into chunk_1_0 plots...")
				prefab_slots = [
					{ "origin": Vector2i(2, 7), "facing": "upper" },
					{ "origin": Vector2i(19, 7), "facing": "upper" },
					{ "origin": Vector2i(2, 25), "facing": "lower" },
					{ "origin": Vector2i(19, 25), "facing": "lower" }
				]

			elif chunk_key == "chunk_2_0":
				print("🏗 Placing prefabs into chunk_2_0 plots...")
				prefab_slots = [
					{ "origin": Vector2i(0, 7), "facing": "upper" },
					{ "origin": Vector2i(17, 7), "facing": "upper" },
					{ "origin": Vector2i(0, 25), "facing": "lower" },
					{ "origin": Vector2i(17, 25), "facing": "lower" }
				]

			# 🚀 Universal prefab placement (for any chunk that defines slots)
			for slot in prefab_slots:
				var candidates = []
				for p in prefabs:
					if slot["facing"] == "upper" and "upper" in p["name"]:
						candidates.append(p)
					elif slot["facing"] == "lower" and "lower" in p["name"]:
						candidates.append(p)

				if candidates.size() > 0:
					var selected_prefab = candidates[randi() % candidates.size()]
					print("🏘️ Placing prefab:", selected_prefab["name"], "at", slot["origin"])
					place_structure_at(grid, slot["origin"], selected_prefab)
				else:
					print("⚠️ No matching prefab found for slot at", slot["origin"])

				
		# 🧹 Now flatten updated grid
		var flat_tile_grid := {}
		for x in range(size.x):
			for y in range(size.y):
				var key := "%d_%d" % [x, y]
				flat_tile_grid[key] = grid[x][y]

		# 🪑 Object layer after prefab
		var object_layer := []
		for x in range(size.x):
			object_layer.append([])
			for y in range(size.y):
				object_layer[x].append(null)

		var placed_objects = ObjectPlacer.place_objects(grid, object_layer, biome, {}, 1, chunk_key)


		# 💾 Save
		chunked_tile_data[chunk_key] = {
			"chunk_coords": chunk_key.replace("chunk_", ""),
			"chunk_origin": { "x": origin.x, "y": origin.y },
			"tile_grid": flat_tile_grid
		}
		chunked_object_data[chunk_key] = placed_objects

		# 🎨 Preview render (chunk 0_0)
		if chunk_key == "chunk_0_0" and tile_container != null and is_instance_valid(tile_container):
			MapRenderer.render_map({ "tile_grid": flat_tile_grid }, { "objects": object_layer }, tile_container, chunk_key)

	print("✅ All slum chunks generated.")
	return [chunked_tile_data, chunked_object_data, chunk_blueprints, "vses"]


func generate_chunk(origin: Vector2i, size: Vector2i, chunk_key: String) -> Dictionary:
	var grid := []

	# Initialize the grid
	for x in range(size.x):
		grid.append([])
		for y in range(size.y):

			var tile_name := "slum_brick_floor"  # Default prefab filler

			# ---- Horizontal (north-south) zones ----

			# Top border sidewalk
			if y in [0, 1]:
				tile_name = "slum_sidewalk_floor"
			# Top road
			elif y in [2, 3, 4]:
				tile_name = "slum_road_floor"
			# Top inner sidewalk
			elif y in [5, 6]:
				tile_name = "slum_sidewalk_floor"
			# Bottom inner sidewalk
			elif y in [41, 42]:
				tile_name = "slum_sidewalk_floor"
			# Bottom road
			elif y in [43, 44, 45]:
				tile_name = "slum_road_floor"
			# Bottom border sidewalk
			elif y in [46, 47]:
				tile_name = "slum_sidewalk_floor"

			# ---- Vertical (east-west) zones ----

			# Left (west) sidewalks and roads (chunk 0_0 only)
			if chunk_key == "chunk_0_0":
				if x in [0, 1]:
					tile_name = "slum_sidewalk_floor"
				elif x in [2, 3, 4]:
					tile_name = "slum_road_floor"
				elif x in [5, 6]:
					tile_name = "slum_sidewalk_floor"

			# Right (east) sidewalks and roads (chunk 2_0 only)
			if chunk_key == "chunk_2_0":
				if x in [size.x - 2, size.x - 1]:
					tile_name = "slum_sidewalk_floor"
				elif x in [size.x - 5, size.x - 4, size.x - 3]:
					tile_name = "slum_road_floor"
				elif x in [size.x - 7, size.x - 6]:
					tile_name = "slum_sidewalk_floor"

			grid[x].append({
				"tile": tile_name,
				"state": LoadHandlerSingleton.get_tile_state_for(tile_name)
			})

	# ---- Second pass: place alleys ----
	for x in range(size.x):
		for y in range(size.y):
			var tile_data: Dictionary = grid[x][y]
			var existing_tile: String = tile_data["tile"]

			# Only place alleys inside prefab brick floors
			if existing_tile != "slum_brick_floor":
				continue

			# Horizontal alley (splitting prefab rows)
			if y in [23, 24]:
				grid[x][y]["tile"] = "slum_stone_floor"
				grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_stone_floor")

			# Vertical alleys (splitting prefab columns)
			if chunk_key == "chunk_0_0":
				if x in [22, 23]:
					grid[x][y]["tile"] = "slum_stone_floor"
					grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_stone_floor")
			elif chunk_key == "chunk_1_0":
				if x in [17, 18]:
					grid[x][y]["tile"] = "slum_stone_floor"
					grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_stone_floor")
				elif x in [0, 1]:
					grid[x][y]["tile"] = "slum_stone_floor"
					grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_stone_floor")
				elif x in [34, 35]:
					grid[x][y]["tile"] = "slum_stone_floor"
					grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_stone_floor")
			elif chunk_key == "chunk_2_0":
				if x in [15, 16]:
					grid[x][y]["tile"] = "slum_stone_floor"
					grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_stone_floor")

	# ---- Final fix: patch small road intersections in chunk_0_0 ----
	if chunk_key == "chunk_0_0":
		var road_coords = [
			Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
			Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4),
			Vector2i(5, 2), Vector2i(6, 2),
			Vector2i(5, 3), Vector2i(6, 3),
			Vector2i(5, 4), Vector2i(6, 4),
			Vector2i(0, 45), Vector2i(0, 44), Vector2i(0, 43),
			Vector2i(1, 45), Vector2i(1, 44), Vector2i(1, 43),
			Vector2i(5, 45), Vector2i(6, 45),
			Vector2i(5, 44), Vector2i(6, 44),
			Vector2i(5, 43), Vector2i(6, 43)

		]
			
		for coord in road_coords:
			var x = coord.x
			var y = coord.y
			if x >= 0 and y >= 0 and x < size.x and y < size.y:
				grid[x][y]["tile"] = "slum_road_floor"
				grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_road_floor")

	elif chunk_key == "chunk_2_0":
		var road_coords = [
			Vector2i(38, 2), Vector2i(38, 3), Vector2i(38, 4),
			Vector2i(37, 2), Vector2i(37, 3), Vector2i(37, 4),
			Vector2i(32, 2), Vector2i(33, 2),
			Vector2i(32, 3), Vector2i(33, 3),
			Vector2i(32, 4), Vector2i(33, 4),
			Vector2i(38, 45), Vector2i(38, 44), Vector2i(38, 43),
			Vector2i(37, 45), Vector2i(37, 44), Vector2i(37, 43),
			Vector2i(32, 45), Vector2i(33, 45),
			Vector2i(32, 44), Vector2i(33, 44),
			Vector2i(32, 43), Vector2i(33, 43)

		]
			
		for coord in road_coords:
			var x = coord.x
			var y = coord.y
			if x >= 0 and y >= 0 and x < size.x and y < size.y:
				grid[x][y]["tile"] = "slum_road_floor"
				grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("slum_road_floor")


		# TODO: You could do a similar patch for bottom left later if you want


	# ✅ Correct flattening: LOCAL to chunk only
	var flat_local_grid := {}
	for x in range(size.x):
		for y in range(size.y):
			var key := "%d_%d" % [x, y]
			flat_local_grid[key] = grid[x][y]

	return {
		"grid": grid,
		"flat_grid": flat_local_grid
	}


func load_prefab_data():
	var path = "res://data/prefabs/village-slums-prefabs.json"
	if not FileAccess.file_exists(path):
		print("❌ ERROR: Structure prefab file not found!")
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed.has("prefabs"):
		print("❌ ERROR: Structure prefab file failed to parse.")
		return []
	print("📦 Prefab data loaded:", parsed["prefabs"].size())
	return parsed["prefabs"]

func place_structure(grid: Array, prefab: Dictionary, chunk_size: Vector2i) -> void:
	print("🏗 ENTERED place_structure() for:", prefab["name"])

	var structure_width: int = prefab["width"]
	var structure_height: int = prefab["height"]
	var tiles: Array = prefab["tiles"]
	var legend: Dictionary = prefab.get("legend", {})

	var structure_placed := false

	# ✅ Brute force search across actual chunk size
	for x in range(chunk_size.x - structure_width):
		for y in range(chunk_size.y - structure_height):
			var valid := true

			# ✅ Check if this area is clean
			for sx in range(structure_width):
				for sy in range(structure_height):
					var tx := x + sx
					var ty := y + sy

					if tx >= chunk_size.x or ty >= chunk_size.y:
						valid = false
						break

					var tile_data: Dictionary = grid[tx][ty]
					var tile_name: String = tile_data.get("tile", "")

					if tile_name == "water" or tile_name == "bridge":
						valid = false
						break

					if tile_data.get("state", {}).size() > 0:
						valid = false
						break

				if not valid:
					break

			if valid:
				print("✅ BRUTEFORCE: Structure placed at:", Vector2(x, y))

				for sy in range(structure_height):
					if sy >= tiles.size():
						print("⚠️ Not enough rows in prefab tiles at sy =", sy)
						continue

					var row: String = tiles[sy]

					for sx in range(structure_width):
						if sx >= row.length():
							print("⚠️ Row too short at sy =", sy, "| Row:", row)
							continue

						var symbol := row[sx]
						var texture_path: String = legend.get(symbol, null)

						if texture_path == null:
							print("⚠️ Unknown symbol:", symbol, "→", sx, sy)
							continue

						var tex = load(texture_path)
						if tex == null:
							print("❌ Could not load texture:", texture_path)
							continue

						var gx := x + sx
						var gy := y + sy
						var tile_name: String = Constants.TEXTURE_TO_NAME.get(tex, "unknown")

						grid[gx][gy] = {
							"tile": tile_name,
							"state": LoadHandlerSingleton.get_tile_state_for(tile_name)
						}

				structure_placed = true
				break
		if structure_placed:
			break

	if not structure_placed:
		print("❌ Could not place prefab anywhere — even brute force failed.")

func place_structure_at(grid: Array, slot: Vector2i, prefab: Dictionary) -> void:

	var structure_width: int = prefab["width"]
	var structure_height: int = prefab["height"]
	var tiles: Array = prefab["tiles"]
	var legend: Dictionary = prefab.get("legend", {})

	for sy in range(structure_height):
		if sy >= tiles.size():
			continue

		var row: String = tiles[sy]

		for sx in range(structure_width):
			if sx >= row.length():
				continue

			var symbol := row[sx]
			var texture_path: String = legend.get(symbol, null)

			if texture_path == null:
				continue

			var tex = load(texture_path)
			if tex == null:
				continue

			var gx := slot.x + sx
			var gy := slot.y + sy

			# Safety check: Don't overflow grid bounds
			if gx >= 0 and gy >= 0 and gx < grid.size() and gy < grid[gx].size():
				var tile_name: String = Constants.TEXTURE_TO_NAME.get(tex, "unknown")
				grid[gx][gy] = {
					"tile": tile_name,
					"state": LoadHandlerSingleton.get_tile_state_for(tile_name)
				}
