extends Node

# 🔖 DEBUG GRASSLAND GENERATOR (biome-specific configuration)

# 🧭 Generation grid layout (used for blueprint loop)
const CHUNK_GRID_WIDTH := 3
const CHUNK_GRID_HEIGHT := 3
const CHUNK_SIZE := Vector2i(40, 40)  # All grassland chunks are uniform
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
	TEXTURE_HOLE: [],
	TEXTURE_STAIRS: [TEXTURE_WOODCHEST],
}

# 🌀 Noise generator for stream curves
var noise := FastNoiseLite.new()

# 🌲 Tree location tracker (if needed later for spacing logic)
var tree_positions := {}

const NpcPoolData = preload("res://constants/npc_pool_data.gd")

var chunked_npc_data := {}


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
	var allowed_chunks = ["chunk_0_1", "chunk_1_1", "chunk_2_1"]
	var prefab_target_chunk = allowed_chunks[randi() % allowed_chunks.size()]
	print("🌿 Starting chunk-based DebugGrasslandGenerator.generate_chunked_map()...")

	# 🔄 STEP 0: Reset any lingering state from previous generation
	LoadHandlerSingleton.clear_egress_register_for_biome("grass")
	LoadHandlerSingleton.clear_prefab_register_for_biome("grass")
	LoadHandlerSingleton.clear_node_register_for_biome("grass")
	LoadHandlerSingleton.clear_storage_register_for_biome("grass")
	LoadHandlerSingleton.clear_vendor_register_for_biome("grass")

	
	if LoadHandlerSingleton.has_method("reset_chunk_state"):
		LoadHandlerSingleton.reset_chunk_state()

	# 🔧 Reset local biome state variables
	tree_positions.clear()
	stream_should_exist = false
	stream_seed_x = -1
	path_should_exist = false
	path_seed_y = -1

	var biome := "grass"
	var biome_key := Constants.get_biome_chunk_key(biome)   
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var npc_rules: Dictionary = NpcPoolData.NPC_POOLS.get(biome_folder, {})
	LoadHandlerSingleton.save_npc_pool(biome, npc_rules)
	var chunked_npc_data := {}
	var chunked_tile_data := {}
	var chunked_object_data := {}
	var chunk_blueprints := {}
	var placed_structure_map := {}
	
	
	const CHUNK_SIZE = Vector2i(40, 40)

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
		stream_seed_x = randi_range(20, 100)
		print("🌊 Stream enabled → global stream X:", stream_seed_x)

	path_should_exist = randf() < PATH_CHANCE
	if path_should_exist:
		path_seed_y = randi_range(20, 100)
		print("🛤️ Path enabled → global path Y:", path_seed_y)

	# 🏰 STEP 3: Load prefabs
	var biome_key_short = Constants.get_biome_chunk_key(biome)
	var tower_prefab := {}
	var prefab_group := {}
	var prefab_name_map := {}
	var prefab_variants := []

	var prefab_data_result = LoadHandlerSingleton.load_prefab_data(biome_key_short)
	if prefab_data_result.size() == 2:
		prefab_variants = prefab_data_result[0]
		prefab_name_map = prefab_data_result[1]

	if prefab_variants.size() > 0:
		prefab_group = prefab_variants[randi() % prefab_variants.size()]
		var floor_blueprint_name = prefab_group.get("floors", {}).get("0", "")
		if floor_blueprint_name != "" and prefab_name_map.has(floor_blueprint_name):
			tower_prefab = prefab_name_map[floor_blueprint_name]
			print("🏰 Chosen prefab:", prefab_group["name"], "→ floor 0:", floor_blueprint_name)

	# 🧠 STEP 4: Generate each chunk
	for chunk_key in chunk_blueprints.keys():
		var data = chunk_blueprints[chunk_key]
		var origin := Vector2i(data["origin"][0], data["origin"][1])
		var size = Vector2i(data["size"][0], data["size"][1])

		#print("🧱 Generating", chunk_key, "at origin", origin, "size:", size)

		var result = generate_chunk(origin, size, chunk_key)
		var grid = result["grid"]

		# 🏗️ STEP 4.2: Place prefab BEFORE flattening
		if chunk_key == prefab_target_chunk and tower_prefab != null:
			print("🏗 Placing prefab in", chunk_key)
			var placed_at := place_structure(grid, tower_prefab, size, chunk_key)
			placed_structure_map[chunk_key] = prefab_group["name"]

			if placed_at != Vector2i(-1, -1):
				var global_coords := placed_at + origin
				LoadHandlerSingleton.register_prefab_data_for_chunk(
					"grassland_explore_fields",
					chunk_key,
					prefab_group["name"],
					global_coords,
					0
				)

		# Inject cave hole tile (after prefab, before object layer is created)
		if chunk_key == "chunk_1_1":
			var valid := []
			for x in range(size.x):
				for y in range(size.y):
					if grid[x][y].get("tile", "") == "grass":
						valid.append(Vector2i(x, y))

			if valid.size() > 0:
				var pos: Vector2i = valid[randi() % valid.size()]
				grid[pos.x][pos.y] = {
					"tile": "hole",
					"state": LoadHandlerSingleton.get_tile_state_for("hole"),
					"manual_egress": true  # 🚫 Prevent double registration
				}

				var target_z = Constants.EGRESS_TYPES["hole"]

				# 👇 USE LOCAL COORDS — like stone stairs
				LoadHandlerSingleton.register_egress_point({
					"type": "hole",
					"target_z": target_z,
					"position": { "x": pos.x, "y": pos.y, "z": 0 },
					"chunk": chunk_key,
					"biome": biome
				})
				print("🕳️ Cave hole set at (local):", pos)
			else:
				print("⚠️ Could not place hole in", chunk_key)

		# 🧹 STEP 4.3: Flatten grid
		var flat_tile_grid := {}
		for x in range(size.x):
			for y in range(size.y):
				var key := "%d_%d" % [x, y]
				flat_tile_grid[key] = grid[x][y]

		# 🪑 STEP 4.4: Build object layer
		var object_layer := []
		for x in range(size.x):
			object_layer.append([])
			for y in range(size.y):
				object_layer[x].append(null)

		var placed_objects = ObjectPlacer.place_objects(grid, object_layer, biome)
		
		# 🧍 Place NPCs using new NPCPlacer
		var placed_npcs = MapNpcPlacer.place_npcs(grid, placed_objects, chunk_key, origin, npc_rules)
		print("🐾 NPC placement rules for chunk", chunk_key, ":", npc_rules)
		print("🐾 Placed NPCs count:", placed_npcs.size(), "for chunk", chunk_key)
		chunked_npc_data[chunk_key] = { "npcs": placed_npcs }
		LoadHandlerSingleton.chunked_npc_data[chunk_key] = { "npcs": placed_npcs }  # 👈 Add this line
		LoadHandlerSingleton.save_chunked_npc_chunk(chunk_key, { "npcs": placed_npcs })

		# 🔍 TILE-based egress
		for key in flat_tile_grid.keys():
			var tile_data = flat_tile_grid[key]
			if tile_data.get("manual_egress", false):
				continue  # 🔒 Skip manually registered egress tiles

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
						"position": { "x": global_x, "y": global_y, "z": 0 },
						"chunk": chunk_key,
						"biome": biome
					})

		# 🔍 OBJECT-based egress
		for obj_id in placed_objects.keys():
			var obj = placed_objects[obj_id]
			var obj_type = obj.get("type", "")
			if Constants.EGRESS_TYPES.has(obj_type):
				var pos = obj.get("position", {})
				if pos.has("x") and pos.has("y"):
					var global_pos = Vector2i(pos["x"], pos["y"]) + origin
					var target_z = Constants.EGRESS_TYPES[obj_type]
					LoadHandlerSingleton.add_egress_point({
						"type": obj_type,
						"target_z": target_z,
						"position": { "x": global_pos.x, "y": global_pos.y, "z": 0 },
						"chunk": chunk_key,
						"biome": biome
					})

		chunked_tile_data[chunk_key] = {
			"chunk_coords": chunk_key.replace("chunk_", ""),
			"chunk_origin": { "x": origin.x, "y": origin.y },
			"tile_grid": flat_tile_grid
		}
		chunked_object_data[chunk_key] = placed_objects

		var z_level = "0"
		var tile_path = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_key, biome_key, z_level)
		var object_path = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_key, biome_key, z_level)
		var npc_path = LoadHandlerSingleton.get_chunked_npc_chunk_path(chunk_key, biome_key, z_level)

		LoadHandlerSingleton.save_json_file(tile_path, chunked_tile_data[chunk_key])
		LoadHandlerSingleton.save_json_file(object_path, placed_objects)
		LoadHandlerSingleton.save_json_file(npc_path, { "npcs": placed_npcs })



		if chunk_key == "chunk_1_1" and tile_container != null and is_instance_valid(tile_container):
			MapRenderer.render_map({ "tile_grid": flat_tile_grid }, { "objects": object_layer }, { "npcs": placed_npcs }, tile_container, chunk_key)

	print("✅ All debug grassland chunks generated.")
	var placement = LoadHandlerSingleton.load_temp_placement()
	if not placement.has("local_map"):
		placement["local_map"] = {}

	placement["local_map"]["biome_key"] = biome_folder
	LoadHandlerSingleton.save_temp_placement(placement)
	print("📍 Egress points collected:", LoadHandlerSingleton.get_egress_points())
	ZLevelManager.process_z_down_egresses_for_biome("grassland_explore_fields")
	return [chunked_tile_data, chunked_object_data, chunk_blueprints, biome_folder, chunked_npc_data]


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


func place_structure(grid: Array, prefab: Dictionary, chunk_size: Vector2i, chunk_key: String) -> Vector2i:
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

						# 🧭 Register prefab-based egress points (like stairs)
						if Constants.EGRESS_TYPES.has(tile_name):
							var global_pos = Vector3(gx, gy, 0)
							LoadHandlerSingleton.register_egress_point({
								"type": tile_name,
								"target_z": Constants.EGRESS_TYPES[tile_name],
								"position": { "x": global_pos.x, "y": global_pos.y, "z": global_pos.z },
								"chunk": chunk_key,
								"biome": "grass"
							})

				structure_placed = true
				return Vector2i(x, y)  # ✅ Return the top-left coords
		if structure_placed:
			break

	print("❌ Could not place prefab anywhere — even brute force failed.")
	return Vector2i(-1, -1)  # ❌ Signal that nothing was placed
