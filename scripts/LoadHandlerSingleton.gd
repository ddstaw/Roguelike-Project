extends Node

var current_chunk_id: String = ""
var current_chunk_coords: Vector2i = Vector2i.ZERO
var loaded_tile_chunks := {}
var loaded_object_chunks := {}
var loaded_npc_chunks := {}
var chunked_npc_data: Dictionary = {}

static var _chunk_structure_map: Dictionary = {}
static var _cached_egress_data := {}

const Consts = preload("res://scripts/Constants.gd")
const NodeTable := preload("res://constants/node_table.gd")
const ItemData := preload("res://constants/item_data.gd") # adjust!
const BuildData = preload("res://constants/build_data.gd")
const CraftData = preload("res://constants/crafting_blueprints.gd")
const RegisterPath := "res://characterdata/building_register.json"


var elfhaven_proper: String = "sample elf haven"  # Default values
var oldcity_proper: String = "sample old city"
var dwarfcity_proper: String = "sample dwarf city"
var capitalcity_proper: String = "sample cap city"
var villages: Dictionary = {}

# ✅ Add the signal and function HERE:
signal request_map_reload
signal inventory_changed

# -------------------------------------------------------------------
# 🌍 LOCAL MAP SAVE/LOAD
# -------------------------------------------------------------------

func trigger_map_reload():
	print("🔄 Requesting map reload...")
	request_map_reload.emit()

func load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		print("Error: File does not exist at path:", path)
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error: Failed to open file at path:", path)
		return null
	
	var json_data = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_error = json.parse(json_data)
	
	if parse_error == OK and json.data != null:
		if json.data is Dictionary:
			return json.data  # Return as Dictionary
		elif json.data is Array:
			return json.data  # Return as Array
		else:
			print("Error: Parsed JSON is neither Dictionary nor Array.")
			return null
	else:
		print("Error parsing JSON at path:", path)
		return null

# Retrieve the correct save slot number
func get_save_slot() -> int:
	var data = load_handler_data()
	return data.get("selected_save_slot", 1)

# Retrieve the base save path for the current save slot
func get_save_file_path() -> String:
	var data = load_handler_data()
	return data.get("save_file_path", "user://saves/save" + str(get_save_slot()) + "/")

# Centralized function to retrieve load_handler.json data
func load_handler_data() -> Dictionary:
	return load_json_file("user://saves/load_handler.json")


# -------------------------------------------------------------------
# 💾 SAVE / LOAD SYSTEM
# -------------------------------------------------------------------









# Retrieve paths based on the selected save slot
func get_character_creation_path() -> String:
	return get_save_file_path() + "characterdata/character_creation-save" + str(get_save_slot()) + ".json"

# Retrieve paths based on the selected save slot
func get_temp_localmap_layout_path() -> String:
	return get_save_file_path() + "local/local_temp/temp_localmap_layout" + str(get_save_slot()) + ".json"

func get_temp_localmap_placement_path() -> String:
	return get_save_file_path() + "local/local_temp/temp_localmap_placement" + str(get_save_slot()) + ".json"

func get_temp_localmap_terrain_path() -> String:
	return get_save_file_path() + "local/local_temp/temp_localmap_terrain" + str(get_save_slot()) + ".json"

func get_temp_localmap_entities_path() -> String:
	return get_save_file_path() + "local/local_temp/temp_localmap_entities" + str(get_save_slot()) + ".json"

func get_temp_localmap_objects_path() -> String:
	return get_save_file_path() + "local/local_temp/temp_localmap_objects" + str(get_save_slot()) + ".json"

func get_temp_localmap_npcs_path() -> String:
	return get_save_file_path() + "local/local_temp/temp_localmap_objects" + str(get_save_slot()) + ".json"

func get_combat_stats_path() -> String:
	return get_save_file_path() + "characterdata/combat_stats-save" + str(get_save_slot()) + ".json"

func get_skill_save_path() -> String:
	return get_save_file_path() + "characterdata/skills-save" + str(get_save_slot()) + ".json"

func get_base_attributes_path() -> String:
	return get_save_file_path() + "characterdata/base_attributes-save" + str(get_save_slot()) + ".json"

func get_worldmap_placement_path() -> String:
	return get_save_file_path() + "characterdata/worldmap_placement" + str(get_save_slot()) + ".json"

func get_basemapdata_path() -> String:
	return get_save_file_path() + "world/worldmap_basemapinfo" + str(get_save_slot()) + ".json"

func get_charstate_path() -> String:
	return get_save_file_path() + "world/char_state" + str(get_save_slot()) + ".json"

func get_citydata_path() -> String:
	return get_save_file_path() + "world/city_data" + str(get_save_slot()) + ".json"

func get_basemapsettlements_path() -> String:
	return get_save_file_path() + "world/basemapdata"  + str(get_save_slot()) + ".json"

func get_remembered_localmaps_path() -> String:
	return get_save_file_path() + "local/remembered_localmaps" + str(get_save_slot()) + ".json"

func get_investigate_localmaps_path() -> String:
	return get_save_file_path() + "local/investigate_localmaps" + str(get_save_slot()) + ".json"

func get_entry_context_path() -> String:
	return get_save_file_path() + "local/entry_context" + str(get_save_slot()) + ".json"

func get_player_gear_path() -> String:
	return get_save_file_path() + "characterdata/player_gear" + str(get_save_slot()) + ".json"

func get_player_inventory_path() -> String:
	return get_save_file_path() + "characterdata/player_inventory" + str(get_save_slot()) + ".json"

func get_player_looks_path() -> String:
	return get_save_file_path() + "characterdata/player_looks" + str(get_save_slot()) + ".json"

func get_player_effects_path() -> String:
	return get_save_file_path() + "characterdata/player_effects" + str(get_save_slot()) + ".json"


func _charstate_default() -> Dictionary:
	return {
		"character_state": {
			"incity": "N",
			"inlocalmap": "N",
			"inworldmap": "N"
		}
	}

func load_char_state() -> Dictionary:
	var path := get_charstate_path()
	if !FileAccess.file_exists(path):
		return _charstate_default()

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return _charstate_default()

	var text := f.get_as_text()
	f.close()

	var j := JSON.new()
	if j.parse(text) != OK or typeof(j.data) != TYPE_DICTIONARY:
		return _charstate_default()

	# Ensure the key exists even if file is partially formed
	var data: Dictionary = j.data
	if !data.has("character_state"):
		data["character_state"] = _charstate_default()["character_state"]
	return data

func save_char_state(data: Dictionary) -> void:
	var path := get_charstate_path()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not open char_state file for writing: %s" % path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# Call this to flip flags; values are "Y"/"N" to match your file
func set_realm_char_state(realm: String) -> void:
	var data := load_char_state()
	var cs: Dictionary = data.get("character_state", {}).duplicate()

	match realm.to_lower():
		"worldmap":
			cs["inworldmap"] = "Y"
			cs["inlocalmap"] = "N"
			cs["incity"] = "N"
		"localmap":
			cs["inworldmap"] = "N"
			cs["inlocalmap"] = "Y"
			cs["incity"] = "N"
		"city":
			cs["inworldmap"] = "N"
			cs["inlocalmap"] = "N"
			cs["incity"] = "Y"
		_:
			push_warning("Unknown realm '%s' passed to set_realm_char_state" % realm)

	data["character_state"] = cs
	save_char_state(data)



func get_effective_vision_radius() -> int:
	var base_radius := 2  # Minimum at night

	var effects = load_player_effects()
	if effects.get("has_nightvision", false):
		return 24  # Nightvision overrides everything

	# Light source check
	var light_data = get_best_equipped_light_item_with_id()
	if light_data.has("light_radius"):
		base_radius = max(base_radius, light_data["light_radius"])

	# Check sunlight for smooth radius increase
	if Engine.has_singleton("LocalMap"):
		var map = Engine.get_singleton("LocalMap")
		if map.has("sunlight_level"):
			var sunlight: float = map.sunlight_level
			var t: float = clamp(sunlight, 0.0, 1.0)
			var day_radius := 12  # max radius in daylight
			base_radius = int(round(lerp(base_radius, day_radius, t)))

	return base_radius


func load_player_effects() -> Dictionary:
	var path = get_player_effects_path()
	return load_json_file(path)

func load_player_looks() -> Dictionary:
	var path = get_player_looks_path()
	return load_json_file(path)
	
func save_player_looks(data: Dictionary) -> void:
	var path = get_player_looks_path()
	save_json_file(path, data)

func load_entry_context() -> Dictionary:
	var path = get_entry_context_path()
	return load_json_file(path)
	
func save_entry_context(data: Dictionary) -> void:
	var path = get_entry_context_path()
	save_json_file(path, data)

func load_player_gear() -> Dictionary:
	var path = get_player_gear_path()
	return load_json_file(path)
	
func load_player_inventory() -> Dictionary:
	var path = get_player_inventory_path()
	var inv: Dictionary = load_json_file(path)

	# ✅ Normalize each stack
	for uid in inv.keys():
		LoadHandlerSingleton.normalize_stack_stats(inv[uid])

	return inv

func save_player_gear(data: Dictionary) -> void:
	var path = get_player_gear_path()
	save_json_file(path, data)
	LoadHandlerSingleton.recalc_player_and_mount_weight()

func save_player_inventory(data: Dictionary) -> void:
	# If data is an inventory struct or includes inventory, normalize
	for uid in data.keys():
		normalize_stack_stats(data[uid])

	var path = get_player_inventory_path()
	save_json_file(path, data)
	LoadHandlerSingleton.recalc_player_and_mount_weight()

	
func save_base_attributes(data: Dictionary) -> void:
	var path = get_base_attributes_path()
	save_json_file(path, data)
	LoadHandlerSingleton.recalc_player_and_mount_weight()

func save_player_effects(data: Dictionary) -> void:
	var path = get_player_effects_path()
	save_json_file(path, data)

func get_tile_data_path() -> String:
	var realm = get_current_realm()
	var realm_name = ""

	# ✅ If we're in a city or dungeon, get its name
	if realm == "citymap":
		realm_name = get_current_city()

	# ✅ Construct the filename
	var filename = realm
	if realm_name != "":
		filename += "_" + realm_name  # Append city/dungeon name for uniqueness

	# ✅ Ensure the chunks directory exists (Godot 4.2.2 version)
	var chunks_folder = "user://saves/save" + str(get_save_slot()) + "/chunks/"
	var dir = DirAccess.open("user://")  # Create DirAccess instance
	if dir and not dir.dir_exists(chunks_folder):
		dir.make_dir_recursive(chunks_folder)

	var file_path = chunks_folder + filename + "_tiledata.json"

	# 🔥 If the file doesn't exist, create an empty one
	if not FileAccess.file_exists(file_path):
		var new_data = {"tiles": {}}  # Create empty tile data
		LoadHandlerSingleton.save_json_file(file_path, new_data)  # ✅ Corrected function call
		print("📄 Created new tiledata.json for:", file_path)

	return file_path



func load_settlement_names() -> void:
	var settlement_data_path = get_basemapsettlements_path()  # Get the path for basemapdata.json
	var file = FileAccess.open(settlement_data_path, FileAccess.READ)

	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data = json.data[0]  # Assuming the data structure is as you've shown
			for settlement in data["settlement_names"]:
				var biome = settlement["biome"]
				var name = settlement["settlement_name"]
				var grid_position_str = settlement["grid_position"]

				# Remove parentheses and split the string to get x and y
				var grid_position = grid_position_str.replace("(", "").replace(")", "").split(", ")


				# Assigning values based on biome
				match biome:
					"elfhaven":
						elfhaven_proper = name
					"oldcity":
						oldcity_proper = name
					"dwarfcity":
						dwarfcity_proper = name
					"capitalcity":
						capitalcity_proper = name
					"village":
						# Store villages in a dictionary by their grid position
						var village_key = Vector2(int(grid_position[0]), int(grid_position[1]))
						villages[village_key] = name  # Assuming villages is defined as a global dictionary

			print("Villages loaded:", villages)  # Debugging line to check village data

		else:
			print("Error parsing basemapdata.json:", json.get_error_message())
	else:
		print("Error: Could not open basemapdata.json.")


func get_player_position() -> Vector2:
	var path = get_worldmap_placement_path()
	var data = load_json_file(path)

	if data.has("character_position"):
		var character_position = data["character_position"]

		# Get the current realm first
		var current_realm = character_position.get("current_realm", "worldmap")
		var realm_data = character_position.get(current_realm, {})

		# Check if grid_position exists inside the correct realm
		if realm_data.has("grid_position"):
			var pos = realm_data["grid_position"]
			if typeof(pos) == TYPE_DICTIONARY and pos.has("x") and pos.has("y"):
				return Vector2(int(pos["x"]), int(pos["y"]))  # Return as Vector2
			else:
				print("Error: Grid position is not in expected format.")
		else:
			print("Error: 'grid_position' not found in", current_realm, "data.")
	else:
		print("Error: 'character_position' not found in data.")

	return Vector2(-1, -1)  # Return invalid position if something goes wrong

# ✅ Centralized function to get biome based on the current realm
func get_biome_name(position: Vector2) -> String:
	var placement_data = load_json_file(get_worldmap_placement_path())

	# Ensure character position exists
	if not placement_data.has("character_position"):
		print("❌ ERROR: No character_position found in placement data!")
		return "Unknown"

	var character_position = placement_data["character_position"]
	var current_realm = character_position.get("current_realm", "worldmap")
	var realm_data = character_position.get(current_realm, {})

	# ✅ If realm has a defined grid_position, fetch from the correct source
	if realm_data.has("grid_position"):
		if current_realm == "citymap":
			return get_biome_from_city(position, realm_data)
		else:
			return get_biome_from_world(position, realm_data)

	# ❌ Fallback if biome cannot be determined (Fix for missing return case)
	print("❌ ERROR: Biome could not be determined! Returning 'Unknown'.")
	return "Unknown"


func get_biome_from_world(position: Vector2, realm_data: Dictionary) -> String:
	var biome_map_path = get_basemapdata_path()
	var biome_map = load_json_file(biome_map_path)

	if not biome_map:
		print("❌ ERROR: Failed to load biome map from:", biome_map_path)
		return "Unknown"

	# ✅ Handle the case where biome_map is an array
	if biome_map is Array and biome_map.size() > 0:
		biome_map = biome_map[0]  # Extract the first dictionary


	# Ensure "grid" and "biomes" exist
	if not biome_map.has("grid"):
		print("❌ ERROR: 'grid' missing from biome map! Full data:", JSON.stringify(biome_map, "\t"))
		return "Unknown"

	if not biome_map["grid"].has("biomes"):
		print("❌ ERROR: 'biomes' missing inside grid data! Full grid data:", JSON.stringify(biome_map["grid"], "\t"))
		return "Unknown"

	var biomes = biome_map["grid"]["biomes"]
	var x = int(position.x)
	var y = int(position.y)

	# Ensure x, y are in valid range
	if y < 0 or y >= biomes.size():
		print("❌ ERROR: Y coordinate out of bounds!", y)
		return "Unknown"
	
	if x < 0 or x >= biomes[y].size():
		print("❌ ERROR: X coordinate out of bounds!", x)
		return "Unknown"

	var biome_name = biomes[y][x]

	#print("✅ Found biome:", biome_name, "at position:", position)

	return biome_name


# ✅ Retrieves biome from the city grid
func get_biome_from_city(position: Vector2, realm_data: Dictionary) -> String:
	if not realm_data.has("city_grid"):
		print("❌ ERROR: No city grid found for citymap realm!")
		return "Unknown"

	var city_grid_path = realm_data["city_grid"]
	var city_grid_data = load_json_file(city_grid_path)

	# Extract biome grid
	if city_grid_data.has("grid") and city_grid_data["grid"].has("biomes"):
		var biomes = city_grid_data["grid"]["biomes"]
		var x = int(position.x)
		var y = int(position.y)

		if y < biomes.size() and x < biomes[y].size():
			return biomes[y][x]

	print("❌ ERROR: Could not find biome in city map!")
	return "Unknown"

# Function to get the world name from basemapdata JSON
func get_world_name() -> String:
	var path = get_basemapdata_path()
	var data = load_json_file(path)
	if data.size() > 0 and data[0].has("world_name"):
		return data[0]["world_name"]
	return "Unknown"

# Function to get grid data from basemapdata JSON
func get_grid_data() -> Variant:
	var path = get_basemapdata_path()
	var data = load_json_file(path)
	
	# Check if the data contains grid information
	if data.size() > 0 and data[0].has("grid"):
		return data[0]["grid"]
	
	return {}

# Function to get the player's name from character creation JSON
func get_player_name() -> String:
	var path = get_character_creation_path()
	var data = load_json_file(path)
	if data.has("character") and data["character"].has("name"):
		return data["character"]["name"]
	return "Unknown"

# Function to get the time and date from globaldata/timedate JSON
func get_time_and_date() -> Dictionary:
	var path = get_save_file_path() + "globaldata/timedate" + str(get_save_slot()) + ".json"
	return load_json_file(path)

# Function to get base attributes from the JSON file
func get_base_attributes() -> Dictionary:
	var path = get_base_attributes_path()
	return load_json_file(path)

# Function to get combat stats from the JSON file
func get_combat_stats() -> Dictionary:
	var path = get_combat_stats_path()
	return load_json_file(path)

# Function to get game time type from the JSON file (assuming it's in a timedate file)
func get_gametimetype() -> String:
	var path = get_save_file_path() + "globaldata/timedate" + str(get_save_slot()) + ".json"
	var data = load_json_file(path)
	
	if data.has("gametimetype"):
		return data["gametimetype"]
	else:
		print("Error: gametimetype not found in the JSON.")
		return ""

# Function to get the game weather from the JSON file (assuming it's in a timedate file)
func get_gameweather() -> String:
	var path = get_save_file_path() + "globaldata/timedate" + str(get_save_slot()) + ".json"
	var data = load_json_file(path)
	
	if data.has("gameweather"):
		return data["gameweather"]
	else:
		print("Error: Weather not found in the JSON.")
		return "Unknown"

# Function to get the date from the JSON file (assuming it's in a timedate file)
func get_date_name() -> String:
	var path = get_save_file_path() + "globaldata/timedate" + str(get_save_slot()) + ".json"
	var data = load_json_file(path)
	
	if data.has("gamedate"):
		return data["gamedate"]
	else:
		print("Error: Date not found in the JSON.")
		return "Unknown"

func get_gametimeflavorlocal_image() -> Texture:
	var path = get_save_file_path() + "globaldata/timedate" + str(get_save_slot()) + ".json"
	var data = load_json_file(path)

	if data.has("gametimeflavorlocal"):
		var image_path = data["gametimeflavorlocal"]
		var flavor_texture = load(image_path)
		if flavor_texture:
			return flavor_texture
		else:
			print("Error: Failed to load local flavor texture:", image_path)
			return null
	else:
		print("Error: gametimeflavorlocal not found in JSON.")
		return null


# Function to get the game time flavor image path from the JSON file
func get_gametimeflavor_image() -> Texture:
	var path = get_save_file_path() + "globaldata/timedate" + str(get_save_slot()) + ".json"
	var data = load_json_file(path)

	if data.has("gametimeflavor"):
		var image_path = data["gametimeflavor"]
		var flavor_texture = load(image_path)  # Load the texture from the path in the JSON
		if flavor_texture:
			return flavor_texture
		else:
			print("Error: Failed to load texture from path:", image_path)
			return null
	else:
		print("Error: flavor_image not found in the JSON.")
		return null

func save_combat_stats(combat_stats_data: Dictionary) -> void:
	var path = get_combat_stats_path()  # Get the file path where the combat stats are stored
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file != null:
		var json_string = JSON.stringify(combat_stats_data, "\t", true)  # Add indentation with tabs for better formatting
		file.store_string(json_string)  # Write the modified stats to the file
		file.close()
		#print("Combat stats saved successfully to path: ", path)  # Use regular print in Godot 4
	else:
		print("Error: Unable to save combat stats.")

# LoadHandlerSingleton.gd
func get_city_grid_data() -> Dictionary:
	var city_name = get_current_city_name()  # Assume we have a function that retrieves the current city name
	var city_map_path = get_save_file_path() + "chunks/" + city_name.replace(" ", "_") + "_grid.json"
	var city_map_data = load_json_file(city_map_path)

	if city_map_data.has("grid"):
		return city_map_data["grid"]
	else:
		print("Error: City grid data not found.")
		return {}

func get_current_city_name() -> String:
	var player_pos = get_player_position()  # Get the current player position
	var city_data_path = get_citydata_path()  # Load city_data1.json
	var city_data = load_json_file(city_data_path)

	if city_data.has("city_data"):
		for city_name in city_data["city_data"].keys():
			var city_info = city_data["city_data"][city_name]
			var city_position = parse_position(city_info["worldmap-location"])
			if player_pos == city_position:
				return city_name

	print("Error: No city found at the player's current position.")
	return ""


# LoadHandlerSingleton.gd
func parse_position(position_str: String) -> Vector2:
	# Remove parentheses and split the string to get x and y values
	position_str = position_str.trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")
	return Vector2(pos[0].to_int(), pos[1].to_int())

func get_current_realm() -> String:
	var path = get_worldmap_placement_path()
	var data = load_json_file(path)

	if data.has("character_position"):
		var character_position = data["character_position"]
		return character_position.get("current_realm", "worldmap")  # Default to worldmap if missing

	print("❌ Error: 'character_position' not found in data. Returning worldmap.")
	return "worldmap"

# ✅ Function to properly switch realms & update biome instantly
func set_current_realm(new_realm: String):
	var placement_data = load_json_file(get_worldmap_placement_path())

	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# ✅ If the realm is actually changing, update it
		if character_position.get("current_realm", "") != new_realm:
			character_position["current_realm"] = new_realm

			# ✅ Fetch new position and biome
			var new_position = character_position.get(new_realm, {}).get("grid_position", Vector2.ZERO)
			var new_biome = get_biome_name(new_position)
			var new_cell_name = "cell_" + str(new_position.x) + "_" + str(new_position.y)

			# ✅ Ensure biome is updated in JSON
			update_biome_and_cell_in_json(new_biome, new_cell_name)

			# ✅ Save the updated JSON
			var file = FileAccess.open(get_worldmap_placement_path(), FileAccess.WRITE)
			file.store_string(JSON.stringify(placement_data, "\t"))
			file.close()

			print("🌍 Realm changed to:", new_realm, "| Biome refreshed:", new_biome)
	else:
		print("❌ ERROR: 'character_position' not found while changing realm!")

func update_biome_and_cell_in_json(new_biome: String, new_cell_name: String):
	var placement_data = load_json_file(get_worldmap_placement_path())

	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]
		var current_realm = character_position.get("current_realm", "worldmap")
		var realm_data = character_position.get(current_realm, {})

		realm_data["biome"] = new_biome
		realm_data["cell_name"] = new_cell_name
		character_position[current_realm] = realm_data

		# ✅ Save changes
		var file = FileAccess.open(get_worldmap_placement_path(), FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(placement_data, "\t"))
			file.close()
			#print("✅ JSON Updated: Biome is now", new_biome, "in", current_realm)
		else:
			print("❌ ERROR: Failed to save biome data.")
	else:
		print("❌ ERROR: 'character_position' not found in JSON.")

func get_current_city() -> String:
	# Load character position data
	var placement_data = load_json_file(get_worldmap_placement_path())

	# Ensure character_position exists
	if placement_data.has("character_position"):
		var character_position = placement_data["character_position"]

		# Check if current_realm is citymap and get city name
		if character_position.get("current_realm", "") == "citymap" and character_position.has("citymap"):
			return character_position["citymap"].get("name", "Unknown City")

	print("❌ ERROR: City name not found in placement data!")
	return "Unknown City"

func get_remember_name() -> String:
	var path = get_save_file_path() + "local/remembered_localmaps" + str(get_save_slot()) + ".json"
	var data = load_json_file(path)
	
	if data.has("gamedate"):
		return data["gamedate"]
	else:
		print("Error: Date not found in the JSON.")
		return "Unknown"

func save_json_file(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))  # ✅ Pretty formatting with tabs
		file.close()
		#print("💾 Saved JSON file:", path)
	else:
		print("❌ Error: Unable to save JSON file at path:", path)
		
func save_temp_localmap_layout(grid: Array):
	var layout_data := {}

	if grid.is_empty():
		print("❌ Grid is empty in save_temp_localmap_layout!")
		return

	for x in range(grid.size()):
		if typeof(grid[x]) != TYPE_ARRAY:
			print("⚠️ Row", x, "is not an array! Skipping.")
			continue

		for y in range(grid[x].size()):
			var key = "%d_%d" % [x, y]
			var tile_info = grid[x][y]

			if typeof(tile_info) == TYPE_DICTIONARY and tile_info.has("tile"):
				var tile_name = tile_info["tile"]
				var tile_state = tile_info.get("state", {})
				layout_data[key] = {
					"tile": tile_name,
					"state": tile_state
				}
			else:
				print("❌ Invalid tile_info at (%d, %d) → %s" % [x, y, str(tile_info)])
				layout_data[key] = {
					"tile": "unknown",
					"state": {}
				}

	var full_data = { "tile_grid": layout_data }
	var path = LoadHandlerSingleton.get_temp_localmap_layout_path()
	LoadHandlerSingleton.save_json_file(path, full_data)
	print("💾 Layout saved to:", path)

func get_tile_name(tile_entry) -> String:
	if typeof(tile_entry) == TYPE_DICTIONARY and tile_entry.has("tile"):
		return tile_entry["tile"]
	elif typeof(tile_entry) == TYPE_OBJECT and tile_entry is Texture2D:
		return Constants.TEXTURE_TO_NAME.get(tile_entry, "unknown")
	else:
		return "unknown"


func save_temp_localmap_entities(entities: Dictionary):
	var path = LoadHandlerSingleton.get_temp_localmap_entities_path()
	LoadHandlerSingleton.save_json_file(path, { "entities": entities })
	print("💾 Entities saved to:", path)

func save_temp_localmap_objects(objects: Dictionary):
	var path = LoadHandlerSingleton.get_temp_localmap_objects_path()
	LoadHandlerSingleton.save_json_file(path, { "objects": objects })
	print("💾 Objects saved to:", path)


func save_localmap_terrain():
	var path = LoadHandlerSingleton.get_temp_localmap_terrain_path()
	LoadHandlerSingleton.save_json_file(path, { "modified_terrain": {} })
	print("🪨 Blank terrain state saved.")


func load_temp_localmap_placement() -> Dictionary:
	var path = get_temp_localmap_placement_path()
	return load_json_file(path)

func load_temp_localmap_layout() -> Array:
	var path: String = get_temp_localmap_layout_path()
	if not FileAccess.file_exists(path):
		print("❌ Layout file not found:", path)
		return []

	var json: Dictionary = load_json_file(path)
	if not json.has("tile_grid"):
		print("❌ tile_grid key missing in layout JSON!")
		return []

	var tile_grid_dict: Dictionary = json["tile_grid"]
	var max_x: int = 0
	var max_y: int = 0

	# 🧠 Dynamically determine max dimensions
	for key: String in tile_grid_dict.keys():
		var parts: PackedStringArray = key.split("_")
		if parts.size() != 2:
			continue
		var x: int = parts[0].to_int()
		var y: int = parts[1].to_int()
		max_x = max(max_x, x)
		max_y = max(max_y, y)

	var grid: Array = []
	for x in range(max_x + 1):
		var row: Array = []
		for y in range(max_y + 1):
			var key: String = "%d_%d" % [x, y]
			var tile_entry: Dictionary = tile_grid_dict.get(key, {})
			var tile_name: String = tile_entry.get("tile", "grass")
			row.append(get_texture_from_name(tile_name))
		grid.append(row)

	return grid


func get_texture_from_name(name: String) -> Texture2D:
	return Constants.TILE_TEXTURES.get(name, null)

func build_object_layer_from_objects(width: int, height: int, objects: Dictionary) -> Array:
	var layer = []
	for x in range(width):
		layer.append([])
		for y in range(height):
			layer[x].append(null)

	for obj_id in objects:
		var obj = objects[obj_id]
		if obj.has("position") and obj.has("type"):
			var pos = obj["position"]
			var x = int(pos["x"])
			var y = int(pos["y"])
			var type = obj["type"]

			var texture = Constants.get_object_texture(type)

			# 🔁 Fallback to per-object texture (used by mounts, etc)
			if (texture == null) and obj.has("texture"):
				texture = load(obj["texture"])

			# ✅ Debug output
			print("🧱 Object [%s] at (%d, %d) — texture: %s" % [type, x, y, texture])

			# ✅ Bounds safety
			if x >= 0 and x < width and y >= 0 and y < height:
				layer[x][y] = texture
			else:
				print("⚠️ Skipping object out of bounds: (%d, %d)" % [x, y])
		else:
			print("⚠️ Object missing 'position' or 'type':", obj_id)

	return layer

func build_npc_layer_from_npcs(width: int, height: int, npcs: Dictionary) -> Array:
	var layer = []
	for x in range(width):
		layer.append([])
		for y in range(height):
			layer[x].append(null)

	for npc_id in npcs:
		var npc = npcs[npc_id]
		if npc.has("position") and npc.has("type"):
			var pos = npc["position"]
			var x = int(pos["x"])
			var y = int(pos["y"])
			var type = npc["type"]

			var texture = Constants.get_npc_texture(type)

			# 🔁 Fallback to per-npc texture (used by mounts, etc)
			if (texture == null) and npc.has("texture"):
				texture = load(npc["texture"])

			# ✅ Debug output
			print("🧱 Npc [%s] at (%d, %d) — texture: %s" % [type, x, y, texture])

			# ✅ Bounds safety
			if x >= 0 and x < width and y >= 0 and y < height:
				layer[x][y] = texture
			else:
				print("⚠️ Skipping object out of bounds: (%d, %d)" % [x, y])
		else:
			print("⚠️ NPC missing 'position' or 'type':", npc_id)

	return layer


func load_temp_localmap_objects() -> Dictionary:
	var path = get_temp_localmap_objects_path()
	if not FileAccess.file_exists(path):
		print("❌ ERROR: temp_localmap_objects.json not found at:", path)
		return {}
	
	var data = load_json_file(path)
	if data.has("objects"):
		return data["objects"]
	else:
		print("⚠️ WARNING: 'objects' key missing in objects file at:", path)
		return {}

func load_temp_localmap_npcs() -> Dictionary:
	var path = get_temp_localmap_npcs_path()
	if not FileAccess.file_exists(path):
		print("❌ ERROR: temp_localmap_npcs.json not found at:", path)
		return {}
	
	var data = load_json_file(path)
	if data.has("npcs"):
		return data["npcs"]
	else:
		print("⚠️ WARNING: 'npcs' key missing in npcs file at:", path)
		return {}

func get_current_mount_data() -> Dictionary:
	var gear_path = get_player_gear_path()
	var gear_data = load_json_file(gear_path)

	if gear_data == null:
		print("⚠️ Warning: Player gear file not found or invalid. Defaulting to 'None' mount.")
		return get_mount_data_by_id("None")

	var mount_id = gear_data.get("mount", "None")
	return get_mount_data_by_id(mount_id)

func get_mount_data_by_id(mount_id: String) -> Dictionary:
	var mount_types_path = "res://data/mount_types.json"
	var mount_types = load_json_file(mount_types_path)

	if mount_types == null:
		print("❌ ERROR: Failed to load mount_types.json")
		return {}

	# If the mount ID isn't found, fall back to 'None'
	if not mount_types.has(mount_id):
		print("⚠️ Warning: Mount ID '%s' not found. Using 'None'." % mount_id)
		return mount_types.get("None", {})

	return mount_types[mount_id]

func get_current_left_hand_data() -> Dictionary:
	var gear_path = get_player_gear_path()
	var gear_data = load_json_file(gear_path)

	if gear_data == null:
		print("⚠️ Warning: Player gear file not found or invalid. Defaulting to 'empty'.")
		return get_hand_item_data_by_id("empty")

	var item_id = gear_data.get("left_hand", "empty")
	return get_hand_item_data_by_id(item_id)

func get_current_right_hand_data() -> Dictionary:
	var gear_path = get_player_gear_path()
	var gear_data = load_json_file(gear_path)

	if gear_data == null:
		print("⚠️ Warning: Player gear file not found or invalid. Defaulting to 'empty'.")
		return get_hand_item_data_by_id("empty")

	var item_id = gear_data.get("right_hand", "empty")
	return get_hand_item_data_by_id(item_id)

func get_hand_item_data_by_id(item_id: String) -> Dictionary:
	var inventory = load_json_file(get_player_inventory_path())
	if inventory == null:
		print("❌ ERROR: Could not load player inventory!")
		return {}

	if not inventory.has(item_id):
		print("⚠️ Warning: Item ID '%s' not found in inventory." % item_id)
		return {}

	return inventory[item_id]

	
func get_current_belt_data() -> Dictionary:
	var gear_data = load_json_file(get_player_gear_path())
	if gear_data == null:
		print("⚠️ Gear file missing or invalid. Belt fallback to 'empty'")
		return get_hand_item_data_by_id("empty")
	var belt_id = gear_data.get("belt", "empty")
	return get_hand_item_data_by_id(belt_id)

func get_current_pack_mod_data() -> Dictionary:
	var gear_data = load_json_file(get_player_gear_path())
	if gear_data == null:
		print("⚠️ Gear file missing or invalid. Pack mod fallback to 'empty'")
		return get_hand_item_data_by_id("empty")
	var pack_mod_id = gear_data.get("pack_mod_slot", "empty")
	return get_hand_item_data_by_id(pack_mod_id)


func get_all_equipped_light_sources() -> Array:
	var equipped_sources: Array = []

	var gear_data = load_json_file(get_player_gear_path())
	if gear_data == null:
		#print("⚠️ Gear file missing. No light sources equipped.")
		return equipped_sources

	var slots = [
		gear_data.get("left_hand", "empty"),
		gear_data.get("right_hand", "empty"),
		gear_data.get("belt", "empty"),
		gear_data.get("pack_mod_slot", "empty")
	]

	var all_item_data = load_json_file("res://data/inhand_items.json")
	if all_item_data == null:
		#print("❌ ERROR: Failed to load inhand_items.json")
		return equipped_sources

	for slot_id in slots:
		if all_item_data.has(slot_id):
			var item = all_item_data[slot_id]
			if item.has("light_radius") and item["light_radius"] > 0:
				equipped_sources.append(item)

	return equipped_sources

func build_walkability_grid(tile_grid_raw: Dictionary, object_data_raw: Dictionary) -> Array:
	var walkability_grid: Array = []

	# Determine full grid dimensions
	var max_x: int = 0
	var max_y: int = 0
	for key in tile_grid_raw.keys():
		var parts: PackedStringArray = key.split("_")
		if parts.size() != 2:
			continue
		var x: int = parts[0].to_int()
		var y: int = parts[1].to_int()
		max_x = max(max_x, x)
		max_y = max(max_y, y)

	max_x += 1
	max_y += 1

	#print("📏 Detected tile grid size — max_x:", max_x, "max_y:", max_y)

	# Initialize the walkability grid
	for y in range(max_y):
		walkability_grid.append([])
		for x in range(max_x):
			walkability_grid[y].append({
				"walkable": true,
				"transparent": true,
				"terrain_type": "",
				"object_type": "",
				"is_open": true
			})

	# Fill terrain info from the tile data
	for key in tile_grid_raw.keys():
		var parts: PackedStringArray = key.split("_")
		if parts.size() != 2:
			continue
		var x: int = parts[0].to_int()
		var y: int = parts[1].to_int()
		if y >= walkability_grid.size() or x >= walkability_grid[y].size():
			continue

		var tile_info: Dictionary = tile_grid_raw.get(key, {})
		var terrain_type: String = tile_info.get("tile", "")
		var state: Dictionary = tile_info.get("state", {})

		walkability_grid[y][x]["terrain_type"] = terrain_type
		walkability_grid[y][x]["is_open"] = state.get("is_open", true)
		walkability_grid[y][x]["tile_state"] = state

	# Fill object info from flat-format object data
	#print("🧱 Processing %d object(s) into walk grid..." % object_data_raw.size())
	for obj_id in object_data_raw.keys():
		var obj: Dictionary = object_data_raw[obj_id]
		if obj.has("position") and obj.has("type"):
			var pos: Dictionary = obj["position"]
			var x: int = int(pos.get("x", -1))
			var y: int = int(pos.get("y", -1))
			var obj_type: String = obj["type"]

			if x == -1 or y == -1:
				#print("⚠️ Skipping malformed object:", obj_id)
				continue

			if y < walkability_grid.size() and x < walkability_grid[y].size():
				walkability_grid[y][x]["object_type"] = obj_type
				#print("✅ Added object to grid:", obj_id, "→", obj_type, "at", x, y)
			else:
				print("❌ Object out of bounds:", obj_id, "→", x, y, "grid size:", max_x, "x", max_y)
		else:
			print("⚠️ Skipping object missing position/type:", obj_id)

	# Final walkability logic
	for y in range(max_y):
		for x in range(max_x):
			var cell: Dictionary = walkability_grid[y][x]
			var terrain_type: String = cell["terrain_type"]
			var object_type: String = cell["object_type"]
			var tile_state: Dictionary = cell.get("tile_state", {})

			cell["walkable"] = not Consts.is_blocking_movement(terrain_type, object_type, tile_state)
			cell["transparent"] = not Consts.is_blocking_vision(terrain_type, object_type, tile_state)

	return walkability_grid


func load_temp_localmap_tile_dict() -> Dictionary:
	var path = get_temp_localmap_layout_path()
	print("📄 Trying to load tile dict from:", path)

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var full_data = JSON.parse_string(file.get_as_text())
		var tile_grid = full_data.get("tile_grid", {})

		return tile_grid
	else:
		print("❌ Could not open tile layout file at path:", path)

	return {}

func get_best_equipped_light_item_with_id() -> Dictionary:
	var gear_data: Dictionary = load_json_file(get_player_gear_path())
	var inventory: Dictionary = load_json_file(get_player_inventory_path())
	if gear_data == null or inventory == null:
		print("⚠️ Missing gear or inventory.")
		return {}

	var best_item: Dictionary = {}
	var best_radius: int = -1
	var slot_keys: Array[String] = ["left_hand", "right_hand", "belt_aux", "pack_mod_slot"]

	for slot in slot_keys:
		var uid: String = gear_data.get(slot, "empty")
		if uid == "empty" or not inventory.has(uid):
			continue

		var item: Dictionary = inventory[uid]
		var item_id: String = item.get("item_ID", "")
		
		if not ItemData.ITEM_PROPERTIES.has(item_id):
			continue

		var base = ItemData.ITEM_PROPERTIES[item_id]
		var merged: Dictionary = base.duplicate(true)
		for k in item.keys():
			merged[k] = item[k]

		var tags: Array = merged.get("tags", [])
		if "light-tool" in tags:
			var radius: int = int(merged.get("light_radius", 0))
			if radius > best_radius:
				best_radius = radius
				best_item = merged
				best_item["instance_id"] = uid  # Include for reference

	return best_item


func is_light_source_equipped() -> bool:
	var item = get_best_equipped_light_item_with_id()
	return item.has("light_radius") and item["light_radius"] > 0

func get_player_light_radius() -> int:
	if LoadHandlerSingleton.player_has_nightvision():
		return 24  # Full nightvision range

	var light_item = get_best_equipped_light_item_with_id()
	return light_item.get("light_radius", 0)


func player_has_nightvision() -> bool:
	var effects = load_player_effects()
	return effects.get("has_nightvision", false)


func get_player_light_color() -> Color:
	if player_has_nightvision():
		return Color(1, 1, 1)

	var best = get_best_equipped_light_item_with_id()
	if best.has("light_tint"):
		var tint = best["light_tint"]
		return Color(tint[0], tint[1], tint[2])
	return Color(0.1, 0.1, 0.2)  # fallback "barely seeing"

func is_underground() -> bool:
	var placement = LoadHandlerSingleton.load_temp_localmap_placement()
	return placement.get("local_map", {}).get("z_level", 0) < 0

func save_all_chunked_localmap_files( 
	grid_chunks: Dictionary,
	object_chunks: Dictionary,
	entities := {},  # 👈 This will be used for NPCs
	terrain_mods := {},
	biome_key: String = "gef"
) -> void:
	# 🗃️ Save unified, multi-chunk versions for debug or legacy fallback
	save_chunked_localmap_layout(grid_chunks)
	save_chunked_localmap_objects(object_chunks)
	save_chunked_localmap_entities(entities)
	save_chunked_localmap_terrain()

	# 💾 Save each individual tile chunk file (with normalized keys)
	for chunk_id in grid_chunks.keys():
		var tile_data: Dictionary = grid_chunks[chunk_id]

		if typeof(tile_data) != TYPE_DICTIONARY:
			continue

		var raw_tile_grid = tile_data.get("tile_grid", {})
		var normalized_grid = raw_tile_grid  # Already local

		var chunk_origin: Vector2i = get_chunk_origin(chunk_id)
		var tile_path = get_chunked_tile_chunk_path(chunk_id, biome_key)

		var payload := {
			"chunk_coords": chunk_id.replace("chunk_", ""),
			"chunk_origin": { "x": chunk_origin.x, "y": chunk_origin.y },
			"tile_grid": normalized_grid
		}

		save_json_file(tile_path, payload)

	# 💾 Save each individual object chunk file (with normalized positions)
	for chunk_id in object_chunks.keys():
		var object_data: Dictionary = object_chunks[chunk_id]

		if typeof(object_data) != TYPE_DICTIONARY:
			continue

		var normalized_objects = normalize_object_positions_in_chunk(object_data, chunk_id)
		var obj_path = get_chunked_object_chunk_path(chunk_id, biome_key)

		save_json_file(obj_path, normalized_objects)

	# 💾 Save each individual NPC chunk file (raw for now — add normalization later)
	for chunk_id in entities.keys():
		var npc_data: Dictionary = entities[chunk_id]

		if typeof(npc_data) != TYPE_DICTIONARY:
			continue

		var npc_path = get_chunked_npc_chunk_path(chunk_id, biome_key)
		save_json_file(npc_path, npc_data)

	# ✅ Update placement file
	save_chunked_localmap_placement()

func save_chunked_localmap_layout(chunk_data: Dictionary):
	var layout_path = get_temp_localmap_layout_path()
	var full_data = { "chunks": chunk_data }
	save_json_file(layout_path, full_data)

func save_chunked_localmap_objects(chunked_objects: Dictionary):
	var objects_path = get_temp_localmap_objects_path()
	save_json_file(objects_path, { "chunks": chunked_objects })

func save_chunked_localmap_npcs(chunked_npcs: Dictionary):
	var npcs_path = get_temp_localmap_npcs_path()
	save_json_file(npcs_path, { "chunks": chunked_npcs })


func save_chunked_localmap_terrain():
	var path = get_temp_localmap_terrain_path()
	save_json_file(path, { "modified_terrain": {} })

func save_chunked_localmap_entities(entities: Dictionary):
	var path = get_temp_localmap_entities_path()
	save_json_file(path, { "entities": entities })
	
func chunked_mount_placement(chunk_key: String) -> void:

	var placement_file := LoadHandlerSingleton.load_temp_localmap_placement()
	if placement_file == null or not placement_file.has("local_map"):
		return

	# 🔍 Pull blueprint-driven chunk size + origin safely
	var chunk_blueprints: Dictionary = placement_file["local_map"].get("chunk_blueprints", {})
	if not chunk_blueprints.has(chunk_key):
		return

	var blueprint: Dictionary = chunk_blueprints.get(chunk_key, {})
	if not blueprint.has("size") or not blueprint.has("origin"):
		return

	var raw_size = blueprint["size"]
	var raw_origin = blueprint["origin"]

	if typeof(raw_size) != TYPE_ARRAY or raw_size.size() != 2:
		return
	if typeof(raw_origin) != TYPE_ARRAY or raw_origin.size() != 2:
		#print("❌ ERROR: Invalid origin format in blueprint for %s: %s" % [chunk_key, str(raw_origin)])
		return

	var chunk_size: Vector2i = Vector2i(raw_size[0], raw_size[1])
	var chunk_origin: Vector2i = Vector2i(raw_origin[0], raw_origin[1])
	var biome_key: String = placement_file.local_map.get("biome_key", "gef")  # Fallback to "gef" if not set
	
	#print("🔎 chunk_key =", chunk_key)
	#print("🔎 biome_key =", biome_key)

	var tile_chunk_raw = load_json_file(get_chunked_tile_chunk_path(chunk_key, biome_key))
	if tile_chunk_raw == null:
		#print("❌ ERROR: Failed to load tile chunk for", chunk_key)
		return

	var tile_chunk = tile_chunk_raw as Dictionary
	if tile_chunk == null or not tile_chunk.has("tile_grid"):
		#print("❌ ERROR: Invalid or missing tile data for", chunk_key)
		return

	var object_data_raw = load_json_file(get_chunked_object_chunk_path(chunk_key, biome_key))
	if object_data_raw == null:
		#print("❌ ERROR: Failed to load object chunk for", chunk_key)
		return

	var object_data = object_data_raw as Dictionary
	if object_data == null:
		#print("⚠️ Warning: Object chunk isn't a dictionary — defaulting to empty.")
		object_data = {}

	var tile_data: Dictionary = tile_chunk["tile_grid"]
	var valid_terrain_types := ["grass", "path"]  # TODO: biome-dependent later
	var occupied_positions := {}

	for id in object_data.keys():
		var pos: Dictionary = object_data[id].get("position", {})
		if pos.has("x") and pos.has("y"):
			occupied_positions[Vector2i(pos["x"], pos["y"])] = true

	# 🧭 Use center of chunk by default
	var center := Vector2i(chunk_size.x / 2, chunk_size.y / 2)
	var local_spawn := center
	var global_spawn := chunk_origin + local_spawn

	#print("🔍 Chunk Size:", chunk_size)
	#print("🔍 Spawn Center:", local_spawn)
	#print("🔍 Occupied Positions:", occupied_positions.size())

	var mount_data := LoadHandlerSingleton.get_current_mount_data()
	var raw_tiles := mount_data.get("tiles", []) as Array
	var mount_tiles: Array[Dictionary] = []
	for tile in raw_tiles:
		if typeof(tile) == TYPE_DICTIONARY:
			mount_tiles.append(tile)

	var mount_size_data: Array = mount_data.get("size", [0, 0])
	var mount_size := Vector2i(mount_size_data[0], mount_size_data[1])

	if mount_tiles.size() > 0 and mount_size.x > 0:
		var candidates: Array[Vector2i] = []
		var radius := 6
		var safe_margin := 5

		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var base := local_spawn + Vector2i(dx, dy)
				if base.x < safe_margin or base.x >= chunk_size.x - safe_margin:
					continue
				if base.y < safe_margin or base.y >= chunk_size.y - safe_margin:
					continue

				var can_place := true
				for entry in mount_tiles:
					var offset := Vector2i(entry["offset"][0], entry["offset"][1])
					var pos := base + offset
					var key := "%d_%d" % [pos.x, pos.y]

					if not tile_data.has(key):
						#print("⛔ REJECTED %s — no tile" % key)
						can_place = false
						break

					var terrain: String = tile_data[key].get("tile", "")
					if terrain not in valid_terrain_types:
						#print("⛔ REJECTED %s — bad terrain: %s" % [key, terrain])
						can_place = false
						break

					if occupied_positions.has(pos):
						#print("⛔ REJECTED %s — already occupied" % key)
						can_place = false
						break

					if pos == local_spawn:
						#print("⛔ REJECTED %s — same as player spawn" % key)
						can_place = false
						break

				if can_place:
					candidates.append(base)

		#print("🔎 Found", candidates.size(), "valid mount placement candidates.")

		if candidates.size() > 0:
			var base_mount_pos: Vector2i = candidates.front()
			var mount_id := 0
			for entry in mount_tiles:
				var offset := Vector2i(entry["offset"][0], entry["offset"][1])
				var pos: Vector2i = base_mount_pos + offset
				var mount_key := "mount_%d" % mount_id
				mount_id += 1

				object_data[mount_key] = {
					"position": { "x": pos.x, "y": pos.y, "z": 0 },
					"type": "mount",
					"texture": entry["texture"]
				}

			print("✅ 1Mount placed at:", base_mount_pos)
		else:
			print("⚠️ No valid mount placement for chunk:", chunk_key)

	else:
		print("⚠️ Mount tiles or size invalid!")
	
	save_json_file(get_chunked_object_chunk_path(chunk_key, biome_key), object_data)

func save_chunked_localmap_placement():
	var player_pos: Vector2i = get_player_position()
	var biome := get_biome_name(player_pos)
	var spawn_chunk: String = Consts.get_spawn_chunk_for_biome(biome)
	var spawn_offset: Vector2i = Consts.get_spawn_offset_for_biome(biome)
	var cell_name: String = "cell_%d_%d" % [player_pos.x, player_pos.y]

	var placement_file := LoadHandlerSingleton.load_temp_localmap_placement()
	if placement_file == null or not placement_file.has("local_map"):
		#print("❌ ERROR: Invalid placement file!")
		return

	var chunk_key: String = placement_file.local_map.get("current_chunk_id", spawn_chunk)
	var chunk_blueprints = placement_file.local_map.get("chunk_blueprints", {})

	if not chunk_blueprints.has(chunk_key):
		#print("❌ ERROR: Missing blueprint for chunk:", chunk_key)
		return

	var blueprint: Dictionary = chunk_blueprints[chunk_key]
	var chunk_origin := Vector2i(blueprint["origin"][0], blueprint["origin"][1])
	var chunk_size := Vector2i(50, 50)  # fallback
	if blueprint.has("size"):
		chunk_size = Vector2i(blueprint["size"][0], blueprint["size"][1])

	# Clamp spawn offset to chunk bounds to avoid out-of-bounds spawn
	spawn_offset.x = clamp(spawn_offset.x, 0, chunk_size.x - 1)
	spawn_offset.y = clamp(spawn_offset.y, 0, chunk_size.y - 1)

	var biome_key: String = placement_file.local_map.get("biome_key", "gef")  # Fallback to "gef" if not set

	var z_level = int(placement_file["local_map"].get("z_level", 0))


	var tile_chunk_data = load_json_file(get_chunked_tile_chunk_path(chunk_key, biome_key, str(z_level)))
	if tile_chunk_data == null or not tile_chunk_data.has("tile_grid"):
		#print("❌ ERROR: Failed to load tile grid from chunk:", chunk_key)
		return
	var tile_chunk: Dictionary = tile_chunk_data

	var object_data_raw = load_json_file(get_chunked_object_chunk_path(chunk_key, biome_key, str(z_level)))
	var object_data: Dictionary = {}
	if object_data_raw != null and typeof(object_data_raw) == TYPE_DICTIONARY:
		object_data = object_data_raw
	else:
		print("⚠️ Warning: Object chunk missing or malformed for:", chunk_key)
	
	var npc_data_raw = load_json_file(get_chunked_npc_chunk_path(chunk_key, biome_key, str(z_level)))
	var npc_data: Dictionary = {}
	if npc_data_raw != null and typeof(npc_data_raw) == TYPE_DICTIONARY:
		npc_data = npc_data_raw
	else:
		print("⚠️ Warning: NPC chunk missing or malformed for:", chunk_key)


	if tile_chunk == null or not tile_chunk.has("tile_grid"):
		#print("❌ ERROR: Failed to load tile grid from chunk:", chunk_key)
		return
	if typeof(object_data) != TYPE_DICTIONARY:
		object_data = {}

	var tile_data: Dictionary = tile_chunk["tile_grid"]
	var occupied_positions: Dictionary = {}
	for id in object_data.keys():
		var pos = object_data[id].get("position", {})
		if pos.has("x") and pos.has("y"):
			occupied_positions[Vector2i(pos["x"], pos["y"])] = true

	var valid_spawn_tiles: Array[Vector2i] = []
	var valid_terrain_types: Array[String] = ["grass", "path"]

	for key in tile_data.keys():
		var parts = key.split("_")
		if parts.size() != 2:
			continue
		var x = parts[0].to_int()
		var y = parts[1].to_int()
		var pos = Vector2i(x, y)
		var terrain = tile_data[key].get("tile", "")

		if terrain in valid_terrain_types and not occupied_positions.has(pos):
			valid_spawn_tiles.append(pos)

	var local_spawn = spawn_offset
	if valid_spawn_tiles.size() > 0:
		valid_spawn_tiles.sort_custom(func(a, b):
			return Vector2(a).distance_squared_to(spawn_offset) < Vector2(b).distance_squared_to(spawn_offset)
		)
		local_spawn = valid_spawn_tiles[0]

	var global_spawn = chunk_origin + local_spawn
	#print("📍 Player spawn (global):", global_spawn, "| Local:", local_spawn, "| Chunk size:", chunk_size)

	var placement_data = placement_file.duplicate(true)
	placement_data["local_map"]["grid_position"] = { "x": global_spawn.x, "y": global_spawn.y }
	placement_data["local_map"]["grid_position_local"] = { "x": local_spawn.x, "y": local_spawn.y }
	
	# Update Z-level
	placement_data["local_map"]["z_level"] = z_level

	# Track in existing_z_levels
	if not placement_data["local_map"].has("existing_z_levels"):
		placement_data["local_map"]["existing_z_levels"] = []

	if str(z_level) not in placement_data["local_map"]["existing_z_levels"]:
		placement_data["local_map"]["existing_z_levels"].append(str(z_level))

	# Optional: ensure it's listed in z_level_definitions
	if not placement_data["local_map"].has("z_level_definitions"):
		placement_data["local_map"]["z_level_definitions"] = {}

	if not placement_data["local_map"]["z_level_definitions"].has(str(z_level)):
		placement_data["local_map"]["z_level_definitions"][str(z_level)] = { "type": "predefined" }

	# Optional: track explored chunk for this z
	var current_chunk_id := chunk_key.replace("chunk_", "")
	var explored_chunks = placement_data["local_map"].get("explored_chunks", {})
	if not explored_chunks.has(str(z_level)):
		explored_chunks[str(z_level)] = []
	if current_chunk_id not in explored_chunks[str(z_level)]:
		explored_chunks[str(z_level)].append(current_chunk_id)
	placement_data["local_map"]["explored_chunks"] = explored_chunks


	save_json_file(get_temp_localmap_placement_path(), placement_data)
	#print("📌 Final placement saved with updated spawn info.")


func load_chunked_tile_chunk(chunk_id: String) -> Dictionary:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path := get_chunked_tile_chunk_path(chunk_id, biome_key)
	#print("📄 Trying to load tile chunk file:", path)

	var data = load_json_file(path)
	if data == null:
		#print("❌ ERROR: Failed to load tile chunk file at:", path)
		return {}

	if not data.has("tile_grid"):
		#print("⚠️ WARNING: tile chunk missing 'tile_grid' key!", data)
		return {}

	#print("✅ Loaded tile chunk:", chunk_id, "with", data["tile_grid"].size(), "tiles")
	
	# 🧼 Wrap only what render_map expects
	return {
		"tile_grid": data["tile_grid"]
	}


func load_chunk_tile_data(chunk_id: String) -> Dictionary:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path := get_chunked_tile_chunk_path(chunk_id, biome_key)
	#print("📄 Trying to load tile chunk file:", path)

	var data = load_json_file(path)
	if data == null:
		#print("❌ ERROR: Failed to load tile chunk file at:", path)
		return {}

	if not data.has("tile_grid"):
		#print("⚠️ WARNING: tile chunk missing 'tile_grid' key!", data)
		return {}

	#print("✅ Loaded tile chunk:", chunk_id, "with", data["tile_grid"].size(), "tiles")
	return data


func load_chunked_object_chunk(chunk_id: String) -> Dictionary:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path := get_chunked_object_chunk_path(chunk_id, biome_key)

	var raw = load_json_file(path)
	if raw == null:
		#print("❌ ERROR: Failed to load object chunk file at:", path)
		return {}

	if typeof(raw) != TYPE_DICTIONARY:
		#print("❌ ERROR: Loaded object chunk is not a dictionary! Type:", typeof(raw))
		return {}

	# ✅ Avoid double-wrapping
	if raw.has("objects") and typeof(raw["objects"]) == TYPE_DICTIONARY:
		return raw
	elif typeof(raw) == TYPE_DICTIONARY:
		return { "objects": raw }
	else:
		#print("❌ ERROR: Invalid object chunk format:", raw)
		return {}

func load_chunked_npc_chunk(chunk_id: String) -> Dictionary:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path := get_chunked_npc_chunk_path(chunk_id, biome_key)

	var raw = load_json_file(path)
	if raw == null:
		#print("❌ ERROR: Failed to load npc chunk file at:", path)
		return {}

	if typeof(raw) != TYPE_DICTIONARY:
		#print("❌ ERROR: Loaded npc chunk is not a dictionary! Type:", typeof(raw))
		return {}

	# ✅ Avoid double-wrapping
	if raw.has("npcs") and typeof(raw["npcs"]) == TYPE_DICTIONARY:
		return raw
	elif typeof(raw) == TYPE_DICTIONARY:
		return { "npcs": raw }
	else:
		#print("❌ ERROR: Invalid npc chunk format:", raw)
		return {}

func load_chunk_object_data(chunk_id: String) -> Dictionary:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path := get_chunked_object_chunk_path(chunk_id, biome_key)

	if not FileAccess.file_exists(path):
		#print("❌ ERROR: Missing object chunk:", chunk_id)
		return {}

	return load_json_file(path)

func load_chunk_npc_data(chunk_id: String) -> Dictionary:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path := get_chunked_npc_chunk_path(chunk_id, biome_key)

	if not FileAccess.file_exists(path):
		#print("❌ ERROR: Missing npc chunk:", chunk_id)
		return {}

	return load_json_file(path)

# 🔨 Flattens a 2D grid of tile dictionaries into a global tile dictionary keyed by world position
func flatten_tile_dict_grid(tile_dict_grid: Array, origin: Vector2i = Vector2i.ZERO) -> Dictionary:
	var tile_grid := {}

	# Sanity check: skip if not array of arrays
	if tile_dict_grid.size() == 0 or typeof(tile_dict_grid[0]) != TYPE_ARRAY:
		push_warning("⚠️ flatten_tile_dict_grid() received non-array 2D grid — skipping flatten.")
		return { "tile_grid": {} }

	for x in range(tile_dict_grid.size()):
		for y in range(tile_dict_grid[x].size()):
			var tile_entry = tile_dict_grid[x][y]

			if typeof(tile_entry) != TYPE_DICTIONARY or not tile_entry.has("tile"):
				continue

			var global_x = origin.x + x
			var global_y = origin.y + y
			var key = "%d_%d" % [global_x, global_y]

			tile_grid[key] = tile_entry.duplicate(true)

	return { "tile_grid": tile_grid }


# 🧠 Returns default state data for certain tile types
func get_tile_state_for(tile_name: String) -> Dictionary:
	match tile_name:
		"stonedoor":
			return { "is_open": false }
		"stonewallsidewindow", "stonewallbottomwindow":
			return {
				"is_open": false,
				"is_broken": false,
				"curtains_closed": true
			}
		_:
			return {}

func get_starting_chunk_id() -> String:
	var entry_context = load_entry_context()
	var explored_chunks = entry_context.get("local_map", {}).get("explored_chunks", {})
	var default_chunk = "1_1"

	if explored_chunks.has("0"):
		var chunk_list = explored_chunks["0"]
		if chunk_list.size() > 0:
			return "chunk_" + chunk_list[0]

	return "chunk_" + default_chunk

func normalize_chunk_tile_grid(global_tile_grid: Dictionary, chunk_key: String) -> Dictionary:
	var normalized_grid := {}

	var placement = LoadHandlerSingleton.load_temp_placement()
	var blueprints = placement.get("local_map", {}).get("chunk_blueprints", {})

	if not blueprints.has(chunk_key):
		push_warning("⚠️ normalize_chunk_tile_grid() → missing blueprint for %s" % chunk_key)
		return global_tile_grid  # fallback to global coords if unknown

	var origin_data = blueprints[chunk_key].get("origin", [0, 0])
	var chunk_origin = Vector2i(origin_data[0], origin_data[1])

	for key in global_tile_grid.keys():
		var coords = key.split("_")
		if coords.size() != 2:
			continue

		var global_x = coords[0].to_int()
		var global_y = coords[1].to_int()

		var local_x = global_x - chunk_origin.x
		var local_y = global_y - chunk_origin.y
		var new_key = "%d_%d" % [local_x, local_y]

		normalized_grid[new_key] = global_tile_grid[key]

	return normalized_grid


func normalize_object_positions_in_chunk(obj_data: Dictionary, chunk_key: String) -> Dictionary:
	var placement = LoadHandlerSingleton.load_temp_placement()
	var blueprints = placement.get("local_map", {}).get("chunk_blueprints", {})

	if not blueprints.has(chunk_key):
		push_warning("⚠️ normalize_object_positions_in_chunk() → missing blueprint for %s" % chunk_key)
		return obj_data  # fallback to global coords

	var origin_data = blueprints[chunk_key].get("origin", [0, 0])
	var chunk_origin = Vector2i(origin_data[0], origin_data[1])

	if not obj_data.has("objects"):
		return obj_data

	for obj_id in obj_data["objects"]:
		var pos = obj_data["objects"][obj_id].get("position", {})
		if pos.has("x") and pos.has("y"):
			pos["x"] -= chunk_origin.x
			pos["y"] -= chunk_origin.y

	return obj_data

func normalize_npc_positions_in_chunk(npc_data: Dictionary, chunk_key: String) -> Dictionary:
	var placement = LoadHandlerSingleton.load_temp_placement()
	var blueprints = placement.get("local_map", {}).get("chunk_blueprints", {})

	if not blueprints.has(chunk_key):
		push_warning("⚠️ normalize_npc_positions_in_chunk() → missing blueprint for %s" % chunk_key)
		return npc_data  # fallback to global coords

	var origin_data = blueprints[chunk_key].get("origin", [0, 0])
	var chunk_origin = Vector2i(origin_data[0], origin_data[1])

	if not npc_data.has("npcs"):
		return npc_data

	for npc_id in npc_data["npcs"]:
		var pos = npc_data["npcs"][npc_id].get("position", {})
		if pos.has("x") and pos.has("y"):
			pos["x"] -= chunk_origin.x
			pos["y"] -= chunk_origin.y

	return npc_data

func save_chunked_tile_chunk(chunk_id: String, tile_chunk: Dictionary) -> void:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")

	var path = get_chunked_tile_chunk_path(chunk_id, biome_key)
	save_json_file(path, tile_chunk)
	#print("💾 Saved tile chunk:", chunk_id, "to", path)


func save_chunked_object_chunk(chunk_id: String, object_chunk: Dictionary) -> void:
	var placement := load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")


	var path = get_chunked_object_chunk_path(chunk_id, biome_key)
	save_json_file(path, object_chunk)
	#print("💾 Saved object chunk:", chunk_id, "to", path)

func save_chunked_npc_chunk(chunk_id: String, npc_chunk: Dictionary) -> void:
	var placement = load_temp_localmap_placement()
	if placement == null:
		push_warning("⚠️ No placement data found when saving NPC chunk.")
		return

	var lm = placement.get("local_map", {})
	var stored_biome = str(lm.get("biome_key", ""))
	if stored_biome == "":
		push_error("❌ Missing biome_key in placement when saving NPC chunk " + str(chunk_id))
		return

	# normalize: if we got a folder (e.g. "grassland_explore_fields"), convert to short key ("gef")
	var biome_key_for_path = stored_biome
	if stored_biome.contains("_"):
		biome_key_for_path = Constants.get_biome_chunk_key(stored_biome)

	var z_level = str(lm.get("z_level", "0"))
	var path = get_chunked_npc_chunk_path(chunk_id, biome_key_for_path, z_level)

	# ensure directory exists
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	save_json_file(path, npc_chunk)
	print("💾 Saved NPC chunk:", chunk_id, "→", path)

func chunk_exists(chunk_coords: Vector2i) -> bool:
	var chunk_str = "%d_%d" % [chunk_coords.x, chunk_coords.y]
	var placement = load_temp_localmap_placement()
	if placement == null:
		return false

	var valid_chunks: Array = placement.get("local_map", {}).get("valid_chunks", [])
	if valid_chunks.size() > 0:
		# We're enforcing chunk limits
		var exists = valid_chunks.has(chunk_str)
		#print("🔒 Checking chunk validity:", chunk_str, "| Valid:", exists)
		return exists

	# If no valid_chunks list, fallback to explored_chunks only
	var explored = placement.get("local_map", {}).get("explored_chunks", {}).get("0", [])
	var exists = explored.has(chunk_str)
	#print("🔎 Checking chunk exists (fallback):", chunk_str, "| Explored:", exists)
	return exists


func get_current_chunk_coords() -> Vector2i:
	var placement = load_temp_localmap_placement()
	var chunk_id = placement.get("local_map", {}).get("current_chunk_id", "chunk_1_1")
	var parts = chunk_id.replace("chunk_", "").split("_")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	else:
		#print("❌ Invalid chunk ID format in get_current_chunk_coords():", chunk_id)
		return Vector2i(0, 0)

func mark_chunk_as_explored(chunk_coords: Vector2i):
	var chunk_str = "%d_%d" % [chunk_coords.x, chunk_coords.y]
	var placement = load_temp_localmap_placement()
	var explored_map = placement.get("local_map", {}).get("explored_chunks", {})
	var z_level = str(placement.get("local_map", {}).get("z_level", 0))

	if not explored_map.has(z_level):
		explored_map[z_level] = []

	if not chunk_str in explored_map[z_level]:
		explored_map[z_level].append(chunk_str)
		#print("🗺️ Marked chunk as explored:", chunk_str)
		placement["local_map"]["explored_chunks"] = explored_map
		LoadHandlerSingleton.save_temp_placement(placement)

func save_temp_placement(data: Dictionary) -> void:
	var path := LoadHandlerSingleton.get_temp_localmap_placement_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))  # Save with pretty indentation
		file.close()
		#print("💾 Saved placement data to:", path)
	else:
		print("❌ Failed to open placement file for writing at:", path)

func is_tile_walkable_in_chunk(chunk_coords: Vector2i, tile_pos_global: Vector2i) -> bool:
	var chunk_id: String = "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]

	var tile_chunk: Dictionary = load_chunked_tile_chunk(chunk_id)
	var object_chunk: Dictionary = load_chunked_object_chunk(chunk_id)

	if tile_chunk == null or object_chunk == null:
		#print("❌ Could not load chunk data for:", chunk_id)
		return false

	if object_chunk.has("objects"):
		object_chunk = object_chunk["objects"]

	var placement: Dictionary = load_temp_localmap_placement()
	var blueprints: Dictionary = placement.get("local_map", {}).get("chunk_blueprints", {})
	if not blueprints.has(chunk_id):
		#print("❌ No blueprint found for chunk:", chunk_id)
		return false

	var origin_data: Array = blueprints[chunk_id].get("origin", [0, 0])
	var chunk_origin: Vector2i = Vector2i(origin_data[0], origin_data[1])

	# ✅ Force tile_pos_global to be *actually* global
	var actual_global_tile: Vector2i = tile_pos_global
	var current_chunk_origin := LoadHandlerSingleton.get_chunk_origin(LoadHandlerSingleton.get_current_chunk_id())
	if tile_pos_global.x < 0 or tile_pos_global.y < 0:
		actual_global_tile = current_chunk_origin + tile_pos_global
		#print("🛠 Adjusted local tile to global:", tile_pos_global, "+", current_chunk_origin, "→", actual_global_tile)

	var local_pos: Vector2i = actual_global_tile - chunk_origin
	var key: String = "%d_%d" % [local_pos.x, local_pos.y]

	var tile_grid: Dictionary = tile_chunk.get("tile_grid", {})
	if not tile_grid.has(key):
		#print("⛔ Tile key missing:", key, "→ Global:", actual_global_tile, "→ Local:", local_pos, "in chunk:", chunk_id)
		return false

	var tile_entry: Dictionary = tile_grid.get(key, {})
	var terrain: String = tile_entry.get("tile", "")
	var object: Dictionary = Constants.find_object_at(object_chunk, local_pos.x, local_pos.y)
	var object_type: String = object.get("type", "") if object else ""

	#print("🌐 Walkability check — Chunk:", chunk_id, "| Global tile:", actual_global_tile, "| Origin:", chunk_origin, "| Local:", local_pos, "| Terrain:", terrain, "| Object:", object_type)

	return not Constants.is_blocking_movement(terrain, object_type)

func is_chunk_valid(chunk_coords: Vector2i) -> bool:
	var placement = load_temp_localmap_placement()
	if placement == null:
		return false

	var valid_chunks = placement.get("local_map", {}).get("valid_chunks", [])
	var chunk_str = "%d_%d" % [chunk_coords.x, chunk_coords.y]

	return chunk_str in valid_chunks


func load_temp_placement() -> Dictionary:
	var path := get_temp_localmap_placement_path()
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var contents := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(contents)
	if parsed == null:
		return {}

	return parsed

func get_chunk_size_for_chunk_id(chunk_id: String) -> Vector2i:
	var placement := load_temp_placement()
	var blueprints: Dictionary = placement.get("local_map", {}).get("chunk_blueprints", {})

	if not blueprints.has(chunk_id):
		push_warning("⚠️ No chunk blueprint found for: " + chunk_id)
		return Vector2i.ZERO

	var size_data: Array = blueprints[chunk_id].get("size", [0, 0])
	if size_data.size() != 2:
		push_warning("⚠️ Invalid size array for: " + chunk_id)
		return Vector2i.ZERO

	return Vector2i(size_data[0], size_data[1])

func get_current_chunk_id() -> String:
	var placement := load_temp_placement()
	return placement.get("local_map", {}).get("current_chunk_id", "chunk_1_1")

func get_current_z_level() -> int:
	var placement := load_temp_placement()
	return placement.get("local_map", {}).get("z_level", 0)

func get_chunk_blueprints() -> Dictionary:
	var placement := load_temp_placement()
	if not placement.has("local_map"):
		return {}
	return placement["local_map"].get("chunk_blueprints", {})

func get_chunk_origin(chunk_id: String) -> Vector2i:
	var blueprints = get_chunk_blueprints()
	if not blueprints.has(chunk_id):
		return Vector2i.ZERO
	var bp: Dictionary = blueprints[chunk_id]
	return Vector2i(bp["origin"][0], bp["origin"][1])

func get_chunk_origin_from_file(chunk_key: String, biome_key_short: String, z_level: int) -> Vector2i:
	var biome_folder = Constants.get_chunk_folder_for_key(biome_key_short)
	var path = get_chunked_tile_chunk_path(chunk_key, biome_key_short, str(z_level))
	var chunk_data = load_json_file(path)
	if chunk_data.has("chunk_origin"):
		var o = chunk_data["chunk_origin"]
		return Vector2i(o.get("x", 0), o.get("y", 0))
	return Vector2i.ZERO

func get_chunked_tile_chunk_path(chunk_id: String, key: String, z_level: String = "") -> String:
	if z_level == "":
		var placement = load_temp_localmap_placement()
		z_level = str(placement.get("local_map", {}).get("z_level", "0"))

	var folder = Constants.get_chunk_folder_for_key(key)
	return get_save_file_path() + "localchunks/" + folder + "/z" + z_level + "/chunk_tile_" + chunk_id + ".json"


func get_chunked_object_chunk_path(chunk_id: String, key: String, z_level: String = "") -> String:
	if z_level == "":
		var placement = load_temp_localmap_placement()
		z_level = str(placement.get("local_map", {}).get("z_level", "0"))

	var folder = Constants.get_chunk_folder_for_key(key)
	return get_save_file_path() + "localchunks/" + folder + "/z" + z_level + "/chunk_object_" + chunk_id + ".json"

func get_chunked_npc_chunk_path(chunk_id: String, key: String, z_level: String = "") -> String:
	if z_level == "":
		var placement = load_temp_localmap_placement()
		z_level = str(placement.get("local_map", {}).get("z_level", "0"))

	var folder = Constants.get_chunk_folder_for_key(key)
	return get_save_file_path() + "localchunks/" + folder + "/z" + z_level + "/chunk_npc_" + chunk_id + ".json"


	
# Optional for entity + terrain mods if you plan to save those
func get_chunked_entity_chunk_path(chunk_id: String, biome_key: String) -> String:
	return get_save_file_path() + "localchunks/%s/chunk_entities_%s.json" % [Consts.get_biome_folder_from_key(biome_key), chunk_id]

func get_chunked_terrain_mod_path(chunk_id: String, biome_key: String) -> String:
	return get_save_file_path() + "localchunks/%s/chunk_terrain_%s.json" % [Consts.get_biome_folder_from_key(biome_key), chunk_id]


func clear_chunks_for_key(key: String) -> void:
	var folder = Constants.get_chunk_folder_for_key(key)
	var path = get_save_file_path() + "localchunks/" + folder + "/"
	var dir = DirAccess.open(path)
	if dir:
		for file in dir.get_files():
			if file.ends_with(".json"):
				dir.remove(file)

var _chunk_blueprints := {}  # This must stay outside a function

func reset_chunk_state():
	#print("♻️ Resetting chunk-related transient state...")

	# ✅ Clear currently tracked chunk state
	current_chunk_id = ""
	current_chunk_coords = Vector2i.ZERO

	# ✅ Wipe all cached tile + object data (if they exist)
	if typeof(loaded_tile_chunks) == TYPE_DICTIONARY:
		loaded_tile_chunks.clear()

	if typeof(loaded_object_chunks) == TYPE_DICTIONARY:
		loaded_object_chunks.clear()

	# ✅ Clear blueprints dictionary
	_chunk_blueprints.clear()
	#print("✅ Blueprint keys AFTER reset:", _chunk_blueprints.keys())  # ✅ This is valid now

	# ✅ Optional: clear any cached chunk info from other systems
	if Engine.has_singleton("ChunkTools"):
		var ct = Engine.get_singleton("ChunkTools")
		if ct.has("chunk_cache") and typeof(ct.chunk_cache) == TYPE_DICTIONARY:
			ct.chunk_cache.clear()

	# ✅ Optional: clear walkability from LocalMap
	if has_node("/root/LocalMap"):
		var local_map = get_node("/root/LocalMap")
		if local_map.has_method("clear_walkability"):
			local_map.call("clear_walkability")
	
	reset_egress_points()

func set_chunk_blueprints(bp: Dictionary) -> void:
	_chunk_blueprints = bp

var egress_points := []  # Reset each local map generation

func reset_egress_points():
	egress_points.clear()

func add_egress_point(point: Dictionary):
	# point must contain: position (Vector2i), type (e.g. "hole", "stairs_down"), and target_z (int)
	if point.has("position") and point.has("type") and point.has("target_z"):
		egress_points.append(point)
	else:
		push_error("Invalid egress point: missing keys")

func get_egress_points() -> Array:
	return egress_points

func get_egress_points_for_z(target_z: int) -> Array:
	return egress_points.filter(func(p): return p["target_z"] == target_z)

static func get_egress_register_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/egress_register.json" % biome_folder

static func save_egress_register(biome_folder: String, egress_data: Dictionary) -> void:
	var path = get_egress_register_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, egress_data)

static func load_egress_register(biome_folder: String) -> Dictionary:
	var path = get_egress_register_path(biome_folder)
	var data = LoadHandlerSingleton.load_json_file(path)
	if typeof(data) == TYPE_DICTIONARY:
		return data
	#print("⚠️ No egress register found or invalid format at:", path)
	return {}

static func load_prefab_data(biome_key: String = "gef") -> Array:
	var prefab_path = get_prefab_json_path_for_biome(biome_key)
	var instance = LoadHandlerSingleton  # reference to autoload singleton instance
	var json = instance.load_json_file(prefab_path)

	if json and json.has("prefabs") and json.has("blueprints"):
		return [json["prefabs"], get_blueprint_map(json["blueprints"])]
	else:
		#print("⚠️ Failed to load prefab data from:", prefab_path)
		return []

static func get_blueprint_map(blueprints: Array) -> Dictionary:
	var result := {}
	for blueprint in blueprints:
		if blueprint.has("name"):
			result[blueprint["name"]] = blueprint
	return result

static func register_egress_point(egress: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(egress["biome"])
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var current: Dictionary = LoadHandlerSingleton.load_egress_register(biome_folder)

	var z: int = int(egress["position"].get("z", 0))
	var chunk: String = str(egress["chunk"])
	var chunk_key := "%s|z%d" % [chunk, z]

	if not current.has(chunk_key):
		current[chunk_key] = []
	current[chunk_key].append(egress)

	# 🪜 Generate reverse egress if applicable
	if Constants.REVERSE_EGRESS_TYPES.has(egress["type"]) and not Constants.MANUAL_EGRESS_TYPES.has(egress["type"]):
		var reverse_type = Constants.REVERSE_EGRESS_TYPES[egress["type"]]
		var reverse_z = egress["target_z"]
		var reverse_target_z = z

		# 🚫 Skip if the reverse Z == source Z (no self-loop egresses)
		if reverse_z == z:
			return

		var reverse_chunk_key := "%s|z%d" % [chunk, reverse_z]

		var reverse_egress = {
			"type": reverse_type,
			"target_z": reverse_target_z,
			"position": {
				"x": egress["position"]["x"],
				"y": egress["position"]["y"],
				"z": reverse_z
			},
			"chunk": chunk,
			"biome": egress["biome"]
		}

		if not current.has(reverse_chunk_key):
			current[reverse_chunk_key] = []

		# ✅ Prevent duplicate reverse entries
		var is_duplicate := false
		for existing in current[reverse_chunk_key]:
			if existing["position"] == reverse_egress["position"] and existing["type"] == reverse_egress["type"]:
				is_duplicate = true
				break

		if not is_duplicate:
			current[reverse_chunk_key].append(reverse_egress)

	# 💾 Save final result
	LoadHandlerSingleton.save_egress_register(biome_folder, current)


static func get_prefab_json_path_for_biome(biome_key_short: String) -> String:
	match biome_key_short:
		"gef":
			return "res://data/prefabs/grassland-prefabs.json"
		"vses":
			return "res://data/prefabs/village-slums-prefabs.json"
		# Add more as needed
		_:
			print("⚠️ No prefab path mapped for biome:", biome_key_short)
			return ""

static func set_chunk_structure_map(map_data: Dictionary) -> void:
	_chunk_structure_map = map_data

static func get_chunk_structure_map() -> Dictionary:
	return _chunk_structure_map if _chunk_structure_map != null else {}

static func clear_egress_register_for_biome(biome: String) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path = LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/egress_register.json" % biome_folder

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({}, "\t"))  # Overwrite with empty dict
		file.close()
		#print("🧹 Cleared egress_register for biome folder:", biome_folder)
	else:
		print("⚠️ Failed to open egress register file for clearing:", path)

static func clear_prefab_register_for_biome(biome: String) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path = LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/prefab_register.json" % biome_folder

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({}, "\t"))  # Overwrite with empty dict
		file.close()
		#print("🧹 Cleared prefab_register for biome folder:", biome_folder)
	else:
		print("⚠️ Failed to open prefab register file for clearing:", path)

static func register_prefab_data_for_chunk(biome_folder: String, chunk_key: String, prefab_id: String, coords: Vector2i, z_level: int = 0) -> void:
	var current := load_prefab_register(biome_folder)
	current[chunk_key] = {
		"prefab_id": prefab_id,
		"coords": { "x": coords.x, "y": coords.y },
		"z_level": z_level
	}
	save_prefab_register(biome_folder, current)
	
static func save_prefab_register(biome_folder: String, data: Dictionary) -> void:
	var path := LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/prefab_register.json" % biome_folder
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		#print("💾 Saved prefab_register for:", biome_folder)		

	else:
		print("⚠️ Failed to save prefab_register at:", path)

static func load_prefab_register(biome_folder: String) -> Dictionary:
	var path := LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/prefab_register.json" % biome_folder
	#print("🔍 Loading prefab_register from:", path)  # <-- Add this here
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.parse_string(content)
			if typeof(json) == TYPE_DICTIONARY:
				return json
			else:
				print("⚠️ Invalid JSON in prefab_register at:", path)
	return {}

static func get_blueprint_from_register_entry(prefab_entry: Dictionary, biome_key_short: String) -> Dictionary:
	if not prefab_entry.has("prefab_id"):
		#print("⚠️ Prefab entry missing 'prefab_id':", prefab_entry)
		return {}

	var prefab_id = prefab_entry["prefab_id"]
	var z_level = str(prefab_entry.get("z_level", "-1"))  # Default to -1 if not provided

	var prefab_data = load_prefab_data(biome_key_short)
	if prefab_data.size() != 2:
		#print("⚠️ Invalid prefab data structure for biome:", biome_key_short)
		return {}

	var all_prefabs = prefab_data[0]
	var all_blueprints = prefab_data[1]

	for prefab in all_prefabs:
		if prefab.get("name", "") == prefab_id:
			var blueprint_name = prefab.get("floors", {}).get(z_level, "")
			if blueprint_name != "" and all_blueprints.has(blueprint_name):
				#print("📦 Blueprint found for prefab:", prefab_id, "Z:", z_level, "→", blueprint_name)
				return all_blueprints[blueprint_name]
			else:
				#print("⚠️ No blueprint found for", prefab_id, "at Z:", z_level)
				return {}

	#print("⚠️ No matching prefab_id in list:", prefab_id)
	return {}

static func load_global_egress_data(force_refresh := false) -> Dictionary:
	if not force_refresh and _cached_egress_data.has("data"):
		return _cached_egress_data["data"]

	var placement = LoadHandlerSingleton.load_temp_placement()
	var biome_key = placement.get("local_map", {}).get("biome_key", "")
	if biome_key == "":
		push_error("❌ [load_global_egress_data] Missing biome_key in temp placement.")
		return {}

	# 🔁 Convert long-form → short-form
	biome_key = Constants.get_biome_chunk_key(biome_key)

	# 🔁 Now convert short-form → folder path
	var biome_folder = Constants.get_chunk_folder_for_key(biome_key)
	var path = get_egress_register_path(biome_folder)

	if not FileAccess.file_exists(path):
		push_warning("⚠️ [load_global_egress_data] Egress register file does not exist at path: " + path)
		return {}

	var contents = FileAccess.open(path, FileAccess.READ).get_as_text()
	var parsed = JSON.parse_string(contents)
	_cached_egress_data["data"] = parsed
	return parsed


static func reload_from_temp_placement():
	#print("🔄 reload_from_temp_placement called from singleton.")

	var scene = Engine.get_main_loop().get_current_scene()
	if scene == null:
		#print("❌ No current scene found!")
		return

	var local_map = Engine.get_main_loop().get_current_scene()
	if local_map == null:
		#print("❌ LocalMap node NOT found!")
		return

	var placement_data = LoadHandlerSingleton.load_temp_placement()
	var local_map_data = placement_data.get("local_map", {})
	var z_level = local_map_data.get("z_level", null)

	if z_level == null:
		#print("⚠️ Z-level missing from placement data!")
		return

	#print("📡 Reloading LocalMap at Z-level:", z_level)
	local_map.call_deferred("load_z_level", z_level)


func change_z_level(new_z_level: int) -> void:
	var path = get_temp_localmap_placement_path()
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	data["local_map"]["z_level"] = str(new_z_level)

	var file_write = FileAccess.open(path, FileAccess.WRITE)
	file_write.store_string(JSON.stringify(data))
	file_write.close()

	#print("💾 Z-level updated in temp placement to:", new_z_level)

	# Properly call reload
	call_deferred("reload_from_temp_placement")

static func clear_cached_egress_register():
	_cached_egress_data.clear()

func get_combined_egress_list() -> Array:
	var all_egresses := []
	var seen := {}

	# Grab in-memory points safely (non-static)
	for e in self.egress_points:
		var key := "%s_%d_%d_%d" % [e.chunk, e.position.x, e.position.y, e.position.z]
		seen[key] = true
		all_egresses.append(e)

	# Add disk-persisted register entries
	var egress_data := LoadHandlerSingleton.load_global_egress_data(true)
	for chunk_key in egress_data.keys():
		for e in egress_data[chunk_key]:
			var key := "%s_%d_%d_%d" % [e.chunk, e.position.x, e.position.y, e.position.z]
			if not seen.has(key):
				all_egresses.append(e)

	return all_egresses

func load_player_inventory_dict() -> Dictionary:
	var path: String = get_player_inventory_path()
	var data: Variant = load_json_file(path)
	if data == null or not (data is Dictionary):
		return {}

	# ✅ Normalize each stack
	for uid in data.keys():
		LoadHandlerSingleton.normalize_stack_stats(data[uid])

	return data

func save_player_inventory_dict(inv: Dictionary) -> void:
	# Auto-flatten if someone passed in a wrapped dict
	if inv.has("inventory") and inv["inventory"] is Dictionary:
		inv = inv["inventory"]

	# Normalize all stacks
	for uid in inv.keys():
		normalize_stack_stats(inv[uid])

	var path := get_player_inventory_path()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(inv, "\t"))
		f.close()
	else:
		push_warning("Could not write inventory to: %s" % path)


static func get_loot_register_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/loot_register.json" % biome_folder

static func load_loot_register(biome: String) -> Dictionary:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_loot_register_path(biome_folder)
	return LoadHandlerSingleton.load_json_file(path)

static func save_loot_register(biome: String, data: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_loot_register_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, data)

static func get_node_register_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/node_register.json" % biome_folder

static func load_node_register(biome: String) -> Dictionary:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_node_register_path(biome_folder)
	return LoadHandlerSingleton.load_json_file(path)

static func save_node_register(biome: String, data: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_node_register_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, data)

static func get_pile_register_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/pile_register.json" % biome_folder

static func load_pile_register(biome: String) -> Dictionary:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_pile_register_path(biome_folder)
	return LoadHandlerSingleton.load_json_file(path)

static func save_pile_register(biome: String, data: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_pile_register_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, data)

static func get_storage_register_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/storage_register.json" % biome_folder

static func load_storage_register(biome: String) -> Dictionary:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_storage_register_path(biome_folder)
	return LoadHandlerSingleton.load_json_file(path)

static func save_storage_register(biome: String, data: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_storage_register_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, data)

static func get_vendor_register_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/vendor_register.json" % biome_folder

static func load_vendor_register(biome: String) -> Dictionary:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_vendor_register_path(biome_folder)
	return LoadHandlerSingleton.load_json_file(path)

static func save_vendor_register(biome: String, data: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_vendor_register_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, data)

static func reset_node_register_for_biome(biome: String, current_datetime: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var register: Dictionary = LoadHandlerSingleton.load_node_register(biome)

	var changed := false

	for z_level in register.keys():
		for chunk_key in register[z_level].keys():
			var chunk: String = chunk_key
			for biome_data_key in register[z_level][chunk_key].keys():
				for node_id_key in register[z_level][chunk_key][biome_data_key].keys():
					var node_id: String = node_id_key
					var node: Dictionary = register[z_level][chunk_key][biome_data_key][node_id]
					
					if node.has("reset_at") and is_datetime_expired(node["reset_at"], current_datetime):
						node["inventory"].clear()
						node["last_looted"] = current_datetime
						node["reset_at"] = calculate_next_reset(current_datetime)
						changed = true

	if changed:
		LoadHandlerSingleton.save_node_register(biome, register)

static func clear_node_register_for_biome(biome: String) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path = LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/node_register.json" % biome_folder

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({}, "\t"))  # Overwrite with empty dict
		file.close()
	else:
		print("⚠️ Failed to open node register file for clearing:", path)

static func is_datetime_expired(reset_at: Dictionary, current: Dictionary) -> bool:
	var reset_minutes = TimeManager.get_total_minutes_from_string(reset_at["time"])
	var current_minutes = TimeManager.get_total_minutes_from_string(current["time"])

	if reset_at["date"] != current["date"]:
		# Naively assume day rollover means it's expired
		return true

	return current_minutes >= reset_minutes

static func calculate_next_reset(current: Dictionary) -> Dictionary:
	var temp_time = {
		"date": current["date"],
		"time": current["time"]
	}

	# Let TimeManager advance the temp object (you'd need to expose a method for this)
	var result = TimeManager.advance_datetime(temp_time, 1440)  # ⏰ Add 1440 minutes (1 day)

	return {
		"date": result["date"],
		"time": result["time"]
	}

static func get_node_table() -> Dictionary:
	return NodeTable.NODE_TABLE

static func get_node_pool(node_type: String) -> Dictionary:
	var table: Dictionary = NodeTable.NODE_TABLE
	if not table.has(node_type):
		return {}
	return table[node_type].get("possible_items", {})
	
static func roll_node_loot(node_type: String, rolls: int = 3, rng: RandomNumberGenerator = null) -> Dictionary:
	var pool: Dictionary = get_node_pool(node_type)
	if pool.is_empty():
		return {}

	var local_rng: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		local_rng.randomize()

	var weighted: Array[Dictionary] = []
	for item_id in pool.keys():
		var entry: Dictionary = pool[item_id]
		var weight: int = int(entry.get("weight", 1))
		if weight > 0:
			weighted.append({"id": String(item_id), "w": weight})

	if weighted.is_empty():
		return {}

	var rare_cap: int = 999999
	var node_def: Dictionary = NodeTable.NODE_TABLE.get(node_type, {})
	if node_def.has("max_rare"):
		rare_cap = int(node_def["max_rare"])

	var rolled: Dictionary = {}
	var rare_count: int = 0

	for i in range(rolls):
		var pick_id: String = _weighted_pick(weighted, local_rng)
		if pick_id == "":
			continue

		var is_rare: bool = String(pool[pick_id].get("rarity", "common")) == "rare"
		if is_rare and rare_count >= rare_cap:
			# try to pick a non-rare instead
			var fallback_id: String = _weighted_pick(weighted, local_rng, true, pool)
			if fallback_id == "":
				continue
			pick_id = fallback_id
			is_rare = false

		var max_q: int = int(pool[pick_id].get("max_qty", 1))
		var qty: int = local_rng.randi_range(1, max_q)

		rolled[pick_id] = int(rolled.get(pick_id, 0)) + qty
		if is_rare:
			rare_count += 1

	return rolled


static func _weighted_pick(weighted: Array[Dictionary], rng: RandomNumberGenerator, prefer_non_rare: bool = false, pool: Dictionary = {}) -> String:
	var total: int = 0
	for e in weighted:
		if prefer_non_rare and pool.size() > 0 and String(pool[e["id"]].get("rarity", "common")) == "rare":
			continue
		total += int(e["w"])

	if total <= 0:
		return ""

	var roll: int = rng.randi_range(1, total)
	var accum: int = 0

	for e in weighted:
		if prefer_non_rare and pool.size() > 0 and String(pool[e["id"]].get("rarity", "common")) == "rare":
			continue
		accum += int(e["w"])
		if roll <= accum:
			return String(e["id"])

	return ""

# adjust the path at the top of the file:
# const ItemData := preload("res://constants/item_data.gd")

static func expand_loot_to_inventory(rolled: Dictionary, timestamp: Dictionary = {}) -> Dictionary:
	var inv: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	for item_id in rolled.keys():
		var qty: int = int(rolled[item_id])

		var base: Dictionary = ItemData.ITEM_PROPERTIES.get(item_id, {}).duplicate(true)
		var display_name: String = String(base.get("base_display_name", String(item_id)))
		var type_str: String = String(base.get("type", "Loot"))
		var weight_per: float = float(base.get("weight_per", 0.0))
		var avg_value_per: int = int(base.get("avg_value_per", 0))

		# Explicit timestamp fields
		var date_str: String = String(timestamp.get("date", ""))
		var time_str: String = String(timestamp.get("time", ""))

		# Generate unique ID
		var uid: String = _make_unique_id(rng)

		# Add runtime-specific fields
		base["display_name"] = display_name
		base["item_ID"] = String(item_id)
		base["unique_ID"] = uid
		base["date"] = date_str
		base["time"] = time_str
		base["type"] = type_str
		base["weight"] = weight_per
		base["value"] = avg_value_per * qty
		base["qty"] = qty

		inv[uid] = base

	return inv


static func _make_unique_id(rng: RandomNumberGenerator) -> String:
	# lightweight unique id
	return "i%08X" % rng.randi()

static func ensure_node_entry_with_loot(biome: String, z_key: String, chunk_key: String, biome_key: String, node_id: String, node_type: String, position: Vector2, current_dt: Dictionary) -> void:
	# Load
	var register: Dictionary = LoadHandlerSingleton.load_node_register(biome)
	if not register.has(z_key):
		register[z_key] = {}
	if not register[z_key].has(chunk_key):
		register[z_key][chunk_key] = {}
	if not register[z_key][chunk_key].has(biome_key):
		register[z_key][chunk_key][biome_key] = {}

	# Create if missing
	if not register[z_key][chunk_key][biome_key].has(node_id):
		var rolled := roll_node_loot(node_type, 3)  # tune rolls per node type
		var inv := expand_loot_to_inventory(rolled, current_dt)

		register[z_key][chunk_key][biome_key][node_id] = {
			"position": [int(position.x), int(position.y)],
			"last_looted": current_dt,
			"reset_at": calculate_next_reset(current_dt), # you already have this
			"inventory": inv
		}
		LoadHandlerSingleton.save_node_register(biome, register)

static func get_node_entry(biome: String, z: String, chunk: String, biome_key: String, node_id: String) -> Dictionary:
	var register := load_node_register(biome)
	if register.has(z) and register[z].has(chunk) and register[z][chunk].has(biome_key) and register[z][chunk][biome_key].has(node_id):
		return register[z][chunk][biome_key][node_id]
	return {}

static func update_node_inventory(
	biome: String,
	z_key: String,
	chunk_key: String,
	biome_key: String,
	node_id: String,
	inventory: Dictionary
) -> void:
	var register := load_node_register(biome)

	print("🌿 Updating node:", biome, z_key, chunk_key, biome_key, node_id)
	print("📒 Node register keys:", register.keys())

	if not register.has(z_key):
		push_warning("⚠️ z_key not found: %s" % z_key)
		return
	if not register[z_key].has(chunk_key):
		push_warning("⚠️ chunk_key not found: %s" % chunk_key)
		return
	if not register[z_key][chunk_key].has(biome_key):
		push_warning("⚠️ biome_key not found: %s" % biome_key)
		return
	if not register[z_key][chunk_key][biome_key].has(node_id):
		push_warning("⚠️ node_id not found: %s" % node_id)
		return

		# ✅ Normalize inventory stacks
	for uid in inventory.keys():
		LoadHandlerSingleton.normalize_stack_stats(inventory[uid])

	# ✅ Apply update
	register[z_key][chunk_key][biome_key][node_id]["inventory"] = inventory

	print("✅ Updated node entry:", node_id, "→", inventory.keys())

	save_node_register(biome, register)

func get_mount_inv_path() -> String:
	return get_save_file_path() + "characterdata/mount_inventory" + str(get_save_slot()) + ".json"

func load_mount_inv() -> Dictionary:
	var path = get_mount_inv_path()
	var data: Variant = load_json_file(path)
	if data == null or not (data is Dictionary):
		return {}

	# ✅ Normalize all stacks
	for uid in data.keys():
		LoadHandlerSingleton.normalize_stack_stats(data[uid])

	return data


func save_mount_inv(data: Dictionary) -> void:
	# ✅ Normalize before save
	for uid in data.keys():
		LoadHandlerSingleton.normalize_stack_stats(data[uid])

	var path = get_mount_inv_path()
	save_json_file(path, data)
	LoadHandlerSingleton.recalc_player_and_mount_weight()


static func ensure_storage_entry_with_loot(
	biome: String,
	z_key: String,
	chunk_key: String,
	biome_key: String,
	storage_id: String,
	storage_type: String,
	position: Vector2,
	timestamp: Dictionary
) -> void:
	var register := LoadHandlerSingleton.load_storage_register(biome)

	# Ensure nesting exists
	if not register.has(z_key):
		register[z_key] = {}
	if not register[z_key].has(chunk_key):
		register[z_key][chunk_key] = {}
	if not register[z_key][chunk_key].has(biome_key):
		register[z_key][chunk_key][biome_key] = {}

	# 🧱 If this storage already exists, check if it's a player-built one
	if register[z_key][chunk_key][biome_key].has(storage_id):
		var existing: Dictionary = register[z_key][chunk_key][biome_key][storage_id]
		if existing.get("is_built", false):
			print("🧱 Skipping loot roll — built storage detected:", storage_id)
			return  # ✅ do nothing for player-built chests
		return  # ✅ do nothing if already rolled naturally

	# Otherwise, first interaction → roll loot for *naturally spawned* chests
	var rolled := roll_node_loot(storage_type, 3)
	var inv := expand_loot_to_inventory(rolled, timestamp)

	register[z_key][chunk_key][biome_key][storage_id] = {
		"position": [int(position.x), int(position.y)],
		"inventory": inv,
		"storage_type": storage_type,
		"rolled_once": true,
		"created_at": timestamp
	}

	print("🎁 Rolled new natural chest loot for:", storage_id)
	LoadHandlerSingleton.save_storage_register(biome, register)


static func clear_storage_register_for_biome(biome: String) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path = LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/storage_register.json" % biome_folder

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({}, "\t"))  # Overwrite with empty dict
		file.close()
	else:
		print("⚠️ Failed to open storage register file for clearing:", path)

func get_localmap_biome_key() -> String:
	var path: String = get_temp_localmap_placement_path()
	var data: Dictionary = load_json_file(path)
	var lm: Dictionary = data.get("local_map", {})
	return String(lm.get("biome_key", "unknown"))

func get_localmap_z_key() -> String:
	var path: String = get_temp_localmap_placement_path()
	var data: Dictionary = load_json_file(path)
	var lm: Dictionary = data.get("local_map", {})
	return str(lm.get("z_level", 0))

func get_chunk_key_for_pos(pos: Vector2i) -> String:
	var path: String = get_temp_localmap_placement_path()
	var data: Dictionary = load_json_file(path)
	var lm: Dictionary = data.get("local_map", {})
	var chunks: Dictionary = lm.get("chunk_blueprints", {})

	for chunk_id in chunks.keys():
		var chunk: Dictionary = chunks[chunk_id]
		var origin_arr: Array = chunk.get("origin", [0, 0])
		var size_arr: Array   = chunk.get("size",   [32, 32])
		if origin_arr.size() >= 2 and size_arr.size() >= 2:
			var origin: Vector2i = Vector2i(int(origin_arr[0]), int(origin_arr[1]))
			var size: Vector2i   = Vector2i(int(size_arr[0]),   int(size_arr[1]))
			var rect: Rect2i = Rect2i(origin, size)
			if rect.has_point(pos):
				return String(chunk_id)

	# Fallbacks
	var current_id: String = String(lm.get("current_chunk_id", ""))
	if current_id != "":
		return current_id
	return "chunk_0_0"
	
func _ctx_for_pos(pos: Vector2i) -> Dictionary:
	var biome_key: String = LoadHandlerSingleton.get_localmap_biome_key()
	var biome_name: String = biome_key
	var z_key: String = str(LoadHandlerSingleton.get_localmap_z_key())  # 🔑 always a string
	var chunk_key: String = LoadHandlerSingleton.get_chunk_key_for_pos(pos)

	return {
		"biome": biome_name,
		"biome_key": biome_key,
		"z": z_key,
		"chunk": chunk_key
	}

static func ensure_vendor_entry_with_loot(
	biome: String,
	z_key: String,
	chunk_key: String,
	biome_key: String,
	vendor_id: String,
	vendor_type: String,
	position: Vector2,
	current_dt: Dictionary
) -> void:
	var register := load_vendor_register(biome)

	if not register.has(z_key):
		register[z_key] = {}
	if not register[z_key].has(chunk_key):
		register[z_key][chunk_key] = {}
	if not register[z_key][chunk_key].has(biome_key):
		register[z_key][chunk_key][biome_key] = {}

	if not register[z_key][chunk_key][biome_key].has(vendor_id):
		var rolled := roll_node_loot(vendor_type, 5)  # ← just like bushes/trees/etc
		var inv := expand_loot_to_inventory(rolled, current_dt)

		register[z_key][chunk_key][biome_key][vendor_id] = {
			"position": [int(position.x), int(position.y)],
			"type": vendor_type,
			"last_visited": current_dt,
			"inventory": inv
		}
		save_vendor_register(biome, register)

static func clear_vendor_register_for_biome(biome: String) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_vendor_register_path(biome_folder)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({}, "\t"))  # Overwrite with empty dict
		file.close()
	else:
		print("⚠️ Failed to open vendor register file for clearing:", path)

static func transfer_item(
	source_inventory: Dictionary,
	target_inventory: Dictionary,
	stack_id: String,
	qty: int = -1
) -> void:
	if not source_inventory.has(stack_id):
		push_warning("❌ Tried to transfer non-existent item: " + stack_id)
		return

	var item: Dictionary = source_inventory[stack_id].duplicate(true)
	var amount_to_transfer: int = (qty if qty > 0 else int(item.get("qty", 1)))

	var item_id: String = item.get("item_ID", "")
	var def: Dictionary = ItemData.ITEM_PROPERTIES.get(item_id, {})
	var is_stackable: bool = def.get("stackable", true)

	# Decrease or remove from source
	if amount_to_transfer >= int(item.get("qty", 1)):
		source_inventory.erase(stack_id)
	else:
		source_inventory[stack_id]["qty"] -= amount_to_transfer

	# Stackable: Try to merge into existing stack in target
	if is_stackable:
		for k in target_inventory.keys():
			var t: Dictionary = target_inventory[k]
			if t.get("item_ID", "") == item_id:
				t["qty"] += amount_to_transfer
				LoadHandlerSingleton.normalize_stack_stats(t) # ✅ update merged stack
				return

	# New stack needed: generate new instance
	var new_stack: Dictionary = item.duplicate(true)
	new_stack["qty"] = amount_to_transfer
	new_stack["unique_ID"] = LoadHandlerSingleton._make_unique_id(RandomNumberGenerator.new())

	LoadHandlerSingleton.normalize_stack_stats(new_stack) # ✅ normalize new stack
	target_inventory[new_stack["unique_ID"]] = new_stack
	if Engine.has_singleton("LoadHandlerSingleton"):
		var handler = Engine.get_singleton("LoadHandlerSingleton")
		if handler is Object:
			handler._on_transfer_item_completed()

func _on_transfer_item_completed():
	emit_signal("inventory_changed")

static func update_storage_inventory(
	biome: String,
	z_key: String,
	chunk_key: String,
	biome_key: String,
	storage_id: String,
	inventory: Dictionary
) -> void:
	var register := LoadHandlerSingleton.load_storage_register(biome)

	print("📝 Updating storage:", biome, z_key, chunk_key, biome_key, storage_id)
	print("📦 Before update keys:", register.keys())

	if not register.has(z_key):
		push_warning("⚠️ z_key not found: %s" % z_key)
		return
	if not register[z_key].has(chunk_key):
		push_warning("⚠️ chunk_key not found: %s" % chunk_key)
		return
	if not register[z_key][chunk_key].has(biome_key):
		push_warning("⚠️ biome_key not found: %s" % biome_key)
		return
	if not register[z_key][chunk_key][biome_key].has(storage_id):
		push_warning("⚠️ storage_id not found: %s" % storage_id)
		return

	# ✅ Normalize inventory stacks
	for uid in inventory.keys():
		LoadHandlerSingleton.normalize_stack_stats(inventory[uid])

	# ✅ Only replace inventory field
	register[z_key][chunk_key][biome_key][storage_id]["inventory"] = inventory

	print("✅ Updated storage entry:", storage_id, "→", inventory.keys())

	LoadHandlerSingleton.save_storage_register(biome, register)


static func get_npc_pool_path(biome_folder: String) -> String:
	return LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/npc_pool.json" % biome_folder

static func load_npc_pool(biome: String) -> Dictionary:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_npc_pool_path(biome_folder)
	return LoadHandlerSingleton.load_json_file(path)

static func save_npc_pool(biome: String, data: Dictionary) -> void:
	var biome_key := Constants.get_biome_chunk_key(biome)
	var biome_folder := Constants.get_chunk_folder_for_key(biome_key)
	var path := get_npc_pool_path(biome_folder)
	LoadHandlerSingleton.save_json_file(path, data)

func save_chunked_npc_data(biome: String, chunked_npcs: Dictionary) -> void:
	for chunk_key in chunked_npcs.keys():
		save_chunked_npc_chunk(chunk_key, chunked_npcs[chunk_key])

func build_position_lookup_from_grid(grid: Array) -> Dictionary:
	var lookup := {}
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			lookup[Vector2i(x, y)] = grid[y][x].get("walkable", false)
	return lookup

func get_npcs_in_chunk(chunk_id: String) -> Dictionary:
	var placement = load_temp_localmap_placement()
	if placement == null:
		return {}

	var lm = placement.get("local_map", {})
	var stored_biome = str(lm.get("biome_key", ""))
	if stored_biome == "":
		return {}

	# normalize: folder → short key if needed
	var biome_key_for_path = stored_biome
	if stored_biome.contains("_"):
		biome_key_for_path = Constants.get_biome_chunk_key(stored_biome)

	var z_level = str(lm.get("z_level", "0"))
	var path = get_chunked_npc_chunk_path(chunk_id, biome_key_for_path, z_level)

	var data = load_json_file(path)
	if typeof(data) == TYPE_DICTIONARY and data.has("npcs"):
		return data["npcs"]
	return {}


func get_walkability_bounds(walkability_grid: Array) -> Dictionary:
	if walkability_grid.is_empty():
		return { "width": 0, "height": 0 }
	
	var height = walkability_grid.size()
	var width = walkability_grid[0].size()
	return { "width": width, "height": height }
	

func is_tile_walkable(walkability_grid: Array, pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= walkability_grid.size():
		return false
	if pos.x < 0 or pos.x >= walkability_grid[pos.y].size():
		return false
	
	var cell = walkability_grid[pos.y][pos.x]
	return cell.get("walkable", false)
	
func get_walkability_grid_for_chunk(chunk_id: String) -> Array:
	var placement := load_temp_localmap_placement()
	if placement == null:
		push_warning("⚠️ No placement found when getting walkability grid.")
		return []

	var biome_key: String = placement.get("local_map", {}).get("biome_key", "gef")
	var z_level: String = str(placement.get("local_map", {}).get("z_level", "0"))

	var tile_path = get_chunked_tile_chunk_path(chunk_id, biome_key, z_level)
	var object_path = get_chunked_object_chunk_path(chunk_id, biome_key, z_level)

	var tile_chunk: Dictionary = load_json_file(tile_path)
	var object_chunk: Dictionary = load_json_file(object_path)

	if tile_chunk == null or not tile_chunk.has("tile_grid"):
		print("❌ Missing or invalid tile_chunk for:", chunk_id)
		return []

	if object_chunk == null:
		object_chunk = {}
	elif object_chunk.has("objects"):
		object_chunk = object_chunk["objects"]

	# ✅ Build and return proper walkability grid
	return build_walkability_grid(tile_chunk["tile_grid"], object_chunk)

func get_player_weight_path() -> String:
	return get_save_file_path() + "characterdata/player_weight" + str(get_save_slot()) + ".json"

func load_player_weight() -> Dictionary:
	var path = get_player_weight_path()
	return load_json_file(path)
	
func save_player_weight(data: Dictionary) -> void:
	var path = get_player_weight_path()
	save_json_file(path, data)

func _get_item_stack_weight(item: Dictionary) -> float:
	if item == null:
		return 0.0
	
	var qty: int = int(item.get("qty", 1))
	
	# Prefer per-item weight if present
	if item.has("weight_per"):
		return float(item["weight_per"]) * qty
	
	# fallback to constants/item_data.gd
	var item_id: String = item.get("item_ID", "")
	if item_id != "" and ItemData.ITEM_PROPERTIES.has(item_id):
		var per: float = float(ItemData.ITEM_PROPERTIES[item_id].get("weight_per", 0.0))
		return per * qty
	
	# fallback: explicit weight field
	if item.has("weight"):
		return float(item["weight"])
	
	return 0.0


# --- Calculate inventory weight ---
func _calc_inventory_weight(inv: Dictionary) -> float:
	var total := 0.0
	for uid in inv.keys():
		total += _get_item_stack_weight(inv[uid])
	return total
	
func recalc_player_and_mount_weight() -> void:
	var weight_data: Dictionary = {
		"weight_stats": {
			"current_carry_weight": { "value": 0.0 },
			"current_gear_weight": { "value": 0.0 },
			"max_base_carry_weight": { "value": 0 },
			"max_carry_weight": { "value": 0 },
			"current_mount_carry_weight": { "value": 0.0 },
			"max_mount_carry_weight": { "value": 0 }
		}
	}
	
	# --- Player inventory ---
	var player_inv: Dictionary = load_player_inventory()
	weight_data["weight_stats"]["current_carry_weight"]["value"] = _calc_inventory_weight(player_inv)
	
	# --- Gear weight placeholder ---
	weight_data["weight_stats"]["current_gear_weight"]["value"] = 0.0
	
	# --- Max from attributes ---
	var base_attr: Dictionary = get_base_attributes()
	var str_val: int = int(base_attr.get("effective_attributes", {}).get("strength", 0))
	var max_base: int = str_val * 20
	weight_data["weight_stats"]["max_base_carry_weight"]["value"] = max_base
	weight_data["weight_stats"]["max_carry_weight"]["value"] = max_base
	
	# --- Mount inventory ---
	var mount_inv: Dictionary = load_mount_inv()
	weight_data["weight_stats"]["current_mount_carry_weight"]["value"] = _calc_inventory_weight(mount_inv)
	
	# --- Mount type max ---
	var mount_data: Dictionary = get_current_mount_data()
	var raw_mount_val = mount_data.get("max_mount_carry_weight", 0)
	var max_mount: int = 0
	
	if typeof(raw_mount_val) == TYPE_DICTIONARY:
		max_mount = int(raw_mount_val.get("value", 0))
	else:
		max_mount = int(raw_mount_val)
	
	weight_data["weight_stats"]["max_mount_carry_weight"]["value"] = max_mount
	
	# --- Save ---
	save_player_weight(weight_data)
	print("✅ Weight recalculated: ", weight_data)

static func get_avg_value_per(item: Dictionary) -> int:
	if item.has("avg_value_per"):
		return int(item["avg_value_per"])

	var item_id: String = item.get("item_ID", "")
	if item_id != "" and ItemData.ITEM_PROPERTIES.has(item_id):
		return int(ItemData.ITEM_PROPERTIES[item_id].get("avg_value_per", 0))

	return 0


static func normalize_stack_stats(item: Dictionary) -> void:
	if item == null or not item.has("item_ID"):
		return

	var qty := int(item.get("qty", 1))
	var item_id: String = item["item_ID"]
	var def: Dictionary = ItemData.ITEM_PROPERTIES.get(item_id, {})

	var weight_per := float(def.get("weight_per", item.get("weight_per", 0.0)))
	var avg_value_per := LoadHandlerSingleton.get_avg_value_per(item)

	item["weight_per"] = weight_per
	item["weight"] = weight_per * qty
	item["value"] = avg_value_per * qty

func get_player_hotbar_path() -> String:
	return get_save_file_path() + "characterdata/hotbar_register.json"

func load_player_hotbar() -> Dictionary:
	var path = get_player_hotbar_path()
	return load_json_file(path)
	
func save_player_hotbar(data: Dictionary) -> void:
	var path = get_player_hotbar_path()
	save_json_file(path, data)

func get_player_buildreg_path() -> String:
	return get_save_file_path() + "characterdata/building_register.json"

func load_player_buildreg() -> Dictionary:
	var path = get_player_buildreg_path()
	return load_json_file(path)
	
func save_player_buildreg(data: Dictionary) -> void:
	var path = get_player_buildreg_path()
	save_json_file(path, data)

func is_holding_hammer_tool() -> bool:
	var left_hand = get_current_left_hand_data()
	var right_hand = get_current_right_hand_data()

	var left_tags = left_hand.get("crafting_tags", [])
	var right_tags = right_hand.get("crafting_tags", [])

	return "hammer-tool" in left_tags or "hammer-tool" in right_tags

func set_current_build(id: String) -> void:
	var reg = load_player_buildreg()
	reg["current_build"] = id
	save_player_buildreg(reg)


func has_required_materials_for_current_build() -> bool:
	var build_reg: Dictionary = LoadHandlerSingleton.load_player_buildreg()
	var build_key: String = build_reg.get("current_build", "")

	if build_key == "":
		push_warning("No current_build set in build register.")
		return false

	var build_data: Dictionary = BuildData.BUILD_PROPERTIES.get(build_key)
	if build_data == null:
		push_warning("Build key '%s' not found in BUILD_PROPERTIES." % build_key)
		return false

	var requirements: Dictionary = build_data.get("requires", {})
	var inventory: Dictionary = LoadHandlerSingleton.load_player_inventory_dict()

	for tag in requirements.keys():
		var needed_qty: int = requirements[tag]
		var found_qty := 0

		for item in inventory.values():
			if tag in item.get("crafting_tags", []):
				found_qty += item.get("qty", 0)

		if found_qty < needed_qty:
			return false  # Not enough of this resource

	return true  # All requirements met
	
func get_blueprint_register_path() -> String:
	return get_save_file_path() + "characterdata/blueprint_register.json"

func load_blueprint_register() -> Dictionary:
	var path = get_blueprint_register_path()
	return load_json_file(path)
	
func save_blueprint_register(data: Dictionary) -> void:
	var path = get_blueprint_register_path()
	save_json_file(path, data)

func clear_blueprint_register() -> void:
	save_blueprint_register({ "blueprints": {} })

func get_display_name_from_item_data(item_id: String) -> String:
	# Matches your item_data.gd structure
	if ItemData.ITEM_PROPERTIES.has(item_id):
		var entry = ItemData.ITEM_PROPERTIES[item_id]
		if entry.has("base_display_name"):
			return entry["base_display_name"]
	# fallback if missing or invalid
	return "[Unknown Item: %s]" % item_id


# 🔹 Determine which faith the player chose
func detect_player_faith() -> String:
	var path = get_character_creation_path()
	var data = load_json_file(path)
	if data.has("divineskills"):
		for faith_key in data["divineskills"].keys():
			if data["divineskills"][faith_key]:
				return faith_key
	return "negation"  # default to godless if not found


func get_conviction_level_for_faith(faith_key: String) -> int:
	var path = get_skill_save_path()
	var data = load_json_file(path)

	# ✅ Safely handle missing or malformed files
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("⚠️ Skills file not found or invalid at: %s" % path)
		return 0

	if not data.has("divine_skills"):
		return 0
	if typeof(data["divine_skills"]) != TYPE_DICTIONARY:
		return 0
	if not data["divine_skills"].has(faith_key):
		return 0

	var faith_data = data["divine_skills"][faith_key]
	if typeof(faith_data) != TYPE_DICTIONARY:
		return 0

	return int(faith_data.get("level", 0))


# 🔹 Get current conviction level (based on active faith)
func get_current_conviction_level() -> int:
	var active_faith = detect_player_faith()
	return get_conviction_level_for_faith(active_faith)


func get_conviction_rank_title(level: int, faith: String = "negation") -> String:
	var table: Dictionary = FaithConvictionTitles.TITLES
	if not table.has(faith):
		return "Uninitiated"
	var ranks: Array = table[faith]
	var idx: int = int(clamp(floor(level / 3.0), 0, ranks.size() - 1))
	return ranks[idx]

# 🔹 Get current XP for a given faith
func get_current_xp_for_faith(faith_key: String) -> int:
	var path = get_skill_save_path()
	var data = load_json_file(path)
	if data == null or not data.has("divine_skills"):
		return 0
	var skill_data = data["divine_skills"].get(faith_key, null)
	if skill_data == null:
		return 0
	return int(skill_data.get("current_xp", 0))


# 🔹 Get XP required for next level
func get_xp_to_next_level_for_faith(faith_key: String) -> int:
	var path = get_skill_save_path()
	var data = load_json_file(path)
	if data == null or not data.has("divine_skills"):
		return 100
	var skill_data = data["divine_skills"].get(faith_key, null)
	if skill_data == null:
		return 100
	return int(skill_data.get("xp_to_next_level", 100))


# 🔹 Calculate XP progress as float 0.0–1.0
func get_xp_progress_ratio_for_faith(faith_key: String) -> float:
	var current_xp = float(get_current_xp_for_faith(faith_key))
	var next_xp = float(get_xp_to_next_level_for_faith(faith_key))
	if next_xp <= 0:
		return 0.0
	return clamp(current_xp / next_xp, 0.0, 1.0)
