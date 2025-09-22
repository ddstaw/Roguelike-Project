extends Control

const GRID_SIZE = 12  # Declare GRID_SIZE as a constant
const INVENTORY_SCENE: String = "res://scenes/play/Inventory_LocalPlay.tscn"


@onready var rest_button = $RestButton
@onready var travel_log_control = get_node_or_null("/root/WorldMapTravel/LeftInfoContainer/TravelLogControl")
@onready var travel_log_scroll = get_node_or_null("/root/WorldMapTravel/LeftInfoContainer/TravelLogControl/TravelLogPanel/TravelLogScrollContainer")

# Define possible rest outcomes
var rest_outcomes = [
	"You have rested and feel refreshed.",
	"You have rested but still feel tired.",
	"You have rested but had terrible nightmares.",
	"You have rested and feel strangely wonderful, regaining sanity."
]

# Special outcome when hunger is 0
var starving_outcome = "You try to rest but you are starving, you feel tired and your sanity slipping."

func _ready() -> void:
	#print("Movement and Rest Control is ready.")
	rest_button.connect("pressed", Callable(self, "_on_rest_button_pressed"))
	set_process_input(true)  # Handle input events like spacebar

# Function to handle input events like the spacebar
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Default binding for Spacebar is ui_accept
		_on_rest_button_pressed()  # Trigger rest when spacebar is pressed
		
		# Check if numpad 5 is pressed
	if event.is_action_pressed("rest_select"):  # Use "rest_select" for numpad 5
		_on_rest_button_pressed()  # Trigger the same rest action
	
	# Inventory key press
	if event.is_action_pressed("toggle_inventory"):
		accept_event()
		handle_inventory_toggle()
		return  # Prevents movement/other logic firing in the same frame
	
	# Movement input handling
	if event.is_action_pressed("up_move"):
		move_player(Vector2(0, -1))  # Move up
	elif event.is_action_pressed("upleft_move"):
		move_player(Vector2(-1, -1))  # Move up left
	elif event.is_action_pressed("upright_move"):
		move_player(Vector2(1, -1))  # Move up right
	elif event.is_action_pressed("left_move"):
		move_player(Vector2(-1, 0))  # Move left
	elif event.is_action_pressed("right_move"):
		move_player(Vector2(1, 0))  # Move right
	elif event.is_action_pressed("down_move"):
		move_player(Vector2(0, 1))  # Move down
	elif event.is_action_pressed("downleft_move"):
		move_player(Vector2(-1, 1))  # Move down left
	elif event.is_action_pressed("downright_move"):
		move_player(Vector2(1, 1))  # Move down right
		

func handle_inventory_toggle() -> void:
	# Minimal: just open the inventory scene.
	# Your inventory script will read char_state and return to WorldMapTravel.
	get_tree().change_scene_to_file(INVENTORY_SCENE)

func _on_rest_button_pressed():
	#print("Before resting:")
	TimeManager.print_time_and_date()
	#print("You have rested.")
	
	# Load the combat stats
	var combat_stats_data = LoadHandlerSingleton.get_combat_stats()

	# Access the "combat_stats" section of the JSON data
	var combat_stats = combat_stats_data.get("combat_stats", {})

	# Get hunger, sanity, fatigue, stamina, and health values
	var hunger_current = combat_stats.get("hunger", {}).get("current", null)
	var hunger_max = combat_stats.get("hunger", {}).get("max", null)
	var sanity_current = combat_stats.get("sanity", {}).get("current", null)
	var sanity_max = combat_stats.get("sanity", {}).get("max", null)
	var fatigue_current = combat_stats.get("fatigue", {}).get("current", null)
	var fatigue_max = combat_stats.get("fatigue", {}).get("max", null)
	var stamina_current = combat_stats.get("stamina", {}).get("current", null)
	var stamina_max = combat_stats.get("stamina", {}).get("max", null)
	var health_current = combat_stats.get("health", {}).get("current", null)
	var health_max = combat_stats.get("health", {}).get("max", null)

	# Check if values are missing
	if hunger_current == null or sanity_current == null or fatigue_current == null or stamina_current == null or health_current == null:
		#print("Missing critical values from the JSON file!")
		return

	# Check if hunger is 0 and apply starving outcome
	var selected_message = ""
	if hunger_current == 0:
		# Apply the "starving" effects
		health_current = max(health_current - 17, 0)
		sanity_current = max(sanity_current - 22, 0)
		stamina_current = max(stamina_current - 22, 0)
		fatigue_current = max(fatigue_current - 22, 0)

		#print("Starving! Health:", health_current, "Sanity:", sanity_current, "Stamina:", stamina_current, "Fatigue:", fatigue_current)
		selected_message = starving_outcome
	else:
		# Prepare weighted rest outcome list
		var weighted_rest_outcomes = []
		
		# Add the regular outcomes
		for i in range(3):
			weighted_rest_outcomes.append("You have rested and feel refreshed.")
			weighted_rest_outcomes.append("You have rested but still feel tired.")
		
		# Make nightmares far more likely if hunger is over 70%
		if hunger_current != null and hunger_max != null and hunger_current >= hunger_max * 0.7:
			for i in range(5):  # Add more weight for nightmares
				weighted_rest_outcomes.append("You have rested but had terrible nightmares.")
		else:
			weighted_rest_outcomes.append("You have rested but had terrible nightmares.")
		
		# Always include the "wonderful" outcome
		weighted_rest_outcomes.append("You have rested and feel strangely wonderful, regaining sanity.")

		# Randomly select a rest outcome
		selected_message = weighted_rest_outcomes[randi() % weighted_rest_outcomes.size()]

		# Apply fatigue, stamina, sanity effects based on outcome
		if selected_message == "You have rested but still feel tired.":
			fatigue_current = max(fatigue_current - 5, 0)
			stamina_current = max(stamina_current - 5, 0)
		elif selected_message == "You have rested but had terrible nightmares.":
			sanity_current = max(sanity_current - 10, 0)
		elif selected_message == "You have rested and feel strangely wonderful, regaining sanity.":
			sanity_current = min(sanity_current + 10, sanity_max)
			fatigue_current = min(fatigue_current + 5, fatigue_max)
			stamina_current = min(stamina_current + 5, stamina_max)
		else:
			fatigue_current = min(fatigue_current + 5, fatigue_max)
			stamina_current = min(stamina_current + 5, stamina_max)

		# Reduce hunger by 10 for every rest
		hunger_current = max(hunger_current - 10, 0)

	# Log the selected message into the travel log
	if travel_log_control:
		travel_log_control.add_message_to_log(selected_message)
		#print("Added rest outcome to log:", selected_message)
	else:
		print("Error: TravelLogControl or Scroll not found.")

	# Update combat stats
	combat_stats["fatigue"]["current"] = fatigue_current
	combat_stats["stamina"]["current"] = stamina_current
	combat_stats["sanity"]["current"] = sanity_current
	combat_stats["health"]["current"] = health_current
	combat_stats["hunger"]["current"] = hunger_current

	# Save the updated combat stats
	LoadHandlerSingleton.save_combat_stats(combat_stats_data)
	#print("Combat stats saved.")

	# Call the update_progress_bars() to update the bars after resting
	var world_map_control = get_node("/root/WorldMapTravel")  # Adjust the node path if necessary
	if world_map_control:
		world_map_control.update_progress_bars()
		#print("Updated progress bars.")
	else:
		print("Error: WorldMapTravel node not found.")
		

	# After resting, pass two hours and update the flavor
	TimeManager.pass_two_hours()  # Advance the game time by 2 hours

	# Get the updated time data from the singleton
	var updated_time_data = LoadHandlerSingleton.get_time_and_date()  # Load updated time data

	# Call the flavor update using the updated time data
	TimeManager.update_gametime_flavor2(updated_time_data)
	
	world_map_control.update_time_label()  # Update the label after the time change
	world_map_control.update_gametime_flavor()
	world_map_control.update_gametime_type()
	
	# After resting, print the current time and date again
	#print("After resting:")
	TimeManager.print_time_and_date()
	
func move_player(direction: Vector2):
	var current_position = LoadHandlerSingleton.get_player_position()
	var new_position = current_position + direction

	if is_valid_position(new_position):
		update_player_position(new_position)

		# ✅ Correct biome retrieval per realm
		var biome_name = LoadHandlerSingleton.get_biome_name(new_position)
		#print("🌍 DEBUG: Biome before updating JSON:", biome_name)
		var cell_name = "cell_" + str(new_position.x) + "_" + str(new_position.y)

		# ✅ Correctly update only the active realm
		LoadHandlerSingleton.update_biome_and_cell_in_json(biome_name, cell_name)

		update_displayed_player_position(new_position)
		travel_effects(new_position)
	
		var world_map_control = get_node("/root/WorldMapTravel")  # Adjust if needed
		if world_map_control:
			world_map_control.update_biome_label()  # ⬅️ Add this line
			#print("🌍 Biome label updated after movement.")
		else:
			print("⚠️ Warning: WorldMapTravel node not found!")
			
		city_check(new_position)

	else:
		print("❌ Movement blocked by boundary.")
		

func city_check(new_position: Vector2):
	# Load the basemap data from the correct path
	var basemap_file_path = LoadHandlerSingleton.get_basemapsettlements_path()
	var basemap_file = FileAccess.open(basemap_file_path, FileAccess.READ)
	if basemap_file == null:
		print("❌ ERROR: basemapdataX.json file not found: " + basemap_file_path)
		return

	var basemap_data = basemap_file.get_as_text()
	basemap_file.close()

	# Parse the basemap data
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(basemap_data)
	if parse_result != OK:
		print("❌ ERROR: Failed to parse basemapdataX.json")
		return

	var basemap_array = json_parser.data  # The parsed basemap data is an array

	# Load city data from city_data1.json
	var city_data_path = LoadHandlerSingleton.get_citydata_path()
	var city_data = LoadHandlerSingleton.load_json_file(city_data_path)

	# Ensure "city_data" exists
	if not city_data.has("city_data"):
		city_data["city_data"] = {}

	# Iterate over the settlements to check if the player is on a city tile
	for settlement_entry in basemap_array:
		var settlements = settlement_entry["settlement_names"]
		for settlement in settlements:
			var settlement_position = parse_position(settlement["grid_position"])
			if settlement_position == new_position:
				# ✅ Player is standing on a settlement tile
				var city_name = settlement["settlement_name"]
				var biome = settlement["biome"]

				# ✅ If city is NOT in city_data.json, add it and generate a city map
				if not city_data["city_data"].has(city_name):
					print("🏗️ New city detected: " + city_name + ". Adding to city_data.json...")

					# 1️⃣ Add city to city_data.json
					update_city_data(city_name, biome, new_position)

					# 2️⃣ Create empty city JSON
					generate_city_json_file(city_name)

					# 3️⃣ Update city_data.json with correct map path
					update_city_data_with_map_path(city_name)

					# 4️⃣ ✅ Generate the city immediately
					print("🚀 Generating village for:", city_name)
					GeneratorDispatcher.generate_city(city_name, biome)

				else:
					print("✅ City " + city_name + " already exists in city_data.json.")

				return  # ✅ Exit after finding a matching city

	# If no city found, print a message
	#print("🚫 No city found at this position.")


# Function to parse the position string into a Vector2
func parse_position(position_str: String) -> Vector2:
	position_str = position_str.trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")
	return Vector2(pos[0].to_int(), pos[1].to_int())

func update_city_data(city_name: String, biome: String, tile_position: Vector2):
	var city_data_path = LoadHandlerSingleton.get_citydata_path()  # Path for city_data1.json

	# Load existing data from city_data1.json
	var city_data_file = FileAccess.open(city_data_path, FileAccess.READ)
	var city_data = {}
	if city_data_file:
		var json_parser = JSON.new()
		if json_parser.parse(city_data_file.get_as_text()) == OK:
			city_data = json_parser.data
		city_data_file.close()

	# Ensure "city_data" key exists
	if not city_data.has("city_data"):
		city_data["city_data"] = {}

	# Append new city data
	var city_entry = {
		"name": city_name,
		"biome": biome,
		"worldmap-location": "(" + str(tile_position.x) + ", " + str(tile_position.y) + ")",
		"visited": "N"
	}
	city_data["city_data"][city_name] = city_entry

	# Save the updated city_data1.json
	var city_data_file_write = FileAccess.open(city_data_path, FileAccess.WRITE)
	city_data_file_write.store_string(JSON.stringify(city_data, "\t"))
	city_data_file_write.close()

	#print("Updated city_data1.json with new city: " + city_name)


func generate_city_json_file(city_name: String):
	var save_slot_path = LoadHandlerSingleton.get_save_file_path()
	var chunks_folder = save_slot_path + "chunks/"
	var city_grid_filename = city_name.replace(" ", "_") + "_grid.json"
	var city_grid_path = chunks_folder + city_grid_filename

	# Open the directory to check if it exists
	var dir = DirAccess.open(chunks_folder)
	if dir == null:  # If the directory doesn't exist
		dir = DirAccess.open("user://")  # Open a base path like user://
		if dir.make_dir_recursive(chunks_folder) != OK:  # Create the chunks folder recursively
			print("Failed to create chunks directory: " + chunks_folder)
			return

	# Create an empty city grid JSON
	var city_grid_file = FileAccess.open(city_grid_path, FileAccess.WRITE)
	if city_grid_file != null:
		city_grid_file.store_string(JSON.stringify({}, "\t"))  # Empty JSON structure
		city_grid_file.close()
		#print("Empty city grid created at: " + city_grid_path)
	else:
		print("Failed to create city grid file: " + city_grid_path)


func update_city_data_with_map_path(city_name: String):
	var city_data_path = LoadHandlerSingleton.get_citydata_path()  # Path for city_data1.json

	# Load existing data from city_data1.json
	var city_data = LoadHandlerSingleton.load_json_file(city_data_path)

	if not city_data.has("city_data") or not city_data["city_data"].has(city_name):
		print("City not found in city_data1.json, skipping update.")
		return

	# Add city grid path
	var save_slot_path = LoadHandlerSingleton.get_save_file_path()
	var city_grid_filename = city_name.replace(" ", "_") + "_grid.json"
	var city_grid_path = save_slot_path + "chunks/" + city_grid_filename

	city_data["city_data"][city_name]["city_grid"] = city_grid_path

	# Save the updated city_data1.json
	var city_data_file = FileAccess.open(city_data_path, FileAccess.WRITE)
	city_data_file.store_string(JSON.stringify(city_data, "\t"))
	city_data_file.close()

	#print("Updated city grid path for " + city_name + " in city_data1.json.")

		
func is_valid_position(position: Vector2) -> bool:
	# Get the grid data
	var grid_data = LoadHandlerSingleton.get_grid_data()
	
	# Check boundaries based on grid data
	if position.x < 0 or position.x >= GRID_SIZE or position.y < 0 or position.y >= GRID_SIZE:
		return false  # Out of bounds
	# Further checks on grid data can be added here as needed
	return true

func update_player_position(new_position: Vector2):
	var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())  # Load entire JSON data

	# Ensure placement_data has character_position
	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# Get the current realm
		var current_realm = character_position.get("current_realm", "worldmap")
		var realm_data = character_position.get(current_realm, {})  # Get the correct realm data

		# Update grid position in the correct realm
		realm_data["grid_position"] = {
			"x": int(new_position.x),
			"y": int(new_position.y)
		}

		# Save the updated realm data back to character_position
		character_position[current_realm] = realm_data

		# Write the updated data back to JSON
		var file = FileAccess.open(LoadHandlerSingleton.get_worldmap_placement_path(), FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(placement_data, "\t"))  # Save with formatting
			file.close()
			#print("Player position updated in", current_realm, "to:", new_position)
		else:
			print("Error: Unable to save player position.")
	else:
		print("Error: 'character_position' not found in data.")

func update_displayed_player_position(new_position: Vector2):
	var map_display = get_node("/root/WorldMapTravel/MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	
	if map_display:
		# Remove or hide the old player character
		map_display.remove_player_character()  # Make sure this method is implemented to remove the old image

		# Call the function to display the new player character at the updated position
		map_display.display_player_character(new_position)  
		
		# Update the player's position in the JSON
		update_player_position(new_position)  # Ensure this is called to update the JSON
	else:
		print("Error: Map display node is null. Please check the node path.")

	
func update_biome_info(new_position: Vector2):
	# ✅ Get the current realm (worldmap or citymap)
	var current_realm = LoadHandlerSingleton.get_current_realm()

	# ✅ Fetch the correct biome based on the current realm
	var biome_name = LoadHandlerSingleton.get_biome_name(new_position)

	# ✅ Log biome information
	#print("🌍 Biome updated for", current_realm, "at", new_position, ":", biome_name)

	# ✅ If in worldmap, update the world biome label
	if current_realm == "worldmap":
		var world_map_control = get_node_or_null("/root/WorldMapTravel")
		if world_map_control:
			world_map_control.update_biome_label(biome_name)
		else:
			print("⚠️ WARNING: WorldMapTravel node not found!")

	# ✅ If in a city, update the city biome label
	elif current_realm == "citymap":
		var city_map_control = get_node_or_null("/root/CityMapTravel")
		if city_map_control:
			city_map_control.update_village_biome_label(biome_name)
		else:
			print("⚠️ WARNING: CityMapTravel node not found!")

	
func travel_effects(current_position: Vector2):
	var combat_stats_data = LoadHandlerSingleton.get_combat_stats()
	var combat_stats = combat_stats_data.get("combat_stats", {})
	var biome_name = LoadHandlerSingleton.get_biome_name(current_position)  # Retrieve the biome name based on position
	
	# Get current values
	var hunger_current = combat_stats.get("hunger", {}).get("current", 0)
	var fatigue_current = combat_stats.get("fatigue", {}).get("current", 0)

	# Apply effects
	hunger_current = max(hunger_current - 5, 0)  # Decrease hunger by 10
	fatigue_current = min(fatigue_current - 5, 100)  # Increase fatigue by 10, max at 100

	# Update combat stats
	combat_stats["hunger"]["current"] = hunger_current
	combat_stats["fatigue"]["current"] = fatigue_current
	
	if travel_log_control:
		var message = "Traveled through " + biome_name + "."
		if biome_name == "village":
			message = "Exploring the village."
		elif biome_name == "road":
			message = "Walking along the road."
		elif biome_name == "forest":
			message = "Venturing into the forest."
		elif biome_name == "mountains":
			message = "Climbing the mountains."
		# Add more conditions for other biomes as necessary

		travel_log_control.add_message_to_log(message)
		#print("Travel effects applied. Hunger:", hunger_current, "Fatigue:", fatigue_current)


	# Save the updated combat stats
	LoadHandlerSingleton.save_combat_stats(combat_stats_data)
	#print("Travel effects applied. Hunger:", hunger_current, "Fatigue:", fatigue_current)

	# Advance the game time by a set amount (similar to resting)
	TimeManager.pass_two_hours()  # You can change the amount of time as needed
	
	# Get the updated time data from the singleton
	var updated_time_data = LoadHandlerSingleton.get_time_and_date()  # Load updated time data

	# Call the flavor update using the updated time data
	TimeManager.update_gametime_flavor2(updated_time_data)
	
	var world_map_control = get_node("/root/WorldMapTravel")  # Adjust the node path if necessary
	if world_map_control:
		world_map_control.update_time_label()  # Update the label after the time change
		world_map_control.update_gametime_flavor()
		world_map_control.update_gametime_type()
	
	# After resting, print the current time and date again
	#print("After resting:")
	TimeManager.print_time_and_date()

