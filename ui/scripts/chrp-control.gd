extends Control

func _ready():
	# Load the character data using the singleton
	var character_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_character_creation_path())
	var combat_stats_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_combat_stats_path())
	var base_attributes_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_base_attributes_path())
	var experience_data = base_attributes_data["experience"]
	
	# Populate the character data container with character information
	if character_data:
		chrp_populate_character_data(character_data)

	# Populate combat stats if available
	if combat_stats_data:
		chrp_populate_combat_stats(combat_stats_data)

	# Populate base attributes if available
	if base_attributes_data:
		chrp_populate_base_attributes(base_attributes_data)

	# Update the XP progress bar
	if experience_data:
		update_xp_progress_bar(experience_data)
		
# Function to populate character data based on the structured layout
func chrp_populate_character_data(character_data: Dictionary):
	# Access nodes directly by their unique names
	var chrcharport = $chrpplayerinfoCharPort
	var chrcharname = get_node("chrp-VBoxContainer-charinfo/chrpnamelabel")
	var chrcharfaith = get_node("chrp-VBoxContainer-charinfo/chrpfaithlabel")
	var chrcharbg = get_node("chrp-VBoxContainer-charinfo/chrp-HBoxContainer-chartitle/chrpbackground")
	var chrrace = get_node("chrp-VBoxContainer-charinfo/chrp-HBoxContainer-chartitle/chrpracelabel")

	# Attempt to load the character portrait texture
	if character_data.has("character") and character_data["character"].has("portrait"):
		var portrait_texture = load(character_data["character"]["portrait"])
		if portrait_texture == null:
			print("Error: Failed to load portrait texture from path:", character_data["character"]["portrait"])
		else:
			chrcharport.texture = portrait_texture
			chrcharport.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	# Debug print the character data to verify correct loading
	print("Character Data:", character_data)

	# Set character name
	if character_data["character"].has("name"):
		var name = str(character_data["character"]["name"])
		chrcharname.text = name
		print("Setting Name:", chrcharname.text)
	else:
		print("Error: Name not found in character data.")
		
	# Set character race
	if character_data["character"].has("race"):
		var race = str(character_data["character"]["race"]).capitalize()
		chrrace.text = race
		print("Setting Race:", chrrace.text)
	else:
		print("Error: Race not found in character data.")

	# Set character background
	if character_data["character"].has("background"):
		var background = str(character_data["character"]["background"])
		chrcharbg.text = background
		print("Setting background:", chrcharbg.text)
	else:
		print("Error: background not found in character data.")

	# Set character faith
	if character_data["character"].has("faith"):
		chrcharfaith.text = str(character_data["character"]["faith"])
		print("Setting Faith:", chrcharfaith.text)
	else:
		print("Error: Faith not found in character data.")

# Function to populate combat stats
func chrp_populate_combat_stats(combat_stats_data: Dictionary):
	print("Combat Stats Data:", combat_stats_data)

	if combat_stats_data.has("combat_stats"):
		# Define a dictionary to map combat stats to their corresponding UI label paths
		var stat_paths = {
			"armor_penetration_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-pen-lvl",
			"armor_rating": "../chrp-VBoxContainer-combat/chrp-armor-rating-lvl",
			"attack_speed": "../chrp-VBoxContainer-dmglvl/chrp-mlespeed-lvl",
			"chance_to_dodge": "../chrp-VBoxContainer-dmglvl/chrp-dodge-lvl",
			"chance_to_hit": "../chrp-VBoxContainer-dmglvl/chrp-mleaccur-lvl",
			"damage": "../chrp-VBoxContainer-dmglvl/chrp-mledmg-lvl",
			"damage_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-phy-lvl"
		}

		# Handle stats with single "value"
		for stat in stat_paths.keys():
			var stat_info = combat_stats_data["combat_stats"].get(stat, null)
			if stat_info and stat_info.has("value"):
				var stat_value = stat_info["value"]
				var stat_label = get_node(stat_paths[stat])
				
				if stat_label:
					stat_label.text = str(stat_value)
					print("Setting", stat.capitalize(), "Level to:", stat_value)
				else:
					print("Error: Node for", stat, "not found at", stat_paths[stat])
			else:
				print("Error:", stat.capitalize(), "stat not found in combat_stats or missing 'value'.")

		# Handle "current" and "max" stats like health, stamina, fatigue, hunger, sanity
		var current_max_stats = {
			"health": "../chrp-VBoxContainer-meter-lvl/chrp-health-lvl",
			"stamina": "../chrp-VBoxContainer-meter-lvl/chrp-stamina-lvl",
			"fatigue": "../chrp-VBoxContainer-meter-lvl/chrp-fatigue-lvl",
			"hunger": "../chrp-VBoxContainer-meter-lvl/chrp-hunger-lvl",
			"sanity": "../chrp-VBoxContainer-meter-lvl/chrp-sanity-lvl"
		}

		for stat in current_max_stats.keys():
			var stat_info = combat_stats_data["combat_stats"].get(stat, null)
			if stat_info and stat_info.has("current") and stat_info.has("max"):
				var current_value = stat_info["current"]
				var max_value = stat_info["max"]
				var stat_label = get_node(current_max_stats[stat])
				
				if stat_label:
					stat_label.text = str(current_value) + " / " + str(max_value)
					print("Setting", stat.capitalize(), "Level to:", current_value, "/", max_value)
				else:
					print("Error: Node for", stat, "not found at", current_max_stats[stat])
			else:
				print("Error:", stat.capitalize(), "stat not found in combat_stats or missing 'current'/'max'.")
				
		# Handle resistances separately
		var resistances = combat_stats_data["combat_stats"].get("resistances", null)
		if resistances:
			var resistance_paths = {
				"dark_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-dar-lvl",
				"divine_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-div-lvl",
				"fire_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-fir-lvl",
				"glamour_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-gla-lvl",
				"ice_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-ice-lvl",
				"magic_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-mgk-lvl",
				"poison_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-poi-lvl",
				"void_resistance": "../chrp-VBoxContainer-dmgresist-lvl/chrp-voi-lvl"
			}
			
			for resistance in resistance_paths.keys():
				var resistance_info = resistances.get(resistance, null)
				if resistance_info and resistance_info.has("value"):
					var resistance_value = resistance_info["value"]
					var resistance_label = get_node(resistance_paths[resistance])
					
					if resistance_label:
						resistance_label.text = str(resistance_value)
						print("Setting", resistance.capitalize(), "to:", resistance_value)
					else:
						print("Error: Node for", resistance, "not found at", resistance_paths[resistance])
				else:
					print("Error:", resistance.capitalize(), "not found in resistances or missing 'value'.")
	else:
		print("Error: combat_stats not found in the JSON data.")

# Function to populate base attributes and experience (levels, XP)
func chrp_populate_base_attributes(base_attributes_data: Dictionary):
	print("Base Attributes Data:", base_attributes_data)

	# Check if the effective_attributes section exists in the data
	if base_attributes_data.has("effective_attributes"):
		# Define a dictionary to map effective attributes to their corresponding UI label paths
		var attribute_paths = {
			"strength": "../chrp-VBoxContainer-activelvl/chrp-strength-lvl",
			"perception": "../chrp-VBoxContainer-activelvl/chrp-perception-lvl",
			"endurance": "../chrp-VBoxContainer-activelvl/chrp-endurance-lvl",
			"agility": "../chrp-VBoxContainer-activelvl/chrp-agility-lvl",
			"charisma": "../chrp-VBoxContainer-activelvl/chrp-charisma-lvl",
			"faith": "../chrp-VBoxContainer-activelvl/chrp-faith-lvl",
			"intelligence": "../chrp-VBoxContainer-activelvl/chrp-intelligence-lvl",
			"willpower": "../chrp-VBoxContainer-activelvl/chrp-willpower-lvl"
		}

		# Loop through each attribute we want to display
		for attribute in attribute_paths.keys():
			var attribute_value = base_attributes_data["effective_attributes"].get(attribute, null)
			
			if attribute_value != null:
				var attribute_label = get_node(attribute_paths[attribute])
				
				if attribute_label:
					attribute_label.text = str(attribute_value)
					print("Setting", attribute.capitalize(), "Level to:", attribute_value)
				else:
					print("Error: Node for", attribute, "not found at", attribute_paths[attribute])
			else:
				print("Error:", attribute.capitalize(), "attribute not found in effective_attributes.")
	else:
		print("Error: effective_attributes not found in the JSON data.")

	# Check if the experience section exists in the data
	if base_attributes_data.has("experience"):
		# Get the level, current XP, and XP to next level
		var level_value = base_attributes_data["experience"].get("level", null)
		var current_xp_value = base_attributes_data["experience"].get("current_xp", null)
		var xp_to_next_level_value = base_attributes_data["experience"].get("xp_to_next_level", null)
		
		# Set the level label
		if level_value != null:
			var level_label = get_node("chrp-VBoxContainer-charinfo/chrp-HBoxContainer-charlevel/chrplevel")
			if level_label:
				level_label.text = str(level_value)
				print("Setting Level to:", level_value)
			else:
				print("Error: Node for level not found.")

		# Set the XP to next level label (formatted as 'current XP / XP to level up')
		if current_xp_value != null and xp_to_next_level_value != null:
			var xp_to_level_label = get_node("../chrp-xptolevelup")  # Adjust this path based on your scene
			if xp_to_level_label:
				xp_to_level_label.text = str(current_xp_value) + " / " + str(xp_to_next_level_value)
				print("Setting XP to Level Up to:", current_xp_value, "/", xp_to_next_level_value)
			else:
				print("Error: Node for XP to level up not found.")
	else:
		print("Error: experience section not found in the JSON data.")
		
# Function to update the XP progress bar
func update_xp_progress_bar(experience_data: Dictionary):
	if experience_data.has("current_xp") and experience_data.has("xp_to_next_level"):
		var current_xp = experience_data["current_xp"]
		var xp_to_next_level = experience_data["xp_to_next_level"]
		
		# Access the ProgressBar node
		var xp_progress_bar = get_node("../chrp-playerinfo-exp-meter-all")  # Adjust the path to your actual node
		
		if xp_progress_bar:
			# Set the maximum value of the progress bar to the XP needed for the next level
			xp_progress_bar.max_value = xp_to_next_level
			
			# Set the current value of the progress bar to the current XP
			xp_progress_bar.value = current_xp
			
			print("XP Progress: ", current_xp, "/", xp_to_next_level)
		else:
			print("Error: XP ProgressBar node not found.")
	else:
		print("Error: current_xp or xp_to_next_level not found in experience data.")
