# res://scripts/localmapgenscripts/cavegen.gd
extends Node

func generate_cave_chunk(chunk_coords: Vector2i, biome_key: String, from_egress: Dictionary) -> void:
	var short_key = Constants.get_biome_chunk_key(biome_key)
	var biome_config = Constants.get_biome_config(short_key)

	match short_key:
		"gef":
			generate_grassland_cave_chunk(chunk_coords, biome_key, biome_config, from_egress)
		"fep":
			print("🌲 Forest cave gen not implemented yet.")
		"vses":
			print("🏚️ Slum cave gen not implemented yet.")
		_:
			print("⚠️ Unknown biome key for cave gen:", biome_key)


func generate_grassland_cave_chunk(chunk_coords: Vector2i, biome_key: String, biome_config: Dictionary, from_egress: Dictionary) -> void:
	#print("⛏️ ENTERED generate_cave_chunk for", chunk_coords)
	var biome_key_short = Constants.get_biome_chunk_key(biome_key)
	var chunk_key = "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	var chunk_size = biome_config.get("chunk_size", Vector2i(40, 40))
	var origin = LoadHandlerSingleton.get_chunk_origin_from_file(chunk_key, biome_key_short, -2)

	# Step 1: Clean dirt grid
	var result = cave_carving(chunk_coords, chunk_size)
	var grid = result[0]
	var rooms = result[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coords)
	
	add_cave_highway(grid, chunk_size, rng)

	stylize_cave(grid, chunk_size)
	
	# Step 2: Inject ladders from egress register (refactored)
	get_egress_for_caves_and_inject_to_chunk(chunk_key, chunk_coords, chunk_size, origin, biome_key_short, grid, rooms)

	# Step 3: Flatten and save
	var flat_tile_grid := {}
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			var key = "%d_%d" % [x, y]
			flat_tile_grid[key] = grid[x][y]

	save_cave_chunk(chunk_key, chunk_coords, chunk_size, biome_key_short, -2, flat_tile_grid, {})


func save_cave_chunk(
	chunk_key: String,
	chunk_coords: Vector2i,
	chunk_size: Vector2i,
	biome_key_short: String,
	z_level: int,
	tile_grid: Dictionary,
	object_layer: Dictionary
) -> void:
	var origin = chunk_coords * chunk_size

	var tile_json = {
		"chunk_coords": chunk_key.replace("chunk_", ""),
		"chunk_origin": { "x": origin.x, "y": origin.y },
		"tile_grid": tile_grid
	}

	var tile_path = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_key, biome_key_short, str(z_level))
	var object_path = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_key, biome_key_short, str(z_level))

	#print("🧭 Saving cave chunk at tile path:", tile_path)
	#print("🧭 Saving cave chunk at object path:", object_path)

	# 💾 Save tile JSON
	var tile_file = FileAccess.open(tile_path, FileAccess.WRITE)
	if tile_file:
		tile_file.store_string(JSON.stringify(tile_json, "\t"))
		tile_file.close()
		#print("💾 Saved cave tile chunk:", chunk_key, "→ Z:", z_level)
	else:
		print("⛔ Failed to open tile file for writing:", tile_path)

	# 💾 Save object JSON
	var obj_file = FileAccess.open(object_path, FileAccess.WRITE)
	if obj_file:
		obj_file.store_string(JSON.stringify({ "objects": object_layer }, "\t"))
		obj_file.close()
		#print("💾 Saved cave object chunk:", chunk_key, "→ Z:", z_level)
	else:
		print("⛔ Failed to open object file for writing:", object_path)


func get_egress_for_caves_and_inject_to_chunk(
	chunk_key: String,
	chunk_coords: Vector2i,
	chunk_size: Vector2i,
	origin: Vector2i,
	biome_key_short: String,
	grid: Array,
	rooms: Array,
) -> void:
	#print("⛄ SNOWBALL: Injecting egress for chunk_key:", chunk_key)
	#print("⛄ SNOWBALL: Chunk coords:", chunk_coords)
	#print("⛄ SNOWBALL: Chunk size:", chunk_size)
	#print("⛄ SNOWBALL: Origin used:", origin)
	
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coords)
	
	var biome_folder = Constants.get_chunk_folder_for_key(biome_key_short)
	#print("⛄ SNOWBALL: Biome folder resolved to:", biome_folder)

	var egress_register_path = LoadHandlerSingleton.get_egress_register_path(biome_folder)
	#print("⛄ SNOWBALL: Egress register path:", egress_register_path)

	var egress_register = LoadHandlerSingleton.load_json_file(egress_register_path)
	if typeof(egress_register) != TYPE_DICTIONARY:
		#print("⛄ SNOWBALL: ❌ Egress register failed to load or is not a Dictionary!")
		return

	var z_key = "%s|z-2" % chunk_key
	#print("⛄ SNOWBALL: Looking for z_key:", z_key)
	#print("⛄ SNOWBALL: Available keys in egress_register:", egress_register.keys())

	if not egress_register.has(z_key):
		#print("⛄ SNOWBALL: ❌ No egresses found for", z_key)
		return

	var egresses: Array = egress_register[z_key]

	for egress in egresses:
		#print("⛄ SNOWBALL: 🧩 Checking egress:", egress)

		var egress_type = egress.get("type", "")
		if egress_type != "short_ladder" and egress_type != "long_ladder":
			continue

		var pos = egress.get("position", {})
		var global_pos = Vector2i(pos.get("x", 0), pos.get("y", 0))
		var local_x = global_pos.x
		var local_y = global_pos.y
		var local_pos = Vector2i(local_x, local_y)

		#print("⛄ SNOWBALL: 🧭 Global pos:", global_pos, "→ Local pos:", local_pos)

		if local_x >= 0 and local_x < chunk_size.x and local_y >= 0 and local_y < chunk_size.y:
			carve_landing_pad(grid, local_pos, chunk_size, rooms, rng)
			stylize_cave(grid, chunk_size)

			grid[local_x][local_y] = {
				"tile": egress_type,
				"state": LoadHandlerSingleton.get_tile_state_for(egress_type),
				"manual_egress": true
			}
			#print("⛄ SNOWBALL: 🪜 Injected", egress_type, "at local", local_pos, "in", chunk_key)
		else:
			print("⛄ SNOWBALL: ⚠️ Egress out of bounds at", local_pos, "for", chunk_key)


func carve_landing_pad(
	grid: Array,
	center: Vector2i,
	chunk_size: Vector2i,
	rooms: Array,
	rng: RandomNumberGenerator
) -> void:
	
	# Step 1: Carve the immediate landing zone
	var radius = rng.randi_range(2, 3)
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var nx = center.x + dx
			var ny = center.y + dy
			if nx >= 0 and nx < chunk_size.x and ny >= 0 and ny < chunk_size.y:
				var dist = sqrt(dx * dx + dy * dy)
				if dist < radius * rng.randf_range(0.85, 1.15):
					if not grid[nx][ny].has("manual_egress"):
						grid[nx][ny] = {
							"tile": "dirt",
							"state": LoadHandlerSingleton.get_tile_state_for("dirt")
						}

	# Step 2: Try to path to the nearest room
	if rooms.size() > 0:
		var closest_room: Rect2 = rooms[0]
		var closest_dist = Vector2(center).distance_squared_to(closest_room.get_center())


		for room in rooms:
			var dist = Vector2(center).distance_squared_to(room.get_center())
			if dist < closest_dist:
				closest_room = room
				closest_dist = dist

		dig_corridor(grid, center, closest_room.get_center(), rng)
	else:
		# Step 3: No rooms? Carve a single dirt tile adjacent to the pad
		var offsets := [
			Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, 1), Vector2i(0, -1)
		]
		offsets.shuffle()

		for offset in offsets:
			var pos = center + offset
			if pos.x >= 0 and pos.x < chunk_size.x and pos.y >= 0 and pos.y < chunk_size.y:
				if not grid[pos.x][pos.y].has("manual_egress"):
					grid[pos.x][pos.y] = {
						"tile": "dirt",
						"state": LoadHandlerSingleton.get_tile_state_for("dirt")
					}
					break

func cave_carving(chunk_coords: Vector2i, chunk_size: Vector2i) -> Array:
	var grid := []
	for x in range(chunk_size.x):
		grid.append([])
		for y in range(chunk_size.y):
			grid[x].append({
				"tile": "cavewallside",
				"state": LoadHandlerSingleton.get_tile_state_for("cavewallside")
			})

	# Parameters
	var num_rooms := randi_range(3, 6)
	var rooms := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coords)  # deterministic per chunk

	# Create organic rooms
	for i in range(num_rooms):
		var w = rng.randi_range(6, 10)
		var h = rng.randi_range(5, 9)
		var x = rng.randi_range(1, chunk_size.x - w - 1)
		var y = rng.randi_range(1, chunk_size.y - h - 1)
		var room = Rect2(x, y, w, h)
		rooms.append(room)
		dig_room(grid, room)

	# Connect rooms with jittered, fat corridors
	for i in range(rooms.size() - 1):
		var r1 = rooms[i].get_center()
		var r2 = rooms[i + 1].get_center()
		dig_corridor(grid, r1, r2, rng)

	# Connect to neighboring chunks if they exist
	var offsets := {
		"top": Vector2i(0, -1),
		"bottom": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}

	for dir in offsets.keys():
		var neighbor_coords = chunk_coords + offsets[dir]
		if LoadHandlerSingleton.chunk_exists(neighbor_coords):
			carve_edge_connection(grid, chunk_size, dir)

	return [grid, rooms]


func dig_room(grid: Array, room: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(room.position))

	var cx = int(room.position.x + room.size.x / 2)
	var cy = int(room.position.y + room.size.y / 2)
	var rx = int(room.size.x / 2)
	var ry = int(room.size.y / 2)

	for x in range(int(room.position.x), int(room.position.x + room.size.x)):
		for y in range(int(room.position.y), int(room.position.y + room.size.y)):
			var nx = float(x - cx) / float(rx)
			var ny = float(y - cy) / float(ry)
			var dist = nx * nx + ny * ny
			var fuzz = rng.randf_range(0.85, 1.15)

			if dist * fuzz < 1.0:
				grid[x][y] = {
					"tile": "dirt",
					"state": LoadHandlerSingleton.get_tile_state_for("dirt")
				}

func dig_corridor(grid: Array, start: Vector2, end: Vector2, rng: RandomNumberGenerator) -> void:
	var x = int(start.x)
	var y = int(start.y)

	# Randomly choose corridor style
	var corridor_style = rng.randi_range(0, 1)  # 0 = tight, 1 = fat
	var max_radius = 0 if corridor_style == 0 else rng.randi_range(1, 2)

	while x != int(end.x) or y != int(end.y):
		for dx in range(-max_radius, max_radius + 1):
			for dy in range(-max_radius, max_radius + 1):
				var nx = x + dx
				var ny = y + dy
				if nx >= 0 and nx < grid.size() and ny >= 0 and ny < grid[0].size():
					grid[nx][ny] = {
						"tile": "dirt",
						"state": LoadHandlerSingleton.get_tile_state_for("dirt")
					}

		if x != int(end.x):
			x += 1 if end.x > x else -1
			if rng.randi_range(0, 3) == 0:
				y += rng.randi_range(-1, 1)
		elif y != int(end.y):
			y += 1 if end.y > y else -1
			if rng.randi_range(0, 3) == 0:
				x += rng.randi_range(-1, 1)

func carve_edge_connection(grid: Array, chunk_size: Vector2i, direction: String) -> void:
	var mid_x = chunk_size.x / 2
	var mid_y = chunk_size.y / 2
	var radius = 2

	match direction:
		"top":
			for dx in range(-radius, radius + 1):
				for dy in range(0, 2):
					var x = mid_x + dx
					var y = dy
					grid[x][y] = {
						"tile": "dirt",
						"state": LoadHandlerSingleton.get_tile_state_for("dirt")
					}
		"bottom":
			for dx in range(-radius, radius + 1):
				for dy in range(chunk_size.y - 2, chunk_size.y):
					var x = mid_x + dx
					var y = dy
					grid[x][y] = {
						"tile": "dirt",
						"state": LoadHandlerSingleton.get_tile_state_for("dirt")
					}
		"left":
			for dy in range(-radius, radius + 1):
				for dx in range(0, 2):
					var x = dx
					var y = mid_y + dy
					grid[x][y] = {
						"tile": "dirt",
						"state": LoadHandlerSingleton.get_tile_state_for("dirt")
					}
		"right":
			for dy in range(-radius, radius + 1):
				for dx in range(chunk_size.x - 2, chunk_size.x):
					var x = dx
					var y = mid_y + dy
					grid[x][y] = {
						"tile": "dirt",
						"state": LoadHandlerSingleton.get_tile_state_for("dirt")
					}

func stylize_cave(grid: Array, chunk_size: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec()  # Non-deterministic — tweak if needed

	for x in range(chunk_size.x):
		for y in range(chunk_size.y - 1):  # Avoid bottom out-of-bounds
			var current = grid[x][y]
			var below = grid[x][y + 1]

			# Convert wallside to wallbottom if dirt is directly beneath
			if current.get("tile") == "cavewallside" and below.get("tile") in ["dirt", "caverock"]:
				grid[x][y]["tile"] = "cavewallbottom"
				grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("cavewallbottom")

		# Optional: Apply caverock sparsely throughout column
		for y in range(chunk_size.y):
			var tile = grid[x][y]
			if tile.get("tile") == "dirt" and rng.randf() < 0.05:  # ~5% chance
				grid[x][y]["tile"] = "caverock"
				grid[x][y]["state"] = LoadHandlerSingleton.get_tile_state_for("caverock")

func add_cave_highway(grid: Array, chunk_size: Vector2i, rng: RandomNumberGenerator) -> void:
	var y = chunk_size.y / 2 + rng.randi_range(-2, 2)  # Slight vertical offset per chunk
	dig_corridor(grid, Vector2(0, y), Vector2(chunk_size.x - 1, y), rng)
