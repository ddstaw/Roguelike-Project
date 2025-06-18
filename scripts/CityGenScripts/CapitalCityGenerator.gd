extends Node

# Function to generate a capital city with the correct grid structure
func generate(city_name: String, save_slot: int):
	var grid_size = Vector2(12, 12)  # Example size for the capital city map
	var city_map = generate_map(grid_size)  # Create the map grid

	# Save the map data to the correct save path
	var save_path = LoadHandlerSingleton.get_save_file_path() + "chunks/" + city_name.replace(" ", "_") + "_grid.json"
	save_city_map(city_map, save_path)
	print("Capital city map generated for: " + city_name)

# Function to generate the map grid with biomes, names, and tiles
func generate_map(size: Vector2) -> Dictionary:
	var map = {
		"grid": {
			"biomes": [],
			"names": [],
			"tiles": []
		},
		"world_name": "Generated Capital City"  # Placeholder for the world name
	}

	# Generate grid data for biomes, names, and tiles
	for i in range(size.x):
		var biome_row = []
		var name_row = []
		var tile_row = []
		for j in range(size.y):
			# Example biome and tile logic
			biome_row.append("capitalcity")  # Example biome data
			name_row.append("cell_" + str(i) + "_" + str(j))  # Unique cell names
			tile_row.append("res://assets/graphics/36x36-capitalcity.png")  # Tile image paths
		map["grid"]["biomes"].append(biome_row)
		map["grid"]["names"].append(name_row)
		map["grid"]["tiles"].append(tile_row)

	return map
