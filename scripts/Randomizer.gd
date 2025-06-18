extends Node

# Function to generate random grid data
func randomize_grid() -> Array:
	var new_grid_data = []

	# Generate data for a 12x12 grid
	var tiles = []
	var names = []
	var biomes = []

	for y in range(12):
		var row_tiles = []
		var row_names = []
		var row_biomes = []
		
		for x in range(12):
			var tile_type = get_random_tile()
			row_tiles.append(tile_type)
			row_names.append("cell_%d_%d" % [y, x])
			row_biomes.append(get_random_biome(tile_type))
		
		tiles.append(row_tiles)
		names.append(row_names)
		biomes.append(row_biomes)
	
	new_grid_data.append({
		"tiles": tiles,
		"names": names,
		"biomes": biomes
	})

	return new_grid_data

# Function to get a random tile (example)
func get_random_tile() -> String:
	var tile_paths = [
		"res://assets/graphics/36x36-forest.png",
		"res://assets/graphics/36x36-mountains.png",
		"res://assets/graphics/36x36-grass.png",
		"res://assets/graphics/36x36-ocean.png"
	]
	return tile_paths[randi() % tile_paths.size()]

# Function to get a biome based on the tile type (example)
func get_random_biome(tile_type: String) -> String:
	match tile_type:
		"res://assets/graphics/36x36-forest.png":
			return "forest"
		"res://assets/graphics/36x36-mountains.png":
			return "mountains"
		"res://assets/graphics/36x36-grass.png":
			return "grass"
		"res://assets/graphics/36x36-ocean.png":
			return "ocean"
		_:
			return "unknown"

# Function to save grid data to JSON
func save_grid_data(grid_data: Array):
	var json = JSON.new()
	var json_string = json.stringify(grid_data)
	
	var file = FileAccess.open("user://worldgen/current_map.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		print("Error: Could not save JSON file.")
