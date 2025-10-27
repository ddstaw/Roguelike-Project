# res://scenes/play/WorldMapTravel.tscn Parent Node Script
extends Control

@onready var health_bar = get_node("MetersContainer/Hboxhealth/healthbar")
@onready var stamina_bar = get_node("MetersContainer/HBoxstamina/staminabar")
@onready var sanity_bar = get_node("MetersContainer/HBoxsanity/sanitybar")
@onready var fatigue_bar = get_node("MetersContainer/HBoxfatigue/fatiguebar")
@onready var hunger_bar = get_node("MetersContainer/HBoxhunger/hungerbar")


# Declare current_position and last_position variables globally
var current_position: Vector2 = Vector2(-1, -1)  # Track current position
var last_position: Vector2 = Vector2(-1, -1)  # Initialize with an invalid position
var position_initialized = false

func _ready() -> void:
	#print("Parent script is ready. Attempting to load the map...")
	
	# ✅ Connect LoadHandlerSingleton's signal to reload the map
	LoadHandlerSingleton.request_map_reload.connect(load_map)
	
	# Hide player character at start of scene load
	var world_texture_rect = get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if world_texture_rect and world_texture_rect.player_character_node:
		world_texture_rect.player_character_node.visible = false
	
	# Start map loading
	load_map()
	call_deferred("initialize_position")

	if world_texture_rect and world_texture_rect.player_character_node:
		world_texture_rect.player_character_node.call_deferred("set_visible", true)  # Ensure visibility updates properly


	# Updating various game labels and values
	LoadHandlerSingleton.load_settlement_names()
	update_biome_label()  # Should be after initializing position
	update_player_name_label()
	update_time_label()
	update_date_label()
	update_gametime_type()
	update_gametime_flavor()
	update_weather_label()
	update_world_name_label()

	# Attributes and combat stats
	set_effective_attributes()  # Ensure attributes are set before updating stats
	update_combat_stats()       # Update combat stats based on effective attributes

	# Update UI elements like progress bars (health, stamina, etc.)
	update_progress_bars()      # Call this last to ensure all values are ready
	
	call_deferred("place_map_markers")
		# Start the timer to delay setting the play scene
	call_deferred("set_play_scene_after_idle")
	
func place_map_markers():
	await get_tree().process_frame  # 🔥 Wait 1 frame to avoid instant removal
	var world_texture_rect = get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if world_texture_rect:
		world_texture_rect.update_map_markers()  # ✅ Place the markers AFTER loading
	
	# Function to handle input events
func _input(event):
	# Handle input events if necessary for future extensions
	pass

func load_map():
	position_initialized = false  # Reset to allow initialization on new map load
	#print("🗺️ Starting load_map function...")

	# ✅ Load worldmap_placement.json instead of char_stateX.json
	var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())

	# ✅ Ensure character_position exists
	if not placement_data.has("character_position"):
		#print("❌ ERROR: 'character_position' not found in worldmap_placement.json.")
		return

	var character_position = placement_data["character_position"]
	var current_realm = character_position.get("current_realm", "worldmap")  # Default to worldmap if missing

	# ✅ Use `current_realm` to determine what to load
	if current_realm == "worldmap":
		#print("🌍 Player is in the world map. Loading world map...")
		LoadHandlerSingleton.set_realm_char_state("worldmap")
		load_world_map()
	elif current_realm == "citymap":
		# ✅ Ensure city name exists
		var city_name = character_position.get("citymap", {}).get("name", "")
		if city_name != "":
			print("🏙️ Player is in city:", city_name)
			LoadHandlerSingleton.set_realm_char_state("city")
			load_city_map(city_name)
		else:
			print("❌ ERROR: City name not found while in city state.")
	else:
		print("❌ ERROR: Unknown realm:", current_realm)

# Function to load the world map
func load_world_map():
	#print("🌍 Loading world map...")
	await get_tree().process_frame  # Give time for the map to load
	var map_display = get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if map_display:
		#print("✅ Found WorldTextureRect, initializing world map display...")
		map_display.init_map_display()
		update_world_name_label()
	else:
		print("❌ ERROR: WorldTextureRect node not found! Check the node path.")

# ✅ Function to load the city map
func load_city_map(city_name: String):
	#print("🏙️ Loading city map for:", city_name)

	# ✅ Get city grid path from city_data1.json
	var city_data_path = LoadHandlerSingleton.get_citydata_path()
	var city_data = LoadHandlerSingleton.load_json_file(city_data_path)

	# ✅ Ensure city data exists
	if not city_data.has("city_data") or not city_data["city_data"].has(city_name):
		#print("❌ ERROR: No city data found for", city_name)
		return

	var city_grid_path = city_data["city_data"][city_name]["city_grid"]
	var city_grid_data = LoadHandlerSingleton.load_json_file(city_grid_path)

	# ✅ Load the city grid into the world map display
	var map_display = get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if map_display:
		#print("✅ Found WorldTextureRect, loading city grid...")
		map_display.grid_data = city_grid_data["grid"]
		map_display.create_grid()

		# ✅ Load the player's actual position from worldmap_placement.json
		var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())
		if placement_data.has("character_position") and placement_data["character_position"].has("citymap"):
			var player_position = placement_data["character_position"]["citymap"]
			if player_position.has("grid_position"):
				var grid_position = player_position["grid_position"]
				var player_display_position = Vector2(grid_position["x"] * map_display.TILE_SIZE, grid_position["y"] * map_display.TILE_SIZE)
				map_display.display_player_character(player_display_position)
			else:
				print("❌ ERROR: Player grid position not found in JSON data.")
		else:
			print("❌ ERROR: 'citymap' data missing from worldmap_placement.json.")
	else:
		print("❌ ERROR: Map display node not found for city.")


func initialize_position():
	# Only proceed if not yet initialized
	if position_initialized:
		#print("Position already initialized; skipping.")
		return

	await get_tree().process_frame  # Ensure all nodes are fully initialized

	# Define GRID_SIZE consistently
	var GRID_SIZE = 12
	var player_position = load_player_position()

	# Check and apply the correct position
	if player_position.has("grid_position"):
		var grid_position = player_position["grid_position"]
		var x = grid_position["x"]
		var y = grid_position["y"]

		# Calculate display position
		var world_position = Vector2(x, y)
		#print("Setting player display position to:", world_position)

		# Get the WorldTextureRect node and set visibility to false initially
		var world_texture_rect = get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
		if world_texture_rect:
			world_texture_rect.display_player_character(world_position)
			world_texture_rect.player_character_node.call_deferred("set_visible", true)  # Set visibility deferred
			print("Player character made visible after position set.")

			position_initialized = true
		else:
			print("Error: WorldTextureRect node not found.")
	else:
		print("Error: Player grid position not found in JSON data.")

	
func update_biome_label():
	var biome_label = get_node("RightInfoContainerBiome/BiomeLabel")
	if not biome_label:
		#print("❌ Error: BiomeLabel node not found.")
		return

	var current_position = LoadHandlerSingleton.get_player_position()
	var biome_name = LoadHandlerSingleton.get_biome_name(current_position)

	#print("📍 Current Position:", current_position)
	#print("🌍 Biome Name Before Check:", biome_name)

	# ✅ Use village proper name if available
	if biome_name == "village" and LoadHandlerSingleton.villages.has(current_position):
		var village_name = LoadHandlerSingleton.villages[current_position]
		biome_label.text = village_name
		print("🏡 Village name updated to:", village_name)
		return

	# ✅ Use Constants helper for all other biomes
	match biome_name:
		"elfhaven":
			biome_label.text = LoadHandlerSingleton.elfhaven_proper
		"oldcity":
			biome_label.text = LoadHandlerSingleton.oldcity_proper
		"dwarfcity":
			biome_label.text = LoadHandlerSingleton.dwarfcity_proper
		"capitalcity":
			biome_label.text = LoadHandlerSingleton.capitalcity_proper
		_:
			biome_label.text = Constants.get_biome_label(biome_name)

	#print("✅ Biome label updated to:", biome_label.text)

		
# Function to retrieve the village name based on the player's current position
func get_village_name(position: Vector2) -> String:
	return LoadHandlerSingleton.villages.get(position, "Unknown Village")  # Use the singleton to get villages
		
func update_time_label():
	var time_label = get_node("RightInfoContainerTime/TimeLabel")
	var timedate = LoadHandlerSingleton.get_time_and_date()
	if timedate.has("gametime"):
		time_label.text = timedate["gametime"]

# Function to update the date label
func update_date_label():
	# Adjust the path based on the actual scene structure
	var date_label = get_node("LeftInfoContainer/worldmapdate")  # Update this path to the correct one
	if date_label:
		var date_value = LoadHandlerSingleton.get_date_name()  # Use the singleton to get the date
		date_label.text = date_value
		print("Date label updated to:", date_value)
	else:
		print("Error: DateLabel node not found at the specified path.")

# Function to update the game time flavor image
func update_gametime_flavor():
	# Adjust the path based on the actual scene structure
	var flavor_image_node = get_node("RightInfoContainerTime/FlavorTimeImage")  # Update this path to the correct one
	if flavor_image_node:
		var flavor_texture = LoadHandlerSingleton.get_gametimeflavor_image()  # Use the singleton to get the flavor image
		if flavor_texture:
			flavor_image_node.texture = flavor_texture
			#print("Flavor image updated successfully.")
		else:
			print("Error: Failed to load texture for gametime flavor.")
	else:
		print("Error: FlavorTimeImage node not found at the specified path.")

# Function to update the gametime type text based on the gametimetype path in the JSON
func update_gametime_type():
	# Adjust the path based on the actual scene structure
	var time_type_node = get_node("RightInfoContainerTime/FlavorTime")  # Update this path to the correct one
	if time_type_node:
		var time_type_value = LoadHandlerSingleton.get_gametimetype()  # Use the singleton to get gametimetype
		if time_type_value != "":
			time_type_node.text = time_type_value
			#print("Gametime type updated to:", time_type_value)
		else:
			print("Error: Failed to retrieve gametimetype.")
	else:
		print("Error: FlavorTime node not found at the specified path.")


# Function to update the weather label on the UI
func update_weather_label():
	# Adjust the path based on the actual scene structure
	var weather_label = get_node("RightInfoContainerTime/WeatherLabel")  # Update this path to the correct one
	if weather_label:
		var weather_value = LoadHandlerSingleton.get_gameweather()  # Use the singleton to get the weather
		weather_label.text = weather_value
		#print("Weather label updated to:", weather_value)
	else:
		print("Error: WeatherLabel node not found at the specified path.")

# Function to update the player name label
func update_player_name_label():
	var name_label = get_node("RightInfoContainerBasic/Namelabel")
	if name_label:
		name_label.text = LoadHandlerSingleton.get_player_name()

# Function to update the world name label
func update_world_name_label():
	var worldmap_name_label = get_node("LeftInfoContainer/WorldMapName")
	
	if worldmap_name_label:
		# ✅ Get the current realm (worldmap or citymap)
		var current_realm = LoadHandlerSingleton.get_current_realm()

		# ✅ Set label based on realm
		if current_realm == "worldmap":
			worldmap_name_label.text = LoadHandlerSingleton.get_world_name()  # Show world name
		elif current_realm == "citymap":
			worldmap_name_label.text = LoadHandlerSingleton.get_current_city()  # Show city name
		else:
			worldmap_name_label.text = "Unknown Realm"  # Fallback text

		#print("🌍 Updated world name label:", worldmap_name_label.text)  # Debugging
	else:
		print("❌ Error: WorldMapName node not found.")


# Function to load and parse the JSON file for grid data
func load_grid_data() -> Dictionary:
	var load_handler_path = "user://saves/load_handler.json"
	var json_path = determine_map_path(load_handler_path)
	var grid_data = {}

	if json_path != "":
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()

			var json = JSON.new()
			var error = json.parse(json_data)

			if error == OK:
				var data_dict = json.data[0]
				if data_dict.has("grid"):
					grid_data = data_dict["grid"]
				else:
					print("No grid found in JSON.")
			else:
				print("JSON Parse Error:", json.get_error_message(), "in", json_data, "at line", json.get_error_line())
		else:
			print("Error loading JSON file.")
	else:
		print("Error: Could not determine the correct path for map data.")

	return grid_data

# Function to determine the correct path for the map data based on the load handler
func determine_map_path(load_handler_path: String) -> String:
	var file = FileAccess.open(load_handler_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data = json.data
			var save_file_path = data.get("save_file_path", "user://saves/save1/")  # Default if path is missing
			var selected_slot = data.get("selected_save_slot", 1)  # Default to save slot 1 if not specified

			# Construct the appropriate path based on the save slot
			var map_path = save_file_path + "world/worldmap_basemapinfo" + str(selected_slot) + ".json"
			return map_path
		else:
			print("Error parsing load_handler.json:", json.get_error_message())
	else:
		print("Error: Could not open load_handler.json.")

	return ""

# Function to load player position from worldmap_placementX.json
func load_player_position() -> Dictionary:
	var load_handler_path = "user://saves/load_handler.json"
	var placement_path = determine_placement_path(load_handler_path)
	var player_position = {}

	if placement_path != "":
		var file = FileAccess.open(placement_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()

			var json = JSON.new()
			var error = json.parse(json_data)

			if error == OK:
				var data = json.data
				if data.has("character_position"):
					var character_position = data["character_position"]

					# Get current realm
					var current_realm = character_position.get("current_realm", "worldmap")
					var realm_data = character_position.get(current_realm, {})

					# Extract position data from the active realm
					player_position = {
						"grid_position": realm_data.get("grid_position", { "x": 0, "y": 0 }),
						"biome": realm_data.get("biome", "Unknown"),
						"cell_name": realm_data.get("cell_name", "Unknown"),
						"current_realm": current_realm
					}
					
					#print("Player position loaded:", player_position)
				else:
					print("No character_position found in worldmap_placement JSON.")
			else:
				print("Error parsing worldmap_placement JSON:", json.get_error_message())
		else:
			print("Error: Could not open worldmap_placement JSON at path:", placement_path)

	return player_position

# Function to determine the correct path for the player position data based on the load handler
func determine_placement_path(load_handler_path: String) -> String:
	var file = FileAccess.open(load_handler_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data = json.data
			var save_file_path = data.get("save_file_path", "user://saves/save1/")  # Default if path is missing
			var selected_slot = data.get("selected_save_slot", 1)  # Default to save slot 1 if not specified

			# Construct the appropriate path based on the save slot
			var placement_path = save_file_path + "characterdata/worldmap_placement" + str(selected_slot) + ".json"
			return placement_path
		else:
			print("Error parsing load_handler.json:", json.get_error_message())
	else:
		print("Error: Could not open load_handler.json.")

	return ""

func set_effective_attributes():
	# Get the base attributes data using the singleton
	var base_attributes = LoadHandlerSingleton.get_base_attributes()
	
	if base_attributes.has("base_attributes"):
		var attributes_data = base_attributes
		var base_attributes_section = attributes_data.get("base_attributes", {})

		var effective_attributes = {}

		# Copy base attributes to effective attributes
		for attr_name in base_attributes_section:
			effective_attributes[attr_name] = base_attributes_section[attr_name].get("value", 0)
		

		# Update the effective attributes in the original data
		attributes_data["effective_attributes"] = effective_attributes

		# Write the updated data back to the file
		var base_attributes_path = LoadHandlerSingleton.get_base_attributes_path()
		var base_attributes_file = FileAccess.open(base_attributes_path, FileAccess.WRITE)  # Open file for writing
		if base_attributes_file:
			base_attributes_file.store_string(JSON.stringify(attributes_data, "\t"))  # Save with formatting
			base_attributes_file.close()
			#print("Base attributes successfully updated with effective attributes.")
		else:
			print("Error: Failed to open base attributes file for writing at:", base_attributes_path)
	else:
		print("Error: Base attributes section not found in the JSON data.")

func update_combat_stats():
	# Use the singleton to load the base attributes and combat stats data
	var base_attributes = LoadHandlerSingleton.get_base_attributes()
	var combat_stats = LoadHandlerSingleton.get_combat_stats()

	if base_attributes.has("base_attributes"):
		var attributes_data = base_attributes
		var effective_attributes = {}
		var base_attributes_section = attributes_data.get("base_attributes", {})

		# Retrieve the effective attributes
		for attr_name in base_attributes_section:
			effective_attributes[attr_name] = base_attributes_section[attr_name].get("value", 0)

		# Calculate new values based on effective attributes
		var endurance = effective_attributes.get("endurance", 0) * 20
		var agility = effective_attributes.get("agility", 0) * 20
		var willpower = effective_attributes.get("willpower", 0) * 20

		# Proceed to update combat stats with the new values
		if combat_stats.has("combat_stats"):
			var combat_stats_data = combat_stats["combat_stats"]

			# Update only the max values for health, stamina, and sanity
			combat_stats_data["health"]["max"] = endurance
			combat_stats_data["stamina"]["max"] = agility
			combat_stats_data["sanity"]["max"] = willpower

			# Write the updated combat stats back to the file using the singleton
			var combat_stats_path = LoadHandlerSingleton.get_combat_stats_path()
			var combat_stats_file = FileAccess.open(combat_stats_path, FileAccess.WRITE)
			if combat_stats_file:
				combat_stats_file.store_string(JSON.stringify(combat_stats, "\t"))  # Save with formatting
				combat_stats_file.close()
				#print("Combat stats successfully updated.")
			else:
				print("Error: Failed to open combat stats file for writing at:", combat_stats_path)
		else:
			print("Error: 'combat_stats' section not found in the JSON.")
	else:
		print("Error: Base attributes section not found in the JSON data.")

func update_progress_bars() -> void:
	# Use the singleton to get the combat stats data
	var combat_stats_data = LoadHandlerSingleton.get_combat_stats()

	# Ensure combat stats data was successfully loaded
	if combat_stats_data.has("combat_stats"):
		update_health_ui(combat_stats_data)
		update_stamina_ui(combat_stats_data)
		update_sanity_ui(combat_stats_data)
		update_hunger_ui(combat_stats_data)
		update_fatigue_ui(combat_stats_data)
	else:
		print("Error: 'combat_stats' section not found in the JSON.")

func update_health_ui(combat_stats_data) -> void:
	var health_max = combat_stats_data["combat_stats"]["health"]["max"]
	var health_current = combat_stats_data["combat_stats"]["health"]["current"]
	
	if health_bar:
		health_bar.max_value = health_max
		health_bar.value = health_current
	else:
		print("Error: HealthBar node not found.")

func update_stamina_ui(combat_stats_data) -> void:
	var stamina_max = combat_stats_data["combat_stats"]["stamina"]["max"]
	var stamina_current = combat_stats_data["combat_stats"]["stamina"]["current"]
	
	if stamina_bar:
		stamina_bar.max_value = stamina_max
		stamina_bar.value = stamina_current
	else:
		print("Error: StaminaBar node not found.")

func update_sanity_ui(combat_stats_data) -> void:
	var sanity_max = combat_stats_data["combat_stats"]["sanity"]["max"]
	var sanity_current = combat_stats_data["combat_stats"]["sanity"]["current"]
	
	if sanity_bar:
		sanity_bar.max_value = sanity_max
		sanity_bar.value = sanity_current
	else:
		print("Error: SanityBar node not found.")

func update_hunger_ui(combat_stats_data) -> void:
	var hunger_max = combat_stats_data["combat_stats"]["hunger"]["max"]
	var hunger_current = combat_stats_data["combat_stats"]["hunger"]["current"]
	
	if hunger_bar:
		hunger_bar.max_value = hunger_max
		hunger_bar.value = hunger_current
	else:
		print("Error: HungerBar node not found.")

func update_fatigue_ui(combat_stats_data) -> void:
	var fatigue_max = combat_stats_data["combat_stats"]["fatigue"]["max"]
	var fatigue_current = combat_stats_data["combat_stats"]["fatigue"]["current"]
	
	if fatigue_bar:
		fatigue_bar.max_value = fatigue_max
		fatigue_bar.value = fatigue_current
	else:
		print("Error: FatigueBar node not found.")
		
# Function to set play scene after yielding for a frame
func set_play_scene_after_idle() -> void:
	await get_tree().process_frame  # Wait for one frame
	#print("Setting play scene after yielding one frame...")
	SceneManager.set_play_scene("res://scenes/play/WorldMapTravel.tscn")
