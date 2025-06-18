extends Control

# Load the world map grid
func load_world_map_grid():
	var grid_data = LoadHandlerSingleton.get_grid_data()
	if grid_data.size() == 0:
		print("Error: World map grid data is empty or not found.")
		return
	
	var map_display = get_parent().get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if map_display:
		print("Loading world map grid...")
		map_display.grid_data = grid_data
		map_display.create_grid()  # Recreate the grid with world map tiles

		var player_position = LoadHandlerSingleton.get_player_position()
		map_display.display_player_character(player_position)  # Display player on world map
	else:
		print("Error: Map display node not found.")

# Update the player's position on the world map
func update_player_position_on_worldmap(worldmap_position: Vector2):
	var worldmap_placement_path = LoadHandlerSingleton.get_worldmap_placement_path()
	var placement_data = LoadHandlerSingleton.load_json_file(worldmap_placement_path)

	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# Get the current realm
		var current_realm = character_position.get("current_realm", "worldmap")
		var worldmap_data = character_position.get("worldmap", {})

		# Only update worldmap position if the player is actually in the worldmap
		if current_realm == "worldmap":
			worldmap_data["grid_position"] = { "x": int(worldmap_position.x), "y": int(worldmap_position.y) }
			character_position["worldmap"] = worldmap_data  # Save it back

			# Write the updated data back to JSON
			var save_file = FileAccess.open(worldmap_placement_path, FileAccess.WRITE)
			if save_file:
				save_file.store_string(JSON.stringify(placement_data, "\t"))
				save_file.close()
				print("Player position updated on worldmap to", worldmap_position)
			else:
				print("Error: Unable to save worldmap position.")
		else:
			print("Warning: Player is not in worldmap realm, position update ignored.")
	else:
		print("Error: 'character_position' not found in data.")

# Helper function to convert the "worldmap-location" string to Vector2
func parse_position(position_str: String) -> Vector2:
	position_str = position_str.trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")
	return Vector2(pos[0].to_int(), pos[1].to_int())

# Save the character state to file
func save_char_state(char_state_data: Dictionary):
	var char_state_path = LoadHandlerSingleton.get_charstate_path()
	var save_file = FileAccess.open(char_state_path, FileAccess.WRITE)
	if save_file != null:
		save_file.store_string(JSON.stringify(char_state_data, "\t"))
		save_file.close()
		print("Character state saved.")
	else:
		print("Error saving char_stateX.json.")

# Load the character state from file
func load_char_state() -> Dictionary:
	var char_state_path = LoadHandlerSingleton.get_charstate_path()
	var file = FileAccess.open(char_state_path, FileAccess.READ)
	if file == null:
		print("char_stateX.json not found.")
		return {}  # Return an empty Dictionary instead of null

	var char_state_data = file.get_as_text()
	file.close()

	var json_parser = JSON.new()
	var parse_result = json_parser.parse(char_state_data)
	if parse_result != OK:
		print("Error parsing char_stateX.json.")
		return {}  # Return an empty Dictionary if parsing fails

	return json_parser.data


