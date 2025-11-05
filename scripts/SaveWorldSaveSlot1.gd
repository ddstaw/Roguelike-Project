#res://scripts/SaveWorldSaveSlot1.gd in SaveSlot1 res://scenes/SaveWorld.tscn
extends Button

func _ready():
	# Connect the pressed signal to the button press function
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	# Define the file paths
	var playing_map_path = "user://worldgen/playing_map_settlements.json"
	var basemapinfo_path = "user://saves/save1/world/basemapinfo1.json"
	var basemapdata_path = "user://saves/save1/world/basemapdata1.json"
	var char_active_path = "user://saves/save1/world/char_active1.json"
	var worldmap_basemapinfo_path = "user://saves/save1/world/worldmap_basemapinfo1.json"
	var settlement_name_components_path = "res://data/settlement_name_components.json"

	# Load the settlement name components
	var settlement_names = load_settlement_name_components(settlement_name_components_path)

	# Copy data from playing_map_settlements.json to basemapinfo1.json (no changes here)
	var file_playing_map = FileAccess.open(playing_map_path, FileAccess.READ)
	if file_playing_map:
		var json_data = file_playing_map.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_data)
		file_playing_map.close()

		if error == OK:
			var data = json.data

			# Save the full data to basemapinfo1.json (this part remains unchanged)
			var file_basemapinfo = FileAccess.open(basemapinfo_path, FileAccess.WRITE)
			if file_basemapinfo:
				file_basemapinfo.store_string(JSON.stringify(data))
				file_basemapinfo.close()

			# Generate settlement names based on biome and grid positions
			var settlement_data = generate_settlement_names(data[0]["grid"], settlement_names)

			# Extract only world_name and update basemapdata1.json with minimal content
			var world_name = data[0].get("world_name", "Unknown World")
			var date_created = get_current_date()

			var minimal_data = {
				"world_name": world_name,
				"date_created": date_created,
				"settlement_names": settlement_data
			}

			# Save only the minimal data to basemapdata1.json
			var file_basemapdata = FileAccess.open(basemapdata_path, FileAccess.WRITE)
			if file_basemapdata:
				file_basemapdata.store_string(JSON.stringify([minimal_data]))
				file_basemapdata.close()

			# Update char_active1.json to set is_active to false and character_name to an empty string
			var file_char_active = FileAccess.open(char_active_path, FileAccess.WRITE)
			if file_char_active:
				var char_active_data = {
					"is_active": false,
					"character_name": ""
				}
				file_char_active.store_string(JSON.stringify(char_active_data))
				file_char_active.close()
				
			# Save the data to worldmap_basemapinfo1.json with updated tile paths
			update_and_save_worldmap_basemapinfo(data, worldmap_basemapinfo_path)

			# Trigger a refresh in SaveWorld to update the button display
			var save_world = get_parent()
			save_world.refresh_save_slot_info()

# Function to update tile paths and save the modified data to worldmap_basemapinfo1.json
func update_and_save_worldmap_basemapinfo(data: Array, save_path: String):
	# Update tile paths in the data
	if data[0].has("grid") and data[0]["grid"].has("tiles"):
		for row in data[0]["grid"]["tiles"]:
			for i in range(row.size()):
				# Update tile paths to the 87x87 replacements
				var old_path = row[i]
				var new_path = old_path.replace("res://assets/graphics/", "res://assets/worldmap-graphics/tiles/").replace("36x36-", "87x87-")
				row[i] = new_path

	# Save the updated data to the specified path
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("World map data saved to:", save_path)
	else:
		print("Failed to save the world map data.")


# Function to load settlement name components from the JSON file
func load_settlement_name_components(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_data)
		file.close()

		if error == OK:
			return json.data
	return {}

# Function to generate settlement names based on the grid and biome data
# 🏙️ Main naming generator (adds Pilgrim's Junction logic)
func generate_settlement_names(grid: Dictionary, settlement_names: Dictionary) -> Array:
	var settlements = []
	var used_names = []  # track used names globally to avoid repeats

	for y in range(grid["biomes"].size()):
		for x in range(grid["biomes"][y].size()):
			var biome = grid["biomes"][y][x]
			var name = ""

			if biome == "capitalcity":
				name = get_unique_name(settlement_names.get("capital_city_name", []), used_names)
			elif biome == "dwarfcity":
				name = get_unique_name(settlement_names.get("dwarf_city_name", []), used_names)
			elif biome == "village":
				name = get_unique_name(settlement_names.get("village_name", []), used_names)
			elif biome == "oldcity":
				name = get_unique_name(settlement_names.get("old_city_name", []), used_names)
			elif biome == "elfhaven":
				name = get_unique_name(settlement_names.get("elf_haven_name", []), used_names)
			elif biome == "tradepost":
				name = "Pilgrim's Junction"
				var tavern_name = generate_tavern_name(settlement_names, used_names)
				settlements.append({
					"grid_position": "(" + str(x) + ", " + str(y) + ")",
					"biome": biome,
					"settlement_name": name,
					"tavern_name": tavern_name
				})
				continue

			# Add all other normal settlements
			if name != "":
				settlements.append({
					"grid_position": "(" + str(x) + ", " + str(y) + ")",
					"biome": biome,
					"settlement_name": name
				})

	return settlements

# Helper function to get a unique name from a list
func get_unique_name(name_list: Array, used_names: Array) -> String:
	print("Getting unique name from list: ", name_list, " excluding: ", used_names)  # Debugging

	var available_names = name_list.filter(func(n):
		return !used_names.has(n)
	)
	
	print("Available names: ", available_names)  # Debugging

	if available_names.size() > 0:
		var selected_name = available_names[randi() % available_names.size()]
		print("Selected name: ", selected_name)  # Debugging
		return selected_name
	print("No available names, returning default")  # Debugging
	return "Unnamed Settlement"

# Helper function to get the current date in YYYY-MM-DD format
func get_current_date() -> String:
	var current_date = Time.get_datetime_string_from_system().split(" ")[0]
	return current_date

func generate_tavern_name(settlement_names: Dictionary, used_names: Array) -> String:
	var adjectives = settlement_names.get("tavern_adjectives", [])
	var animals = settlement_names.get("tavern_animals", [])

	if adjectives.is_empty() or animals.is_empty():
		return "The Lonely Mug"  # fallback

	var adj = adjectives[randi() % adjectives.size()]
	var ani = animals[randi() % animals.size()]
	var name = "The " + adj + " " + ani

	# Avoid duplicates
	if used_names.has(name):
		return generate_tavern_name(settlement_names, used_names)

	used_names.append(name)
	return name
