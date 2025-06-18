extends Node

# Function to combine the current map and world name JSON files into a single JSON file
func combine_json_files():
	var map_file = FileAccess.open("user://worldgen/current_map.json", FileAccess.READ)
	var name_file = FileAccess.open("user://worldgen/current_world_name.json", FileAccess.READ)
	
	if not map_file or not name_file:
		print("Error loading map or world name JSON files.")
		return
	
	# Parse the map JSON data
	var map_json = JSON.new()
	var map_error = map_json.parse(map_file.get_as_text())
	map_file.close()
	
	if map_error != OK:
		print("Error parsing map JSON: ", map_json.get_error_message())
		return
	
	# Parse the world name JSON data
	var name_json = JSON.new()
	var name_error = name_json.parse(name_file.get_as_text())
	name_file.close()
	
	if name_error != OK:
		print("Error parsing world name JSON: ", name_json.get_error_message())
		return
	
	var map_array = map_json.data
	var name_data = name_json.data
	
	if map_array.size() == 0:
		print("Map data array is empty.")
		return
	
	var map_dict = map_array[0]
	
	var combined_data = {
		"grid": {
			"biomes": [],
			"names": [],
			"tiles": []
		},
		"world_name": "Unknown World"
	}
	
	# Check and assign biomes
	if map_dict.has("biomes"):
		combined_data["grid"]["biomes"] = map_dict["biomes"]

	# Check and assign names
	if map_dict.has("names"):
		combined_data["grid"]["names"] = map_dict["names"]

	# Check and assign tiles
	if map_dict.has("tiles"):
		combined_data["grid"]["tiles"] = map_dict["tiles"]

	# Check and assign world name
	if name_data.has("world_name"):
		combined_data["world_name"] = name_data["world_name"]

	# Write the combined data to a new JSON file
	var output_file = FileAccess.open("user://worldgen/playing_map.json", FileAccess.WRITE)
	if output_file:
		output_file.store_string(JSON.stringify([combined_data], "\t"))
		output_file.close()
		print("Map and world name combined into playing_map.json")
	else:
		print("Error saving combined JSON file.")
