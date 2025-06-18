extends Node

# 🔖 DEBUG GRASSLAND GENERATOR (biome-specific configuration)

# 🧭 Generation grid layout (used for blueprint loop)
const CHUNK_GRID_WIDTH := 3
const CHUNK_GRID_HEIGHT := 3
const CHUNK_SIZE := Vector2i(50, 50)  # All grassland chunks are uniform
const CENTER_CHUNK_COORD := Vector2i(1, 1)  # Used for prefab placement or spawn bias

# 🌊 Stream config
const STREAM_CHANCE := 0.8
var stream_should_exist := false
var stream_seed_x := -1

# 🛤️ Path config
const PATH_CHANCE := 0.8
var path_should_exist := false
var path_seed_y := -1

# 🌾 Decoration / clutter
const TREE_CLUSTER_CHANCE := 0.1
const BUSH_CHANCE := 0.05
const FLOWER_CLUSTER_CHANCE := 0.02
const PATH_STREAM_INTERSECT := true  # Enable bridges when path crosses stream

# 🧱 Tile rendering
const TILE_SIZE := 88  # Each tile is 88x88 pixels (visual, not logical)

const TEXTURE_GRASS := Constants.TILE_TEXTURES["grass"]
const TEXTURE_WATER := Constants.TILE_TEXTURES["water"]
const TEXTURE_PATH := Constants.TILE_TEXTURES["path"]
const TEXTURE_TREE := Constants.TILE_TEXTURES["tree"]
const TEXTURE_BUSH := Constants.TILE_TEXTURES["bush"]
const TEXTURE_FLOWERS := Constants.TILE_TEXTURES["flowers"]
const TEXTURE_BRIDGE := Constants.TILE_TEXTURES["bridge"]
const TEXTURE_HOLE := Constants.TILE_TEXTURES["hole"]

const TEXTURE_STONEFLOOR := Constants.TILE_TEXTURES["stonefloor"]
const TEXTURE_BED := Constants.TILE_TEXTURES["bed"]
const TEXTURE_CANDLELABRA := Constants.TILE_TEXTURES["candelabra"]
const TEXTURE_STAIRS := Constants.TILE_TEXTURES["stairs"]
const TEXTURE_WOODCHEST := Constants.TILE_TEXTURES["woodchest"]


# 🧠 Object spawn rules (tile → object compatibility)
const OBJECT_RULES = {
	TEXTURE_GRASS: [],
	TEXTURE_PATH: [TEXTURE_CANDLELABRA],
	TEXTURE_BRIDGE: [],
	TEXTURE_STONEFLOOR: [TEXTURE_BED, TEXTURE_CANDLELABRA, TEXTURE_WOODCHEST],
	TEXTURE_WATER: [],
	TEXTURE_TREE: [],
	TEXTURE_BUSH: [],
	TEXTURE_FLOWERS: [],
	TEXTURE_STAIRS: [TEXTURE_WOODCHEST],
}

# 🌀 Noise generator for stream curves
var noise := FastNoiseLite.new()

# 🌲 Tree location tracker (if needed later for spacing logic)
var tree_positions := {}


func _ready() -> void:
	randomize()  # Ensures randi/randf are not locked to the same sequence
	print("🛠 DEBUG: DebugGrassland _ready() is running...")

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
	print("🌿 Starting chunk-based DebugGrasslandGenerator.generate_chunked_map()...")

	# 🔄 STEP 0: Reset any lingering state from previous generation
	if LoadHandlerSingleton.has_method("reset_chunk_state"):
		LoadHandlerSingleton.reset_chunk_state()

	# 🔧 Reset local biome state variables
	tree_positions.clear()
	stream_should_exist = false
	stream_seed_x = -1
	path_should_exist = false
	path_seed_y = -1

	var biome := "grass"
	var chunked_tile_data := {}
	var chunked_object_data := {}
	var chunk_blueprints := {}

	const CHUNK_SIZE = Vector2i(50, 50)

	# 🧱 STEP 1: Define blueprint structure (uniform for grasslands)
	for cx in range(3):
		for cy in range(3):
			var chunk_key := "chunk_%d_%d" % [cx, cy]
			var origin := Vector2i(cx, cy) * CHUNK_SIZE
			chunk_blueprints[chunk_key] = {
				"origin": [origin.x, origin.y],
				"size": [CHUNK_SIZE.x, CHUNK_SIZE.y]
			}

	# ✅ STEP 1.5: Push blueprints BEFORE tile generation
	if LoadHandlerSingleton.has_method("set_chunk_blueprints"):
		LoadHandlerSingleton.set_chunk_blueprints(chunk_blueprints)

	# 🌊 STEP 2: Stream/path setup
	stream_should_exist = randf() < STREAM_CHANCE
	if stream_should_exist:
		stream_seed_x = randi_range(60, 140)
		print("🌊 Stream enabled → global stream X:", stream_seed_x)

	path_should_exist = randf() < PATH_CHANCE
	if path_should_exist:
		path_seed_y = randi_range(60, 140)
		print("🛤️ Path enabled → global path Y:", path_seed_y)

	# 🏰 STEP 3: Load prefabs
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

	# 🧠 STEP 4: Generate each chunk
	for chunk_key in chunk_blueprints.keys():
		var data = chunk_blueprints[chunk_key]
		var origin := Vector2i(data["origin"][0], data["origin"][1])
		var size = Vector2i(data["size"][0], data["size"][1])

		print("🧱 Generating", chunk_key, "at origin", origin, "size:", size)

		# ✅ STEP 4.1: Generate basic grid
		var result = generate_chunk(origin, size, chunk_key)
		var grid = result["grid"]

		# 🏗️ STEP 4.2: Place prefab BEFORE flattening
		if chunk_key == "chunk_1_1" and tower_prefab != null:
			print("🏗 Placing prefab in", chunk_key)
			place_structure(grid, tower_prefab, size)

		# 🧹 STEP 4.3: NOW flatten grid after prefab placement
		var flat_local_grid := {}
		for x in range(size.x):
			for y in range(size.y):
				var key := "%d_%d" % [x, y]
				flat_local_grid[key] = grid[x][y]

		# 🪑 STEP 4.4: Build object layer after prefab has modified tiles
		var object_layer := []
		for x in range(size.x):
			object_layer.append([])
			for y in range(size.y):
				object_layer[x].append(null)

		var placed_objects = ObjectPlacer.place_objects(grid, object_layer, biome)

		# 🗂️ STEP 4.5: Save chunk data
		chunked_tile_data[chunk_key] = {
			"chunk_coords": chunk_key.replace("chunk_", ""),
			"chunk_origin": { "x": origin.x, "y": origin.y },
			"tile_grid": flat_local_grid
		}
		chunked_object_data[chunk_key] = placed_objects

		# 🖼️ STEP 4.6: Render only center chunk
		if chunk_key == "chunk_1_1" and tile_container != null and is_instance_valid(tile_container):
			MapRenderer.render_map({ "tile_grid": flat_local_grid }, { "objects": object_layer }, tile_container, chunk_key)

	print("✅ All debug grassland chunks generated.")
	return [chunked_tile_data, chunked_object_data, chunk_blueprints, "gef"]

func generate_chunk(origin: Vector2i, size: Vector2i, chunk_key: String) -> Dictionary:
	var grid := []

	for x in range(size.x):
		grid.append([])
		for y in range(size.y):
			grid[x].append({
				"tile": "grass",
				"state": LoadHandlerSingleton.get_tile_state_for("grass")
			})
			
	var chunk_min_x = origin.x
	var chunk_max_x = origin.x + size.x - 1
	var chunk_min_y = origin.y
	var chunk_max_y = origin.y + size.y - 1

	# 🌊 Step 2: Stream generation
	if stream_should_exist and stream_seed_x >= chunk_min_x and stream_seed_x <= chunk_max_x:
		var local_stream_x = stream_seed_x - origin.x
		var stream_x_local = clamp(local_stream_x, 3, size.x - 4)

		for i in range(size.y):
			var global_y = origin.y + i
			var offset = int(noise.get_noise_2d(stream_seed_x, global_y * 0.2) * 3)
			stream_x_local = clamp(stream_x_local + offset, 3, size.x - 4)

			for j in range(-1, 2):
				var sx = clamp(stream_x_local + j, 0, size.x - 1)
				var sy = i
				grid[sx][sy] = {
					"tile": "water",
					"state": LoadHandlerSingleton.get_tile_state_for("water")
				}

	# 🛤️ Step 3: Path generation
	if path_should_exist and path_seed_y >= chunk_min_y and path_seed_y <= chunk_max_y:
		var local_path_y = path_seed_y - origin.y

		for x in range(size.x):
			for j in range(-1, 2):
				var py = clamp(local_path_y + j, 0, size.y - 1)
				grid[x][py] = {
					"tile": "path",
					"state": LoadHandlerSingleton.get_tile_state_for("path")
				}

	# 🌉 Step 4: Bridge conversion
	if PATH_STREAM_INTERSECT:
		for x in range(1, size.x - 1):
			for y in range(1, size.y - 1):
				if grid[x][y].get("tile", "") == "path" and (
					grid[x - 1][y].get("tile", "") == "water" or grid[x + 1][y].get("tile", "") == "water" or
					grid[x][y - 1].get("tile", "") == "water" or grid[x][y + 1].get("tile", "") == "water"
				):
					grid[x][y] = {
						"tile": "bridge",
						"state": LoadHandlerSingleton.get_tile_state_for("bridge")
					}

					for dx in range(-1, 2):
						for dy in range(-1, 2):
							var nx = x + dx
							var ny = y + dy
							if nx >= 0 and ny >= 0 and nx < size.x and ny < size.y:
								if grid[nx][ny].get("tile", "") == "path":
									grid[nx][ny] = {
										"tile": "bridge",
										"state": LoadHandlerSingleton.get_tile_state_for("bridge")
									}

	# 🌼 Step 5: Decor
	for x in range(size.x):
		for y in range(size.y):
			var tile_data = grid[x][y]
			if tile_data.get("tile") != "grass":
				continue

			var rand_val = randf()
			if rand_val < 0.02:
				grid[x][y] = { "tile": "tree", "state": LoadHandlerSingleton.get_tile_state_for("tree") }
			elif rand_val < 0.05:
				grid[x][y] = { "tile": "bush", "state": LoadHandlerSingleton.get_tile_state_for("bush") }
			elif rand_val < 0.08:
				grid[x][y] = { "tile": "flowers", "state": LoadHandlerSingleton.get_tile_state_for("flowers") }

	var flat_tile_grid := {}
	for x in range(size.x):
		for y in range(size.y):
			var key := "%d_%d" % [x, y]
			flat_tile_grid[key] = grid[x][y]

	return {
		"grid": grid
	}


func load_prefab_data():
	var path = "res://data/prefabs/grassland-prefabs.json"
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
