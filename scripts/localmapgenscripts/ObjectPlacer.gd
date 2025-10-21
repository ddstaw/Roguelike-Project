extends Node
# res://scripts/localmapgenscripts/ObjectPlacer.gd

class_name MapObjectPlacer

const OBJECT_RULES_PATH = "res://scripts/localmapgenscripts/object_placement_rules/"

var object_rules = {}  # Stores the biome-specific rules

# ✅ Loads placement rules for a given biome
func load_placement_rules(biome: String):
	var file_path = OBJECT_RULES_PATH + biome + ".json"
	if not FileAccess.file_exists(file_path):
		print("❌ ERROR: Biome object placement file missing:", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()

	object_rules = JSON.parse_string(json_data)
	if object_rules == null:
		print("❌ ERROR: Failed to parse JSON in", file_path)
		object_rules = {}  # Prevent crashes with a fallback

	#print("✅ Loaded object placement rules for biome:", biome)

func place_objects(grid, object_layer, biome_name := "default", objects := {}, start_id := 1, chunk_id := "") -> Dictionary:
	#print("🔧 Placing world objects for biome:", biome_name, "| chunk_id:", chunk_id)

	var rules = load_object_rules(biome_name)
	if rules == null:
		print("❌ ERROR: Could not load object placement rules for", biome_name)
		return objects

	match biome_name:
		"village-slums":
			return _place_village_slums_objects(grid, object_layer, rules, objects, start_id, chunk_id)
		"grass", "grassland", "debug_grass", "debug_grassland":
			return _place_grassland_objects(grid, object_layer, objects, start_id)
		_:
			print("⚠️ No object placement logic defined for biome:", biome_name)
			return objects

			
# ✅ Loads object placement rules from JSON
func load_object_rules(biome_name):
	var path = OBJECT_RULES_PATH + biome_name + ".json"
	if not FileAccess.file_exists(path):
		print("❌ ERROR: object placement rules file missing for biome:", biome_name)
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	var parsed_data = JSON.parse_string(json_text)
	
	if parsed_data == null:
		print("❌ ERROR: Failed to parse object rules JSON:", path)
		return null

	#print("✅ load_object_rules // Loaded object placement rules for biome:", biome_name)
	return parsed_data

# ✅ Checks if a position is adjacent to a cluster
func _is_adjacent(cluster, x, y):
	for pos in cluster:
		if abs(pos.x - x) <= 1 and abs(pos.y - y) <= 1:
			return true
	return false

func _place_grassland_objects(grid, object_layer, objects := {}, start_id := 1) -> Dictionary:
	var object_id = start_id
	var stone_floor_clusters = []
	var path_positions = []
	var grass_positions = []

	# Gather terrain positions
	for x in range(grid.size()):
		for y in range(grid[x].size()):
			var base_tile = grid[x][y]
			var tile_name = base_tile.get("tile", "")

			match tile_name:
				"stonefloor":
					var added = false
					for cluster in stone_floor_clusters:
						if _is_adjacent(cluster, x, y):
							cluster.append(Vector2(x, y))
							added = true
							break
					if not added:
						stone_floor_clusters.append([Vector2(x, y)])
				"path":
					path_positions.append(Vector2(x, y))
				"grass", "bush":
					grass_positions.append(Vector2(x, y))

	# Place stonefloor cluster objects
	for cluster in stone_floor_clusters:
		cluster.shuffle()
		var placed_bed = false
		var placed_chest = false
		var candelabra_count = 0

		for pos in cluster:
			var x = int(pos.x)
			var y = int(pos.y)

			if not placed_bed:
				object_layer[x][y] = Constants.get_object_texture("bed")
				objects["bed_%d" % object_id] = {
					"type": "bed", "position": { "x": x, "y": y, "z": 0 }
				}
				placed_bed = true
			elif not placed_chest:
				object_layer[x][y] = Constants.get_object_texture("woodchest")
				objects["chest_%d" % object_id] = {
					"type": "woodchest", "position": { "x": x, "y": y, "z": 0 }
				}
				placed_chest = true
			elif candelabra_count < 2 and randf() < 0.5:
				object_layer[x][y] = Constants.get_object_texture("candelabra")
				objects["candelabra_%d" % object_id] = {
					"type": "candelabra",
					"position": { "x": x, "y": y, "z": 0 },
					"state": { "is_lit": false }
				}
				candelabra_count += 1

			object_id += 1

	# Place bridge-edge candelabras
	var grass_set = {}
	for pos in grass_positions:
		grass_set[pos] = true

	for x in range(grid.size()):
		for y in range(grid[x].size()):
			if grid[x][y].get("tile", "") == "bridge":
				for pos in [Vector2(x, y - 1), Vector2(x, y + 1)]:
					if grass_set.has(pos):
						object_layer[int(pos.x)][int(pos.y)] = Constants.get_object_texture("candelabra")
						objects["candelabra_%d" % object_id] = {
							"type": "candelabra",
							"position": { "x": int(pos.x), "y": int(pos.y), "z": 0 },
							"state": { "is_lit": true }
						}
						object_id += 1

	# Rare grass chest
	if grass_positions.size() > 0:
		var rare_pos = grass_positions[randi() % grass_positions.size()]
		var x = int(rare_pos.x)
		var y = int(rare_pos.y)
		object_layer[x][y] = Constants.get_object_texture("woodchest")
		objects["chest_%d" % object_id] = {
			"type": "woodchest", "position": { "x": x, "y": y, "z": 0 }
		}
		object_id += 1

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var nx = x + dx
				var ny = y + dy
				if nx >= 0 and ny >= 0 and nx < grid.size() and ny < grid[0].size() and randf() < 0.5:
					object_layer[nx][ny] = Constants.get_object_texture("candelabra")
					objects["candelabra_%d" % object_id] = {
						"type": "candelabra",
						"position": { "x": nx, "y": ny, "z": 0 },
						"state": { "is_lit": false }
					}
					object_id += 1

	return objects
	
func _place_village_slums_objects(grid, object_layer, rules: Dictionary, objects := {}, start_id := 1, chunk_id := "") -> Dictionary:
	var object_id = start_id

	var lamp_coords = Constants.SLUM_STREETLAMP_COORDS.get(chunk_id, [])

	for pos in lamp_coords:
		var x = pos.x
		var y = pos.y
		object_layer[x][y] = Constants.get_object_texture("slum_streetlamp")
		var is_lit := randf() < 0.5  # 50% chance to be ON (lit)
		objects["lamp_%d" % object_id] = {
			"type": "slum_streetlamp",
			"position": { "x": x, "y": y, "z": 0 },
			"state": { "is_lit": is_lit }
		}
		object_id += 1

	return objects
