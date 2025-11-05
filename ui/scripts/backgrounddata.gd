# HBoxContainer/backgrounddata script res://ui/scripts/backgrounddata.gd
extends Control

# Paths to the different background JSON files
var backgrounds_paths = [
	"res://data/generic_backgrounds.json",
	"res://data/race_backgrounds.json",
	"res://data/faith_backgrounds.json",
	"res://data/skill_backgrounds.json",
	"res://data/magitech_backgrounds.json",
	"res://data/sex_backgrounds.json",
	"res://data/aptitude_backgrounds.json"
]

# Path to the character template JSON file
var character_template_path = "user://saves/character_template.json"

# Index to track the currently selected background
var current_background_index = 0
var backgrounds = []  # List of all backgrounds loaded from JSON
var available_backgrounds = []  # List of filtered backgrounds based on player attributes

func _ready():
	# Load character data to get player attributes
	var player_data = load_character_template(character_template_path)
	if player_data:
		print("Loaded Player Data:", player_data)

		var player_race = player_data.get("race", "")
		var player_faith = player_data.get("faith", "")
		var player_sex = player_data.get("sex", "")

		# Load the player's aptitudes directly from the combined data
		var magic_aptitude = int(player_data.get("aptitudes", {}).get("magic", 0))
		var tech_aptitude = int(player_data.get("aptitudes", {}).get("technology", 0))

		# Extract skills and magitech data
		var skills = []
		var magitech = {}

		# Extract skills marked as true
		for skill in player_data.get("skills", {}):
			if player_data["skills"][skill] == true:
				skills.append(skill)
				print("Detected Skill:", skill)  # Debugging detected skills

		# Extract magitech attributes marked as true
		for tech in player_data.get("magicktech", {}):
			if player_data["magicktech"][tech] == true:
				magitech[tech] = true
				print("Detected Magitech:", tech)  # Debugging detected magitech

		print("Player Race:", player_race)
		print("Player Faith:", player_faith)
		print("Player Sex:", player_sex)
		print("Magic Aptitude:", magic_aptitude)
		print("Technology Aptitude:", tech_aptitude)
		print("Skills:", skills)
		print("Magitech:", magitech)

		# Load backgrounds from multiple JSON files
		load_backgrounds_from_multiple_jsons(backgrounds_paths)
		# Filter backgrounds based on player attributes, aptitudes, skills, and magitech
		filter_backgrounds(player_race, player_faith, player_sex, magic_aptitude, tech_aptitude, skills, magitech)
		update_background_display()
	else:
		print("Error: Could not load player data.")

# Function to load the character template JSON file
func load_character_template(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			print("Successfully loaded character data.")
			var data = json.data

			print("Full JSON Data:", data)

			var character_data = data.get("character", {})
			var aptitudes_data = data.get("aptitudes", {})

			character_data["aptitudes"] = aptitudes_data
			character_data["skills"] = data.get("skills", {})
			character_data["magicktech"] = data.get("magicktech", {})

			print("Combined Character Data:", character_data)

			return character_data
		else:
			print("JSON parsing error:", json.error_string)
			return {}
	else:
		print("Failed to open character template file:", file_path)
		return {}

# Function to load backgrounds from multiple JSON files
func load_backgrounds_from_multiple_jsons(paths: Array):
	backgrounds.clear()
	for path in paths:
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(content)
			file.close()

			if parse_result == OK:
				backgrounds.append_array(json.data)
				print("Successfully loaded backgrounds from:", path)
			else:
				print("JSON parsing error in file:", path, "Error:", json.error_string)
		else:
			print("Failed to open backgrounds file:", path)

# Function to filter backgrounds based on player's race, faith, sex, aptitudes, and skill combinations
func filter_backgrounds(player_race: String, player_faith: String, player_sex: String, magic_aptitude: int, tech_aptitude: int, skills: Array, magitech: Dictionary):
	available_backgrounds.clear()
	for background in backgrounds:
		var allowed_races = background.get("allowed_races", [])
		var allowed_faiths = background.get("allowed_faiths", [])
		var allowed_sexes = background.get("allowed_sexes", [])
		var aptitude_requirements = background.get("aptitude_requirements", {})
		var skill_combinations = background.get("skill_combinations", {})

		var race_ok = (allowed_races.size() == 0 or player_race in allowed_races)
		var faith_ok = (allowed_faiths.size() == 0 or player_faith in allowed_faiths)
		var sex_ok = (allowed_sexes.size() == 0 or player_sex in allowed_sexes)

		var magic_req = aptitude_requirements.get("magic", 0)
		var tech_req = aptitude_requirements.get("technology", 0)
		var aptitudes_ok = (magic_aptitude >= magic_req and tech_aptitude >= tech_req)

		var combination_ok = true
		if skill_combinations.size() > 0:
			combination_ok = check_skill_combinations(skill_combinations, skills, magitech)

		if race_ok and faith_ok and sex_ok and aptitudes_ok and combination_ok:
			available_backgrounds.append(background)

	if available_backgrounds.size() == 0:
		print("No available backgrounds matched the criteria.")
	else:
		print("Filtered backgrounds:")
		for bg in available_backgrounds:
			print("- Title:", bg["title"])

# Function to check if player skills match any defined skill combinations for a background
func check_skill_combinations(skill_combinations: Dictionary, skills: Array, magitech: Dictionary) -> bool:
	var required_skills = skill_combinations.get("skills", [])
	for skill in required_skills:
		if not skill in skills:
			print("Combination check failed: Missing skill:", skill)
			return false

	var required_magitech = skill_combinations.get("magitech", [])
	for tech in required_magitech:
		if not magitech.has(tech) or not magitech[tech]:
			print("Combination check failed: Missing magitech:", tech)
			return false

	print("Combination check passed for required skills and magitech.")
	return true

# Function to update the display with the current background
func update_background_display():
	if available_backgrounds.size() == 0:
		print("No available backgrounds for the selected race, faith, and sex.")
		return

	var background = available_backgrounds[current_background_index]

	print("Available backgrounds:")
	for bg in available_backgrounds:
		print("- Title:", bg["title"])

	var background_title = $background_title
	var background_description = $background_description
	var background_bonus = $background_bonus

	if background_title == null or background_description == null or background_bonus == null:
		print("Error: Background display nodes not found.")
		return

	background_title.text = background["title"]
	background_description.bbcode_text = background["description"]
	background_bonus.bbcode_text = "[color=yellow]" + background["bonus"] + "[/color]"
	print("Displaying background:", background["title"])

# Function to cycle through backgrounds when called
func cycle_background():
	if available_backgrounds.size() == 0:
		print("No available backgrounds for the selected race, faith, and sex.")
		return

	current_background_index = (current_background_index + 1) % available_backgrounds.size()
	update_background_display()
	save_current_background_to_json()

# Function to save the currently selected background to the JSON file
func save_current_background_to_json():
	var file_path = "user://saves/character_template.json"
	var json = JSON.new()
	var data = {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			data = json.data
		else:
			print("JSON parsing error: ", json.error_string)
			return
	else:
		print("Failed to open file for reading:", file_path)
		return

	if "character" in data:
		var selected_background = available_backgrounds[current_background_index]["title"]
		data["character"]["background"] = selected_background
	else:
		print("Error: 'character' section not found in JSON data.")
		return

	file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json.stringify(data, "\t", true))
		file.close()
		print("Successfully saved updated JSON data.")
	else:
		print("Failed to open file for writing:", file_path)
