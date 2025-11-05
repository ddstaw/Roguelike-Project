# Play This Character Button res://scenes/CharacterBackground.tscn res://ui/scripts/PlayThisCharacterButton.gd
extends Button

# Paths for the load handler, character template, and race attributes
var load_handler_path = "user://saves/load_handler.json"
var character_template_path = "user://saves/character_template.json"
var race_attributes_path = "res://ui/data/race_attributes.json"

func _ready():
	connect("pressed", Callable(self, "_on_play_button_pressed"))

# Function triggered when the button is pressed
func _on_play_button_pressed():
	print("Play button pressed!")

	# Load the current save slot from load_handler.json
	var load_data = load_load_handler(load_handler_path)
	if load_data:
		var save_file_path = load_data.get("save_file_path", "")
		if save_file_path != "":
			# Append "characterdata" to the save file path
			save_file_path += "characterdata/"

			# Determine the paths to the character_creation and base_attributes files
			var creation_file_path = save_file_path + "character_creation-save" + str(load_data.get("selected_save_slot", 1)) + ".json"
			var base_attributes_file_path = save_file_path + "base_attributes-save" + str(load_data.get("selected_save_slot", 1)) + ".json"
			print("Updating:", creation_file_path)

			# Load data from character_template.json
			var character_template = load_character_template(character_template_path)
			if character_template:
				# Update character_creation file with all fields from the character template
				if update_character_creation(creation_file_path, character_template):
					print("Character creation data updated successfully.")
				else:
					print("Failed to update character creation data.")

				# Update base_attributes file based on character data
				if update_base_attributes(base_attributes_file_path, character_template):
					print("Base attributes updated successfully.")
				else:
					print("Failed to update base attributes.")
				
				# Initialize the starting placement for the character on the world map
				initialize_character_placement(save_file_path, load_data.get("selected_save_slot", 1))
				
				set_character_active(character_template["character"].get("name", "Unnamed Hero"))
				
				# ♻️ NEW: Refresh Tradepost Hub for the new character
				print("🔄 Refreshing Tradepost hub data...")
				var refresher := preload("res://ui/scripts/tradepost_refresh.gd").new()
				refresher.refresh_tradepost_data()
				print("✅ Tradepost hub refreshed successfully.")
				
				# Change to the WorldMapTravel scene
				print("Attempting to change to WorldMapTravel scene...")
				get_tree().change_scene_to_file("res://scenes/play/WorldMapTravel.tscn")
			else:
				print("Failed to load character template.")
		else:
			print("Error: Invalid save file path.")
	else:
		print("Error: Could not load load_handler.json.")

# Function to determine the correct path for the basemapinfo JSON based on the load handler
func determine_basemapinfo_path() -> String:
	var load_handler_path = "user://saves/load_handler.json"
	var file = FileAccess.open(load_handler_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data = json.data
			
			# Ensure the selected_slot is being retrieved from the JSON data correctly
			var selected_slot = data.get("selected_save_slot", 1)  # Read the correct slot number
			var save_file_path = "user://saves/save" + str(selected_slot) + "/"  # Update path to correctly reflect the slot number

			# Construct the correct path for basemapinfoX.json based on the selected slot
			var basemapinfo_path = save_file_path + "world/worldmap_basemapinfo" + str(selected_slot) + ".json"
			print("Determined basemapinfo path:", basemapinfo_path)  # Debug statement to confirm path construction
			return basemapinfo_path
		else:
			print("Error parsing load_handler.json:", json.get_error_message())
	else:
		print("Error: Could not open load_handler.json.")

	return ""  # Return an empty string if loading fails


# Function to initialize the character's starting placement on the map
# Function to initialize the character's starting placement on the map
func initialize_character_placement(save_file_path: String, save_slot: int):
	var json_path = determine_basemapinfo_path()  # Ensure the correct slot path is used
	var placement_path = save_file_path + "worldmap_placement" + str(save_slot) + ".json"
	var grid_data = load_grid_data(json_path)
	var character_position = get_random_grass_or_road_biome_position(grid_data)

	# Convert old format to new "realms" format
	var placement_data = {
		"character_position": {
			"current_realm": "worldmap",  # Default to worldmap at start
			"worldmap": {
				"biome": character_position.get("biome", "Unknown"),
				"grid_position": character_position.get("grid_position", {"x": 0, "y": 0}),
				"cell_name": character_position.get("cell_name", "Unknown")
			},
			"citymap": null,   # Can be populated later when player enters a city
			"expedition": null,
			"special_realm": null
		}
	}

	# Save the updated placement data
	var file = FileAccess.open(placement_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(placement_data, "\t", true))  # Pretty-print JSON
		file.close()
		print("Character starting position saved to:", placement_path)
	else:
		print("Failed to save character placement data.")

# Function to get a random grass or road biome position near the middle of the grid
func get_random_grass_or_road_biome_position(grid_data: Dictionary) -> Dictionary:
	randomize()  # Seed the random number generator for more random results

	# Define the middle range to focus on central coordinates of a 12x12 grid
	var middle_range = [4, 5, 6, 7]  # These indices target the central area
	var selected_position = {}

	# Loop to find a valid grass or road biome position
	for i in range(100):  # Attempt up to 100 times to find a valid position
		var random_x = middle_range[randi() % middle_range.size()]
		var random_y = middle_range[randi() % middle_range.size()]

		# Retrieve the biome at the random position
		var biomes = grid_data.get("biomes", [])
		if random_y < biomes.size() and random_x < biomes[random_y].size():  # Check if the indices are valid
			var biome = biomes[random_y][random_x]

			# Check if the biome is grass or road
			if biome == "grass" or biome == "road":
				selected_position = {
					"grid_position": {
						"x": random_x,
						"y": random_y
					},
					"cell_name": "cell_" + str(random_x) + "_" + str(random_y),
					"biome": biome,
					"status": "normal"
				}
				break  # Exit the loop once a valid position is found

	# If no valid position was found, return a default value (optional)
	if selected_position.size() == 0:
		selected_position = {
			"grid_position": {
				"x": 5,
				"y": 5
			},
			"cell_name": "cell_5_5",
			"biome": "grass",
			"status": "normal"
		}
		print("No valid grass or road position found; using default.")

	return selected_position

# Function to load the load handler JSON
func load_load_handler(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			print("Successfully loaded load handler data.")
			return json.data
		else:
			print("JSON parsing error:", json.error_string)
			return {}
	else:
		print("Failed to open load handler file:", file_path)
		return {}

# Function to load the character template
func load_character_template(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			print("Character template successfully loaded.")
			return json.data
		else:
			print("Error parsing character template:", json.error_string)
			return {}
	else:
		print("Failed to open character template file:", file_path)
		return {}

# Function to update the character_creation JSON with all fields from character_template.json
func update_character_creation(file_path: String, template_data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = {}

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			data = json.data
			
			# Copy all relevant sections from the template data to the save file
			data["character"] = template_data.get("character", data["character"])
			data["aptitudes"] = template_data.get("aptitudes", data["aptitudes"])
			data["skills"] = template_data.get("skills", data["skills"])
			data["magicktech"] = template_data.get("magicktech", data["magicktech"])
			data["reputation"] = template_data.get("reputation", data["reputation"])
			data["divineskills"] = template_data.get("divineskills", data["divineskills"])

			# Set the appropriate divine skill based on the player's faith
			var faith = data["character"].get("faith", "").to_lower()
			match faith:
				"guided by the void":
					data["divineskills"]["eldritch_invocations"] = true
				"orthodox dogmatist":
					data["divineskills"]["catechisms"] = true
				"sinister cultist":
					data["divineskills"]["demon_summoning"] = true
				"pious reformationist":
					data["divineskills"]["devotionals"] = true
				"follower of the old ways":
					data["divineskills"]["druidic_rituals"] = true
				"fundamentalist zealot":
					data["divineskills"]["holy_ghost_power"] = true
				"disciple of rex mundi":
					data["divineskills"]["the_rites_of_rex"] = true
				"godless":
					data["divineskills"]["negation"] = true

			# Write the updated data back to the file
			var write_file = FileAccess.open(file_path, FileAccess.WRITE)
			if write_file:
				write_file.store_string(json.stringify(data, "\t", true))
				write_file.close()
				print("Successfully updated character_creation-save file with full data.")
				return true
			else:
				print("Failed to open file for writing:", file_path)
		else:
			print("JSON parsing error:", json.error_string)
	else:
		print("Failed to open character_creation file:", file_path)

	return false

# Function to update the base_attributes JSON with values from character_template.json
func update_base_attributes(file_path: String, template_data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = {}

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			data = json.data
			
			# Reset all base attribute values to 5 for both value and max_value
			for attribute in data["base_attributes"]:
				data["base_attributes"][attribute]["value"] = 5
				data["base_attributes"][attribute]["max_value"] = 30
			
			# Get the race from the character data
			var race = template_data.get("character", {}).get("race", "").to_lower()

			# Load race-specific attribute adjustments from the JSON
			var race_attributes = load_race_attributes(race_attributes_path)
			if race in race_attributes:
				apply_race_attributes(data, race_attributes[race])

			# Write the updated data back to the file
			var write_file = FileAccess.open(file_path, FileAccess.WRITE)
			if write_file:
				write_file.store_string(json.stringify(data, "\t", true))
				write_file.close()
				print("Successfully updated base_attributes-save file with race-specific adjustments.")
				return true
			else:
				print("Failed to open file for writing:", file_path)
		else:
			print("JSON parsing error:")
	else:
		print("Failed to open base_attributes file:", file_path)

	return false

# Function to load race attributes from a JSON file
func load_race_attributes(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			print("Successfully loaded race attributes.")
			return json.data
		else:
			print("JSON parsing error:", json.error_string)
			return {}
	else:
		print("Failed to open race attributes file:", file_path)
		return {}

# Function to apply race-specific attribute adjustments
func apply_race_attributes(data: Dictionary, attributes: Dictionary):
	for attribute in attributes:
		if attribute in data["base_attributes"]:
			data["base_attributes"][attribute]["value"] += attributes[attribute]
	print("Applied race attributes:", attributes)

# Function to load and parse the JSON file, and return grid data
func load_grid_data(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()  # Close the file after reading

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data_dict = json.data[0]
			if data_dict.has("grid"):
				return data_dict["grid"]
			else:
				print("No grid found in JSON.")
		else:
			print("JSON Parse Error:", json.get_error_message(), "in", json_data, "at line", json.get_error_line())
	else:
		print("Error loading JSON file.")
	
	return {}  # Return an empty dictionary if loading fails

# 🧭 Marks the character as active in char_activeX.json
func set_character_active(character_name: String):
	var slot = LoadHandlerSingleton.get_save_slot()
	var char_active_path = "user://saves/save" + str(slot) + "/world/char_active" + str(slot) + ".json"
	var data = {
		"is_active": true,
		"character_name": character_name
	}

	var file = FileAccess.open(char_active_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t", true))
		file.close()
		print("✅ Character marked as active for Save Slot " + str(slot))
	else:
		print("⚠️ Failed to write char_active file for Save Slot " + str(slot))
