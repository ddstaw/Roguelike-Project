# res://scenes/play/WorldMapTravel.tscn CityControl Script
extends Control

# Function to load the city grid based on the city_name
func load_city_grid(city_name: String):
	var city_grid_path = "user://saves/save" + str(LoadHandlerSingleton.get_save_slot()) + "/chunks/" + city_name + "_grid.json"
	var city_grid_data = LoadHandlerSingleton.load_json_file(city_grid_path)

	if city_grid_data.size() == 0:
		print("Error: City grid data is empty.")
		return
	
	var map_display = get_parent().get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if map_display:
		print("Loading city grid...")
		map_display.grid_data = city_grid_data["grid"]
		map_display.create_grid()  # Recreate the grid with city tiles
		map_display.display_player_character(Vector2(6, 11))  # Reset the player position inside the city
	else:
		print("Error: Map display node not found.")

func enter_or_generate_city(city_data: Dictionary, player_position: Vector2):
	var current_city = ""

	# Find the matching city based on grid position
	if city_data.has("city_data"):
		for city_name in city_data["city_data"].keys():
			var city_info = city_data["city_data"][city_name]
			var city_position = parse_position(city_info["worldmap-location"])
			if city_position == player_position:
				current_city = city_name
				break

	# If a city is found, enter it
	if current_city != "":
		var city_info = city_data["city_data"][current_city]

		# Check if the city is visited
		if city_info["visited"] == "N":
			print("City " + current_city + " has not been visited yet. Generating map...")

			# Get the city biome
			var city_biome = city_info["biome"]

			# Call the appropriate generator
			GeneratorDispatcher.generate_city(current_city, city_biome)

			# Mark the city as visited and save data
			city_info["visited"] = "Y"
			city_data["city_data"][current_city] = city_info
			LoadHandlerSingleton.save_json_file(LoadHandlerSingleton.get_citydata_path(), city_data)
			print("City marked as visited and data saved.")
		else:
			print("Entering city " + current_city + "...")

		# **🚀 Realms Update: Switch to `citymap` realm**
		var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())
		if placement_data.has("character_position"):
			var character_position = placement_data["character_position"]
			character_position["current_realm"] = "citymap"

			# Store city data inside citymap
			var citymap_data = {
				"biome": city_info["biome"],
				"grid_position": { "x": 6, "y": 11 },  # Move player to city gate
				"cell_name": current_city
			}
			character_position["citymap"] = citymap_data

			# Save back
			LoadHandlerSingleton.save_json_file(LoadHandlerSingleton.get_worldmap_placement_path(), placement_data)
			print("Player moved to city realm:", citymap_data)

		# Load the city grid and display it
		load_city_grid(current_city)
		get_parent().update_world_name_label()
	else:
		print("No city found at the player's current position.")

# Function to exit the city and return to the world map
func exit_city():
	LoadHandlerSingleton.set_realm_char_state("worldmap")
	print("Exiting the city...")

	var city_data_path = LoadHandlerSingleton.get_citydata_path()
	var city_data = LoadHandlerSingleton.load_json_file(city_data_path)

	var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())
	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# Ensure the player is in a city before exiting
		if character_position["current_realm"] != "citymap":
			print("Error: Player is not in a city realm.")
			return

		var current_city = character_position["citymap"].get("cell_name", "Unknown")
		if current_city == "Unknown" or not city_data.has("city_data") or not city_data["city_data"].has(current_city):
			print("Error: No valid city to exit.")
			return

		# Get worldmap location from the city data
		var city_info = city_data["city_data"][current_city]
		var worldmap_position = parse_position(city_info["worldmap-location"])

		# **🚀 Switch back to `worldmap`**
		character_position["current_realm"] = "worldmap"

		# Restore last known worldmap position
		var worldmap_data = character_position.get("worldmap", {})
		worldmap_data["grid_position"] = { "x": int(worldmap_position.x), "y": int(worldmap_position.y) }
		character_position["worldmap"] = worldmap_data

		# Save updated data
		LoadHandlerSingleton.save_json_file(LoadHandlerSingleton.get_worldmap_placement_path(), placement_data)
		print("Exited city:", current_city, "Back to worldmap at:", worldmap_position)

		get_parent().update_world_name_label()

func put_player_at_city_gate():
	var worldmap_placement_path = LoadHandlerSingleton.get_worldmap_placement_path()
	var placement_data = LoadHandlerSingleton.load_json_file(worldmap_placement_path)

	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# Get the citymap data (or create it if missing)
		var city_data = character_position.get("citymap", {})

		# Set player to city gate position
		city_data["grid_position"] = { "x": 6, "y": 11 }

		# Switch realm to citymap
		character_position["current_realm"] = "citymap"
		character_position["citymap"] = city_data  # Save back into character_position

		# Save updated data
		var save_file = FileAccess.open(worldmap_placement_path, FileAccess.WRITE)
		if save_file:
			save_file.store_string(JSON.stringify(placement_data, "\t"))
			save_file.close()
			print("Player moved to city gate at", city_data["grid_position"])
		else:
			print("Error saving updated worldmap_placement.json.")
	else:
		print("Error: 'character_position' not found.")

func update_player_position_on_worldmap(worldmap_position: Vector2):
	var worldmap_placement_path = LoadHandlerSingleton.get_worldmap_placement_path()
	var placement_data = LoadHandlerSingleton.load_json_file(worldmap_placement_path)

	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# Get the worldmap data (or create it if missing)
		var worldmap_data = character_position.get("worldmap", {})

		# Update worldmap grid position
		worldmap_data["grid_position"] = { "x": int(worldmap_position.x), "y": int(worldmap_position.y) }

		# If the player is still in the worldmap, update position
		if character_position["current_realm"] == "worldmap":
			character_position["worldmap"] = worldmap_data

		# Save updated data
		var save_file = FileAccess.open(worldmap_placement_path, FileAccess.WRITE)
		if save_file:
			save_file.store_string(JSON.stringify(placement_data, "\t"))
			save_file.close()
			print("Player position updated on worldmap to", worldmap_position)
		else:
			print("Error saving updated worldmap_placement.json.")
	else:
		print("Error: 'character_position' not found.")

# Helper function to convert the "worldmap-location" string to Vector2
func parse_position(position_str: String) -> Vector2:
	position_str = position_str.trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")
	return Vector2(pos[0].to_int(), pos[1].to_int())
